// cutout: remove the background from any image with macOS Vision. Local, free, no model download.
//
//   swift ~/dev-tools/bin/cutout.swift <image> <out.png>            the subject on a transparent background
//   swift ~/dev-tools/bin/cutout.swift <image> <out.png> --mask     a black and white mask instead (white = subject)
//   swift ~/dev-tools/bin/cutout.swift <image> <out.png> --crop     transparent background, cropped to the subject
//
// Exit codes: 0 written, 2 bad arguments or unreadable image, 3 Vision failed, 4 no subject found, 5 could not write.
// Vision keeps every foreground thing it finds (people, objects, animals). It reads the picture, not a prompt:
// to keep one thing out of several, crop the image first.

import Foundation
import Vision
import CoreImage
import ImageIO
import UniformTypeIdentifiers

func fail(_ message: String, _ code: Int32) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(code)
}

let args = Array(CommandLine.arguments.dropFirst())
let flags = Set(args.filter { $0.hasPrefix("--") })
let paths = args.filter { !$0.hasPrefix("--") }
let known: Set<String> = ["--mask", "--crop"]
guard paths.count == 2, flags.isSubset(of: known), !(flags.contains("--mask") && flags.contains("--crop")) else {
    fail("usage: swift cutout.swift <image> <out.png> [--mask | --crop]", 2)
}
guard paths[1].lowercased().hasSuffix(".png") else { fail("the output must be a .png file (it carries the transparency)", 2) }
guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: paths[0]) as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fail("could not read an image from \(paths[0])", 2)
}

let request = VNGenerateForegroundInstanceMaskRequest()
let handler = VNImageRequestHandler(cgImage: image, options: [:])
do { try handler.perform([request]) } catch { fail("Vision failed: \(error)", 3) }
guard let found = request.results?.first, !found.allInstances.isEmpty else {
    fail("no subject found in \(paths[0])", 4)
}

let buffer: CVPixelBuffer
do {
    if flags.contains("--mask") {
        buffer = try found.generateScaledMaskForImage(forInstances: found.allInstances, from: handler)
    } else {
        buffer = try found.generateMaskedImage(ofInstances: found.allInstances, from: handler,
                                               croppedToInstancesExtent: flags.contains("--crop"))
    }
} catch { fail("Vision failed: \(error)", 3) }

let result = CIImage(cvPixelBuffer: buffer)
let context = CIContext()
guard let output = context.createCGImage(result, from: result.extent),
      let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: paths[1]) as CFURL,
                                                        UTType.png.identifier as CFString, 1, nil) else {
    fail("could not write \(paths[1])", 5)
}
CGImageDestinationAddImage(destination, output, nil)
guard CGImageDestinationFinalize(destination) else { fail("could not write \(paths[1])", 5) }
print("\(paths[1]): \(output.width)x\(output.height), \(found.allInstances.count) subject(s)")

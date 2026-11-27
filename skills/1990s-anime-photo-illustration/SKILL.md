---
name: 1990s-anime-photo-illustration
description: Turn user-supplied photographs into detailed, hand-drawn 1990s Japanese anime stills while preserving the people and the original moment. Use when the user says "90s anime", requests an anime transformation of a photo, or continues an established 90s anime illustration.
---

# 1990s Anime Photo Illustration

Turn the source photograph into a polished still from a 1990s Japanese romantic slice-of-life film. Facial likeness comes first. Use earlier illustrations as style references when available, and follow any style or framing choice the user makes for the current image.

Treat `90s anime` on its own as a request to use this skill. Use the photo attached or clearly referenced in the conversation. For a follow-up edit, use the earlier illustration. If no usable image is available, ask the user to attach one.

## Inspect the reference

- Identify each person's distinct face shape, jaw, cheekbones, chin, nose bridge and tip, nostrils, lip shape and fullness, mouth width, smile, eye shape and spacing, eyelids, brows, and natural asymmetry. Record visible age cues, hairline, hair texture and volume, and the actual pattern of mustache, beard, or stubble. Match glasses and sunglasses, including frame geometry, lens color, and reflections.
- Note the people and their positions, poses, gestures, points of contact, clothing, and accessories. Keep recognizable colors, patterns, folds, stitching, jewelry, watches, bags, hats, shoes, pins, and badges.
- Note camera angle, perspective, framing, light direction and temperature, skin tones, and emotional tone. Identify the actual structure of recognizable architecture, furniture, landmarks, vehicles, fixtures, and other background objects. Transcribe meaningful visible wording exactly, including case and placement. Preserve the design of complex signs and logos. Include only legible wording or wording supplied by the user.

## Render the still

For a new illustration, use the photograph as the image-edit input. Use the built-in image-generation editor when available under the normal imagegen workflow. For a hosted `generate` run, follow its provider and budget workflow. When processing multiple photos, make a separate edit for each source and deliver one finished still per photo unless the user requests a different count. Keep the source photo authoritative for likeness and scene details.

Add the observed details for each image to this reusable prompt:

> Transform the source photograph into a highly detailed, hand-drawn 1990s Japanese anime film still. Use expressive ink contours with subtle line-weight variation, traditional 2D cel-shading, shaped shadows, warm highlights, soft reflected light, cinematic contrast, and subtle analog film grain and painted cel texture. Render layered hair with natural volume and highlights, delicate facial shading and blush where appropriate, accurate anatomy, and detailed fabrics and surroundings.
>
> Preserve each person's facial proportions, individual nose, lips, eyes, hairline, hairstyle, glasses, facial hair, visible age, and expression. Draw soft, expressive faces with well-defined noses and lips, natural eye proportions, and elegant contours. Preserve natural skin tones and the warmth, cheer, composure, or spontaneity in the photo.
>
> Preserve the subject count, poses, interactions, clothing, accessories, camera perspective, lighting direction, and recognizable location and objects. Reproduce any supplied or clearly legible text with its exact spelling, case, and placement. Preserve signs and logos in their original locations and keep unreadable wording indistinct.
>
> Make one polished static illustration. Avoid generic faces, oversized eyes, button noses, exaggerated expressions, artificial youthfulness, harsh aging, angular rendering, flat shading, orange casts, neon saturation, modern gloss, 3D, photorealism, invented objects or wording, reaction effects, decorative symbols, collages, panels, animation, GIFs, and spritesheets.

Keep the source framing by default. A tighter portrait crop can give faces more room for detail if recognizable surroundings, gestures, and accessories still fit. Keep everyone visible in group shots, and retain full-body framing when it matters to the moment.

## Verify and revise

Compare the output with the source. Check each person's likeness and expression, especially the nose, lips, eyes, facial silhouette, glasses, and facial hair. Check clothing, gestures, perspective, important objects, and readable text. Confirm the result is a single static frame with expressive character design and traditional cel shading.

For a correction, use the strongest existing illustration as the edit target. Use the photograph or the user's exact wording to guide the correction. Specify the precise change and lock the successful faces, expressions, rendering, and composition wherever they are outside the requested edit. Compare again with both the photograph and the chosen baseline to catch drift.

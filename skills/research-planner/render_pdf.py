#!/usr/bin/env python3
"""Render a research-report package (a folder of NN-*.md files) into a designed PDF.

Editorial print design: cover, index with real page numbers, running chapter headers,
evidence-grade pills, highlighted recommended rows, callout cards. Serif body paired
with a humanist sans for headings. Per-subject theming.

Deps: pip install weasyprint markdown
macOS: run with DYLD_FALLBACK_LIBRARY_PATH=$(brew --prefix)/lib so WeasyPrint finds pango/cairo.

Usage:
  render_pdf.py --dir "<folder>" --title "..." [--subtitle ...] [--meta ...]
                [--tag 21.NN] [--note ...] [--theme care|default] [--out path.pdf] [--no-open]

Theme resolves in this order: --theme arg > a theme.json in the folder ({"theme": "care"},
plus optional per-token overrides) > "default". Docs are the folder's NN-*.md files in numeric
order; section labels come from an optional labels.json ({"01-foo.md": "Foo"}), else the filename.
"""
import argparse, json, re, pathlib, html, sys
from string import Template

# --- themes: each is a flat token map the CSS template interpolates -----------
# Warmth/identity is carried by ACCENT + serif TYPE, not by a cream body bg
# (the cream/sand near-white is the current AI default; backgrounds stay near-white,
#  tinted only toward the theme's own hue).
THEMES = {
    # calm, humane "care" brand for a partner navigating a loved one's illness:
    # muted pine-green primary, warm clay for the amber grade, book-like serif body.
    "care": {
        "font_body": "Charter, 'Iowan Old Style', 'Palatino Linotype', Georgia, serif",
        "font_head": "'Avenir Next', 'Helvetica Neue', 'Segoe UI', system-ui, sans-serif",
        "paper": "#F6F8F6", "ink": "#222B26", "ink_soft": "#55605A",
        "accent": "#35715E", "accent_strong": "#274F42", "accent_soft": "#E6EFE9",
        "rule": "#DFE6E1", "card_bg": "#ECF2ED", "row_alt": "#EFF4F0",
        "gs_ink": "#2C6A4C", "gs_bg": "#E1EEE6",
        "gm_ink": "#8F5322", "gm_bg": "#F4E8DB",
        "gi_ink": "#5C645E", "gi_bg": "#E8ECE8",
        "rec_bg": "#DCEDE2", "link": "#2F6455",
    },
    # refined clinical/neutral: navy accent, same serif+sans typographic system.
    "default": {
        "font_body": "'Iowan Old Style', Charter, Georgia, 'Times New Roman', serif",
        "font_head": "'Avenir Next', 'Helvetica Neue', system-ui, sans-serif",
        "paper": "#FDFDFC", "ink": "#1B2430", "ink_soft": "#556070",
        "accent": "#2F5573", "accent_strong": "#233F58", "accent_soft": "#E9F0F6",
        "rule": "#E3E7EE", "card_bg": "#EEF3F8", "row_alt": "#F5F8FB",
        "gs_ink": "#1F7A47", "gs_bg": "#E3F0E8",
        "gm_ink": "#96581F", "gm_bg": "#F4E9DD",
        "gi_ink": "#5F6A7A", "gi_bg": "#EEF0F3",
        "rec_bg": "#E4F1EA", "link": "#2A5DB0",
    },
}

def resolve_theme(d, theme_arg):
    theme = dict(THEMES["default"])
    name = theme_arg or ""
    conf = {}
    tj = pathlib.Path(d) / "theme.json"
    if tj.exists():
        conf = json.loads(tj.read_text())
        if not name:
            name = conf.get("theme", "")
    if name in THEMES:
        theme = dict(THEMES[name])
    for k, v in conf.items():          # per-token overrides from theme.json
        if k != "theme":
            theme[k] = v
    return theme

def prefix_ids(s, n):
    s = re.sub(r'id="([^"]+)"', lambda m: 'id="f%d-%s"' % (n, m.group(1)), s)
    s = re.sub(r'href="#([^"]+)"', lambda m: 'href="#f%d-%s"' % (n, m.group(1)), s)
    return s

GRADE = {"Strong": "g-strong", "Moderate": "g-mod", "Inference": "g-inf", "Weak": "g-inf",
         "Patient-reported": "g-inf", "Lived-experience": "g-inf", "Emerging": "g-inf"}
_GRADE_RE = re.compile(r'\b(Strong|Moderate|Inference|Weak|Patient-reported|Lived-experience|Emerging)\b')
def _color(m):
    inner = _GRADE_RE.sub(
        lambda w: '<span class="g %s">%s</span>' % (GRADE[w.group(1)], w.group(1)), m.group(1))
    return '<strong>' + inner + '</strong>'
def enhance(s):
    s = re.sub(r'<strong>(.*?)</strong>', _color, s, flags=re.S)
    s = re.sub(r'<tr>(.*?)</tr>',
               lambda m: ('<tr class="rec-row">' + m.group(1) + '</tr>') if 'RECOMMENDED' in m.group(1) else m.group(0),
               s, flags=re.S)
    s = re.sub(r'(<h2[^>]*>Bottom line</h2>)\s*(<ul>.*?</ul>)', r'\1<div class="panel">\2</div>', s, flags=re.S)
    return s

def label_for(fn, overrides):
    if fn in overrides:
        return overrides[fn]
    stem = re.sub(r'^\d+[-_]?', '', pathlib.Path(fn).stem)
    if stem.lower() in ("readme", "index", "overview", ""):
        return "Overview"
    words = stem.replace("-", " ").replace("_", " ").strip()
    return words[:1].upper() + words[1:]

CSS_TMPL = Template("""
@page { size: Letter; margin: 24mm 26mm 20mm; background: ${paper};
  @top-right { content: string(doctitle); font-family: ${font_head}; font-size: 7.5pt; letter-spacing: 0.4px; color: ${ink_soft}; }
  @bottom-left { content: string(runtag); font-family: ${font_head}; font-size: 7pt; letter-spacing: 0.5px; color: ${ink_soft}; }
  @bottom-center { content: counter(page); font-family: ${font_head}; font-size: 8.5pt; color: ${ink_soft}; }
  @bottom-right { content: string(runtag2); font-family: ${font_head}; font-size: 7pt; color: ${ink_soft}; } }
@page cover { @top-right{content:normal} @bottom-left{content:normal} @bottom-center{content:normal} @bottom-right{content:normal} }
@page nohdr { @top-right{content:normal} }

html { background: ${paper}; font-family: ${font_body}; font-size: 11pt; color: ${ink};
  line-height: 1.6; -weasy-hyphens: auto; }
body { margin: 0; }
p { margin: 0 0 3.2mm; text-wrap: pretty; }
strong { color: ${ink}; font-weight: 600; }
em { color: ${ink_soft}; font-style: italic; }
a { color: ${link}; text-decoration: none; border-bottom: 0.4pt solid ${rule}; word-break: break-word; }
hr { border: none; border-top: 0.6pt solid ${rule}; margin: 6mm 0; }
h1, h2, h3 { break-after: avoid; text-wrap: balance; }
p, li { orphans: 2; widows: 2; }
li, blockquote, .panel, pre, tr { break-inside: avoid; }

/* cover */
.meta-strings { string-set: runtag attr(data-tag), runtag2 attr(data-tag2); }
.cover { page: cover; break-after: page; min-height: 232mm; display: flex; flex-direction: column; justify-content: center; }
.cmark { width: 16mm; height: 2.4pt; background: ${accent}; border-radius: 2pt; margin-bottom: 7mm; }
.kicker { font-family: ${font_head}; font-size: 9.5pt; letter-spacing: 1.6px; text-transform: uppercase; color: ${accent}; margin-bottom: 3mm; }
.ctitle { font-family: ${font_body}; font-weight: 600; font-size: 33pt; color: ${accent_strong}; line-height: 1.08; letter-spacing: -0.3px; margin: 0 0 4mm; max-width: 150mm; }
.csub { font-family: ${font_body}; font-style: italic; font-size: 14pt; color: ${ink_soft}; margin-bottom: 9mm; max-width: 150mm; }
.cmeta { font-family: ${font_head}; font-size: 10pt; color: ${ink_soft}; margin-bottom: 12mm; }
.cnote { font-family: ${font_head}; font-size: 9pt; color: ${ink_soft}; background: ${card_bg}; border: 0.6pt solid ${rule};
  border-radius: 8pt; padding: 4mm 5mm; max-width: 150mm; line-height: 1.5; }

/* index */
.toc-page { page: nohdr; break-after: page; }
.toc-title { font-family: ${font_body}; font-weight: 600; font-size: 22pt; color: ${accent_strong};
  border-bottom: 1.4pt solid ${accent}; padding-bottom: 3mm; letter-spacing: -0.2px; }
ul.toc { list-style: none; padding: 0; margin-top: 5mm; }
ul.toc li { margin: 0.4mm 0; }
ul.toc a { font-family: ${font_head}; text-decoration: none; border: none; color: ${ink}; }
ul.toc a::after { content: leader('. ') target-counter(attr(href), page); color: ${ink_soft}; font-size: 8.5pt; }
li.toc-l1 { font-weight: 600; font-size: 10pt; margin-top: 3mm; }
li.toc-l1 a { color: ${accent_strong}; }
li.toc-l2 { margin-left: 6mm; font-size: 8.8pt; }
li.toc-l2 a { color: ${ink_soft}; }

/* chapters flow continuously (no forced page-per-chapter) so pages fill; a chapter
   heading is kept with its content via break-after:avoid, and gets generous top air. */
.doc { margin-top: 13mm; }
.doc:first-of-type { margin-top: 0; }
.kick { string-set: doctitle content(text); font-family: ${font_head}; font-size: 8.5pt; font-weight: 600;
  letter-spacing: 0.3px; color: ${accent}; margin-bottom: 2.5mm; break-after: avoid; }
.kick::before { content: '\\25CF'; font-size: 5.5pt; color: ${accent}; vertical-align: 1.5pt; margin-right: 2mm; }
h1 { font-family: ${font_body}; font-weight: 600; font-size: 22pt; color: ${accent_strong}; line-height: 1.14;
  letter-spacing: -0.2px; margin: 0 0 5mm; padding-bottom: 3.5mm; border-bottom: 0.8pt solid ${rule}; }
h2 { font-family: ${font_head}; font-weight: 600; font-size: 12.8pt; color: ${accent_strong}; margin: 8mm 0 2.5mm; }
h2::before { content: '\\25CF'; font-size: 6pt; color: ${accent}; vertical-align: 2pt; margin-right: 2.5mm; }
h3 { font-family: ${font_head}; font-weight: 600; font-size: 10.6pt; color: ${accent}; margin: 5mm 0 1.5mm; }
ul, ol { margin: 3mm 0; padding-left: 5.5mm; }
li { margin: 1.6mm 0; padding-left: 1mm; }
ul li::marker { color: ${accent}; }
li::marker { font-weight: 600; }

blockquote { background: ${card_bg}; border: 0.6pt solid ${rule}; border-radius: 8pt; margin: 4mm 0;
  padding: 3.5mm 5mm; color: ${ink}; font-size: 10pt; line-height: 1.55; }
blockquote p:last-child { margin-bottom: 0; }
.panel { background: ${accent_soft}; border: 0.6pt solid ${rule}; border-radius: 9pt; padding: 1mm 6mm 2mm; margin: 4mm 0; }

table { width: 100%; border-collapse: collapse; margin: 4.5mm 0; font-size: 8.8pt; }
thead { display: table-header-group; }
th, td { padding: 2.1mm 2.6mm; text-align: left; vertical-align: top; }
th { font-family: ${font_head}; font-weight: 600; font-size: 8.2pt; letter-spacing: 0.2px;
  color: ${accent_strong}; background: ${accent_soft}; border-bottom: 1.2pt solid ${accent}; }
td { border-bottom: 0.5pt solid ${rule}; }
tbody tr:nth-child(even) td { background: ${row_alt}; }
tr.rec-row td { background: ${rec_bg}; }
tr.rec-row td:first-child { font-weight: 600; }

.g { display: inline-block; font-family: ${font_head}; font-size: 7.3pt; font-weight: 700; letter-spacing: 0.4px;
  text-transform: uppercase; padding: 0.4mm 2.1mm; border-radius: 9pt; vertical-align: 1.2pt; white-space: nowrap; }
.g-strong { color: ${gs_ink}; background: ${gs_bg}; }
.g-mod { color: ${gm_ink}; background: ${gm_bg}; }
.g-inf { color: ${gi_ink}; background: ${gi_bg}; }

code { font-family: 'SF Mono', Menlo, monospace; font-size: 8.4pt; background: ${card_bg}; padding: 0.5pt 3pt; border-radius: 3pt; color: ${accent_strong}; }
pre { background: ${card_bg}; padding: 3mm 3.5mm; border-radius: 6pt; font-size: 8.4pt; white-space: pre-wrap; border: 0.6pt solid ${rule}; }
pre code { background: none; padding: 0; }
""")

def build(d, title, subtitle, meta, tag, note, out, theme):
    import markdown
    from weasyprint import HTML
    d = pathlib.Path(d)
    files = sorted(p.name for p in d.glob("[0-9][0-9]-*.md"))
    if not files:
        sys.exit("No NN-*.md files found in %s" % d)
    overrides = {}
    lj = d / "labels.json"
    if lj.exists():
        overrides = json.loads(lj.read_text())
    docs, toc = [], []
    def walk(tokens, n):
        for t in tokens:
            if t["level"] <= 2:
                toc.append((t["level"], "f%d-%s" % (n, t["id"]), t["name"]))
            if t.get("children"):
                walk(t["children"], n)
    for n, fn in enumerate(files):
        md = markdown.Markdown(extensions=["tables", "fenced_code", "toc", "sane_lists", "attr_list"])
        body = enhance(prefix_ids(md.convert((d / fn).read_text(encoding="utf-8")), n))
        docs.append((label_for(fn, overrides), body, n))
        walk(md.toc_tokens, n)
        md.reset()
    toc_html = '<section class="toc-page"><h1 class="toc-title">Contents</h1><ul class="toc">'
    for lvl, tid, name in toc:
        toc_html += '<li class="toc-l%d"><a href="#%s">%s</a></li>' % (lvl, tid, html.escape(html.unescape(name)))
    toc_html += "</ul></section>"
    cover = ('<section class="cover meta-strings" data-tag="%s" data-tag2="%s">'
             '<div class="cmark"></div><div class="kicker">%s</div><h1 class="ctitle">%s</h1>'
             '<div class="csub">%s</div><div class="cmeta">%s</div><div class="cnote">%s</div></section>') % (
        html.escape(tag or ""), html.escape(tag or ""), html.escape(tag or "Research package"),
        html.escape(title), html.escape(subtitle or ""), html.escape(meta or ""), html.escape(note or ""))
    body_html = "".join('<section class="doc" id="doc-%d"><div class="kick">%s</div>%s</section>' % (n, html.escape(lbl), b)
                        for lbl, b, n in docs)
    css = CSS_TMPL.safe_substitute(theme)
    full = "<!DOCTYPE html><html><head><meta charset='utf-8'><style>" + css + "</style></head><body>" + cover + toc_html + body_html + "</body></html>"
    out = out or str(d / (re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-') + ".pdf"))
    rendered = HTML(string=full).render()
    rendered.write_pdf(out)
    print("PAGES", len(rendered.pages))
    print("WROTE", out)
    return out

def reveal(path):
    """Open the finished package in the OS file browser. Never crash the render if this fails."""
    import subprocess, platform
    try:
        p = pathlib.Path(path)
        if platform.system() == "Darwin":
            subprocess.run(["open", "-R", str(p)], check=False)   # reveal + select the PDF in Finder
        elif platform.system() == "Windows":
            subprocess.run(["explorer", "/select,", str(p)], check=False)
        else:
            subprocess.run(["xdg-open", str(p.parent)], check=False)
        print("REVEALED", p.parent)
    except Exception as e:
        print("REVEAL-SKIPPED", e)

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--subtitle", default="")
    ap.add_argument("--meta", default="")
    ap.add_argument("--tag", default="")
    ap.add_argument("--note", default="Decision-support. Not medical/legal advice. Evidence graded strong / moderate / inference. Citations independently verified.")
    ap.add_argument("--theme", default="", help="theme name (care | default); overrides theme.json")
    ap.add_argument("--out", default="")
    ap.add_argument("--no-open", action="store_true", help="don't reveal the finished PDF in the file browser")
    a = ap.parse_args()
    theme = resolve_theme(a.dir, a.theme)
    written = build(a.dir, a.title, a.subtitle, a.meta, a.tag, a.note, a.out, theme)
    if not a.no_open:
        reveal(written)

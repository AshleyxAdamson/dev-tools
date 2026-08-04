#!/usr/bin/env python3
"""
generate.py - call pay-as-you-go media aggregators (kie.ai, fal.ai, wavespeed)
to make images/video, with budget guardrails, prompt logging, and local saving.

Stdlib only (urllib) - no pip install required.

Providers & auth (env vars):
  kie.ai      KIE_API_KEY        Authorization: Bearer <key>
  fal.ai      FAL_KEY            Authorization: Key <key>
  wavespeed   WAVESPEED_API_KEY  Authorization: Bearer <key>

Typical use:
  # dry run: craft/echo prompt + cost estimate, generate nothing
  python generate.py --model nano-banana --prompt "green apple energy shot ad" --n 3 --dry-run

  # real generation, cheapest available provider, $3 session cap
  python generate.py --model nano-banana --prompt "..." --n 3 --budget 3 --out ./generations

  # force a provider / pass an exact provider slug
  python generate.py --provider fal --model fal-ai/nano-banana --prompt "..."

Every output is saved to <out>/ with a sidecar .json (prompt, model, provider,
cost, seed, timestamp) and appended to <out>/prompts.jsonl. Session spend is
tracked in <out>/.ledger.json and enforced against --budget.

WHY THE REGISTRY LOOKS LIKE THIS
Every model has its OWN input field names. There is no shared body you can post
everywhere: an aspect ratio is `aspect_ratio` on kie + most fal models, a named
enum in `image_size` on fal's OpenAI models, and a "1024*1024" string in `size`
on wavespeed. Reference images are `image_urls`, `image_input`, `input_urls`,
`reference_image_urls` or `images` depending on the model. Several models reject
`seed` outright. So each host row declares how to spell its params, and
build_input() does the translation. Adding a model = adding a row, never editing
the request code.
"""
import argparse, json, os, re, sys, time, urllib.request, urllib.error, base64, mimetypes
from datetime import datetime, timezone

# ---------------------------------------------------------------------------
# Model registry: logical name -> per-provider host row.
#
# Host row keys:
#   slug   native model id posted to the provider
#   cost   approx USD per output, for pre-generation budgeting only
#   aspect how this model spells aspect ratio: "aspect_ratio" | "image_size"
#          | "size_wh" | None (model takes no ratio param)
#   seed   name of the seed field, or None if the model rejects seeds
#   batch  name of the "make N at once" field, or None (then we loop N calls)
#   extra  fixed params always sent
#   edit   variant used when --ref is passed: {"slug":..., "refs": <field name>}
#          absent = this host can't take reference images for this model
#
# Slugs + fields verified against live provider docs/OpenAPI on 2026-08-02.
# Costs drift constantly and several models price by resolution - treat them as
# ceilings for budgeting, not invoices. kie returns real creditsConsumed, which
# is recorded in the sidecar.
# ---------------------------------------------------------------------------
REGISTRY = {
    # --- images ---
    "nano-banana": {"kind": "image", "hosts": {
        "kie": {"slug": "google/nano-banana", "cost": 0.04, "aspect": "aspect_ratio",
                "seed": None, "batch": None,
                "edit": {"slug": "google/nano-banana-edit", "refs": "image_urls"}},
        "fal": {"slug": "fal-ai/nano-banana", "cost": 0.05, "aspect": "aspect_ratio",
                "seed": "seed", "batch": "num_images",
                "edit": {"slug": "fal-ai/nano-banana/edit", "refs": "image_urls"}},
    }},
    "nano-banana-pro": {"kind": "image", "hosts": {
        "kie": {"slug": "nano-banana-pro", "cost": 0.10, "aspect": "aspect_ratio",
                "seed": None, "batch": None,
                "edit": {"slug": "nano-banana-pro", "refs": "image_input"}},
        "fal": {"slug": "fal-ai/nano-banana-pro", "cost": 0.12, "aspect": "aspect_ratio",
                "seed": "seed", "batch": "num_images",
                "edit": {"slug": "fal-ai/nano-banana-pro/edit", "refs": "image_urls"}},
    }},
    "nano-banana-2": {"kind": "image", "hosts": {
        "kie": {"slug": "nano-banana-2", "cost": 0.08, "aspect": "aspect_ratio",
                "seed": None, "batch": None},
    }},
    "gpt-image-2": {"kind": "image", "hosts": {
        # fal prices this by quality x resolution ($0.005 low 1K -> $0.40 high 4K).
        # 0.12 is a mid-range ceiling; raise it before asking for 4K.
        "kie": {"slug": "gpt-image-2-text-to-image", "cost": 0.05, "aspect": "aspect_ratio",
                "seed": None, "batch": None,
                "edit": {"slug": "gpt-image-2-image-to-image", "refs": "input_urls"}},
        "fal": {"slug": "openai/gpt-image-2", "cost": 0.12, "aspect": "image_size",
                "seed": None, "batch": "num_images",
                "edit": {"slug": "openai/gpt-image-2/edit", "refs": "image_urls"}},
    }},
    "z-image": {"kind": "image", "hosts": {
        "kie": {"slug": "z-image", "cost": 0.01, "aspect": "aspect_ratio",
                "seed": None, "batch": None},
        "wavespeed": {"slug": "wavespeed-ai/z-image/turbo", "cost": 0.005,
                      "aspect": "size_wh", "seed": "seed", "batch": None},
    }},
    # --- video (per-clip ballparks; scale hard with duration + resolution) ---
    "kling": {"kind": "video", "hosts": {
        "kie": {"slug": "kling-3.0/video", "cost": 0.30, "aspect": "aspect_ratio",
                "seed": None, "batch": None},
    }},
    "seedance": {"kind": "video", "hosts": {
        "kie": {"slug": "bytedance/seedance-2", "cost": 0.25, "aspect": "aspect_ratio",
                "seed": None, "batch": None,
                "edit": {"slug": "bytedance/seedance-2", "refs": "reference_image_urls"}},
        "fal": {"slug": "bytedance/seedance-2.0/text-to-video", "cost": 0.30,
                "aspect": "aspect_ratio", "seed": None, "batch": None},
    }},
}

# cheapest-first routing order
PROVIDER_ORDER = ["kie", "fal", "wavespeed"]

ENV_KEY = {"kie": "KIE_API_KEY", "fal": "FAL_KEY", "wavespeed": "WAVESPEED_API_KEY"}
IMG_EXT = (".png", ".jpg", ".jpeg", ".webp", ".gif")
VID_EXT = (".mp4", ".webm", ".mov", ".m4v")

# aspect ratio -> fal's named image_size enum (openai/* models on fal)
IMAGE_SIZE_MAP = {"1:1": "square_hd", "4:3": "landscape_4_3", "3:4": "portrait_4_3",
                  "16:9": "landscape_16_9", "9:16": "portrait_16_9", "auto": "auto"}
# aspect ratio -> wavespeed's "W*H" string, ~1MP
SIZE_WH_MAP = {"1:1": "1024*1024", "16:9": "1280*720", "9:16": "720*1280",
               "4:3": "1024*768", "3:4": "768*1024"}

CONTENT_TYPE_EXT = {"image/png": ".png", "image/jpeg": ".jpg", "image/webp": ".webp",
                    "image/gif": ".gif", "video/mp4": ".mp4", "video/webm": ".webm",
                    "video/quicktime": ".mov"}


def eprint(*a): print(*a, file=sys.stderr)


class ApiError(Exception):
    """Provider said no. Carries enough to tell the user which provider and why."""
    def __init__(self, provider, msg, status=None, body=None):
        self.provider, self.msg, self.status, self.body = provider, msg, status, body
        super().__init__(f"[{provider}] {msg}" + (f" (HTTP {status})" if status else ""))


def http(provider, method, url, headers=None, body=None, timeout=120):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read().decode()
    except urllib.error.HTTPError as e:
        text = e.read().decode(errors="replace")[:800]
        detail = text
        try:  # most providers wrap the real reason in JSON
            j = json.loads(text)
            detail = j.get("message") or j.get("msg") or j.get("detail") or j.get("error") or text
            if isinstance(detail, (dict, list)):
                detail = json.dumps(detail)[:500]
        except json.JSONDecodeError:
            pass
        raise ApiError(provider, f"{method} {url}\n  {detail}", status=e.code, body=text)
    except urllib.error.URLError as e:
        raise ApiError(provider, f"network error on {method} {url}: {e}")
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {"_raw": raw}


def extract_urls(obj, kind):
    """Pull output URLs out of a provider payload.

    Do NOT rely on file extensions - fal and wavespeed CDN URLs often carry no
    extension or a query string. Collect any {"url": "http..."} object plus any
    bare URL strings in an outputs-style list, then order-preserve + dedupe.
    """
    out = []

    def walk(x):
        if isinstance(x, dict):
            u = x.get("url")
            if isinstance(u, str) and u.startswith("http"):
                out.append(u)
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                if isinstance(v, str) and v.startswith("http"):
                    out.append(v)
                else:
                    walk(v)

    walk(obj)
    seen, uniq = set(), []
    for u in out:
        if u not in seen:
            seen.add(u)
            uniq.append(u)
    if not uniq:  # last resort: extension scan over every string in the payload
        exts = VID_EXT if kind == "video" else IMG_EXT
        uniq = _ext_scan(obj, exts + (IMG_EXT + VID_EXT))
    return uniq


def _ext_scan(obj, exts):
    found = []
    def walk(x):
        if isinstance(x, str):
            if x.startswith("http") and any(x.split("?")[0].lower().endswith(e) for e in exts):
                found.append(x)
        elif isinstance(x, dict):
            for v in x.values(): walk(v)
        elif isinstance(x, list):
            for v in x: walk(v)
    walk(obj)
    return found


def to_data_uri(path):
    mime = mimetypes.guess_type(path)[0] or "image/png"
    with open(path, "rb") as f:
        return f"data:{mime};base64,{base64.b64encode(f.read()).decode()}"


# ---------------------------------------------------------------------------
# Request building: translate one neutral intent into this model's field names.
# ---------------------------------------------------------------------------
def build_input(provider, host, kind, prompt, aspect, refs, seed, n, warn=True):
    """Return (slug, input_dict, produced_count). produced_count is how many
    outputs this ONE call is expected to yield (>1 only when the model batches)."""
    slug = host["slug"]
    inp = {"prompt": prompt}

    if refs:
        edit = host.get("edit")
        if not edit:
            raise ApiError(provider, f"model '{slug}' on {provider} takes no reference "
                                     f"images. Drop --ref, or pick another model/provider.")
        slug = edit["slug"]
        prepared = []
        for r in refs:
            if r.startswith("http"):
                prepared.append(r)
            elif provider == "fal":
                prepared.append(to_data_uri(r))  # fal accepts data: URIs
            else:
                raise ApiError(provider, f"{provider} needs reference images as public "
                                         f"URLs; '{r}' is a local file. Upload it first "
                                         f"or use --provider fal.")
        inp[edit["refs"]] = prepared

    mode = host.get("aspect")
    if aspect:
        if mode == "aspect_ratio":
            inp["aspect_ratio"] = aspect
        elif mode == "image_size":
            if aspect not in IMAGE_SIZE_MAP:
                raise ApiError(provider, f"aspect '{aspect}' has no {provider} image_size "
                                         f"equivalent. Use one of {list(IMAGE_SIZE_MAP)}.")
            inp["image_size"] = IMAGE_SIZE_MAP[aspect]
        elif mode == "size_wh":
            if aspect not in SIZE_WH_MAP:
                raise ApiError(provider, f"aspect '{aspect}' has no {provider} size mapping. "
                                         f"Use one of {list(SIZE_WH_MAP)}.")
            inp["size"] = SIZE_WH_MAP[aspect]
        elif warn:
            eprint(f"  note: {slug} takes no aspect param; --aspect {aspect} ignored")

    if seed is not None:
        if host.get("seed"):
            inp[host["seed"]] = seed
        elif warn:
            eprint(f"  note: {slug} does not accept a seed; --seed ignored")

    produced = 1
    if n > 1 and host.get("batch"):
        inp[host["batch"]] = n
        produced = n

    inp.update(host.get("extra") or {})
    return slug, inp, produced


# ---------------------------------------------------------------------------
# Provider drivers: submit + poll, return (urls, provider_meta).
# ---------------------------------------------------------------------------
def poll_sleep(i):
    """Back off 2s -> 8s instead of hammering every 3s for five minutes."""
    return min(2 + i, 8)


def run_kie(slug, key, inp, kind, timeout):
    r = http("kie", "POST", "https://api.kie.ai/api/v1/jobs/createTask",
             {"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
             {"model": slug, "input": inp})
    # kie answers HTTP 200 with a non-200 envelope code for auth/credit/param
    # errors. Without this check the failure surfaces as a confusing "no taskId".
    if r.get("code") != 200:
        raise ApiError("kie", f"createTask rejected (code {r.get('code')}): "
                              f"{r.get('msg') or r}")
    task = (r.get("data") or {}).get("taskId")
    if not task:
        raise ApiError("kie", f"no taskId in response: {json.dumps(r)[:400]}")
    deadline = time.time() + timeout
    i = 0
    while time.time() < deadline:
        time.sleep(poll_sleep(i)); i += 1
        s = http("kie", "GET", f"https://api.kie.ai/api/v1/jobs/recordInfo?taskId={task}",
                 {"Authorization": f"Bearer {key}"})
        if s.get("code") != 200:
            raise ApiError("kie", f"recordInfo error (code {s.get('code')}): {s.get('msg')}")
        d = s.get("data") or {}
        state = d.get("state")
        if state == "success":
            rj = d.get("resultJson")
            parsed = json.loads(rj) if isinstance(rj, str) else (rj or {})
            urls = parsed.get("resultUrls") or extract_urls(parsed, kind)
            return urls, {"creditsConsumed": d.get("creditsConsumed"),
                          "costTimeMs": d.get("costTime")}
        if state == "fail":
            raise ApiError("kie", f"task failed: {d.get('failMsg') or d.get('failCode') or d}")
    raise ApiError("kie", f"timed out after {timeout}s waiting for task {task}")


def run_fal(slug, key, inp, kind, timeout):
    hdr = {"Authorization": f"Key {key}", "Content-Type": "application/json"}
    sub = http("fal", "POST", f"https://queue.fal.run/{slug}", hdr, inp)
    rid = sub.get("request_id")
    if not rid:
        raise ApiError("fal", f"no request_id in response: {json.dumps(sub)[:400]}")
    status_url = sub.get("status_url") or f"https://queue.fal.run/{slug}/requests/{rid}/status"
    result_url = sub.get("response_url") or f"https://queue.fal.run/{slug}/requests/{rid}"
    deadline = time.time() + timeout
    i = 0
    while time.time() < deadline:
        time.sleep(poll_sleep(i)); i += 1
        # fal reports a failed job as an HTTP error on the status endpoint, not
        # as a FAILED status value - its enum is only IN_QUEUE/IN_PROGRESS/COMPLETED.
        st = http("fal", "GET", status_url, {"Authorization": f"Key {key}"})
        status = st.get("status")
        if status == "COMPLETED":
            res = http("fal", "GET", result_url, {"Authorization": f"Key {key}"})
            return extract_urls(res, kind), {"request_id": rid}
        if status in ("FAILED", "ERROR", "CANCELLED"):
            raise ApiError("fal", f"task failed: {json.dumps(st)[:400]}")
    raise ApiError("fal", f"timed out after {timeout}s waiting for request {rid}")


def run_wavespeed(slug, key, inp, kind, timeout):
    hdr = {"Authorization": f"Bearer {key}", "Content-Type": "application/json"}
    sub = http("wavespeed", "POST", f"https://api.wavespeed.ai/api/v3/{slug}", hdr, inp)
    d = sub.get("data") or {}
    get_url = (d.get("urls") or {}).get("get")
    pid = d.get("id")
    if not get_url and pid:
        get_url = f"https://api.wavespeed.ai/api/v3/predictions/{pid}/result"
    if not get_url:
        raise ApiError("wavespeed", f"no result url in response: {json.dumps(sub)[:400]}")
    deadline = time.time() + timeout
    i = 0
    while time.time() < deadline:
        time.sleep(poll_sleep(i)); i += 1
        s = http("wavespeed", "GET", get_url, {"Authorization": f"Bearer {key}"})
        sd = s.get("data") or {}
        status = sd.get("status")
        if status == "completed":
            return (extract_urls(sd.get("outputs") or sd, kind), {"id": pid})
        if status in ("failed", "cancelled", "timeout"):
            raise ApiError("wavespeed", f"task {status}: {sd.get('error') or json.dumps(sd)[:400]}")
    raise ApiError("wavespeed", f"timed out after {timeout}s waiting for {pid}")


DRIVERS = {"kie": run_kie, "fal": run_fal, "wavespeed": run_wavespeed}


def resolve(provider, model, require_key=True):
    """Return (provider, host_row, kind). Supports logical names and raw native
    slugs when --provider is explicit. When require_key is False (dry-run),
    route without needing a key so a preview still works."""
    entry = REGISTRY.get(model)
    if entry:
        kind = entry["kind"]
        hosts = entry["hosts"]
        candidates = [provider] if provider != "auto" else PROVIDER_ORDER
        for p in candidates:
            if p in hosts and os.environ.get(ENV_KEY[p]):
                return p, hosts[p], kind
        avail = [p for p in candidates if p in hosts]
        if not require_key and avail:
            return avail[0], hosts[avail[0]], kind
        allhosts = [p for p in PROVIDER_ORDER if p in hosts]
        if provider != "auto" and provider not in hosts:
            raise SystemExit(f"'{model}' is not hosted on {provider}. Hosted on: {allhosts}.")
        raise SystemExit(f"No API key set for a provider hosting '{model}'. "
                         f"Hosted on: {allhosts}. Set one of "
                         f"{[ENV_KEY[p] for p in allhosts]}.")
    if provider == "auto":
        raise SystemExit(f"'{model}' is not a known logical model. Pass --provider "
                         f"explicitly with a native slug, or use one of: "
                         f"{', '.join(REGISTRY)}")
    if require_key and not os.environ.get(ENV_KEY[provider]):
        raise SystemExit(f"{ENV_KEY[provider]} not set.")
    # Raw slug: we don't know this model's field names, so send the most common
    # spelling and a conservative cost. Expect a 4xx if the model differs.
    eprint(f"note: '{model}' is not in the registry - assuming aspect_ratio/seed/"
           f"image_urls field names and a $0.15 cost ceiling.")
    return provider, {"slug": model, "cost": 0.15, "aspect": "aspect_ratio",
                      "seed": "seed", "batch": None,
                      "edit": {"slug": model, "refs": "image_urls"}}, "image"


def download(url, dest_base, kind):
    """Save the file, picking the extension from the URL, then Content-Type,
    then the media kind. Returns the final path."""
    req = urllib.request.Request(url, headers={"User-Agent": "generate.py"})
    with urllib.request.urlopen(req, timeout=180) as r:
        data = r.read()
        ctype = (r.headers.get("Content-Type") or "").split(";")[0].strip().lower()
    ext = next((e for e in IMG_EXT + VID_EXT if url.split("?")[0].lower().endswith(e)), None)
    ext = ext or CONTENT_TYPE_EXT.get(ctype) or (".mp4" if kind == "video" else ".png")
    path = dest_base + ext
    with open(path, "wb") as f:
        f.write(data)
    return path


def ledger_path(out): return os.path.join(out, ".ledger.json")


def read_spend(out):
    try:
        with open(ledger_path(out)) as f: return json.load(f).get("spent", 0.0)
    except (FileNotFoundError, json.JSONDecodeError):
        return 0.0


def add_spend(out, amount):
    spent = read_spend(out) + amount
    with open(ledger_path(out), "w") as f:
        json.dump({"spent": round(spent, 4), "updated": datetime.now(timezone.utc).isoformat()}, f)
    return spent


def slugify(s, n=40):
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:n] or "gen"


def main():
    ap = argparse.ArgumentParser(description="Generate images/video via pay-as-you-go aggregators.")
    ap.add_argument("--model", required=True, help="logical name (%s) or native slug with --provider" % ", ".join(REGISTRY))
    ap.add_argument("--prompt", required=True)
    ap.add_argument("--provider", default="auto", choices=["auto", "kie", "fal", "wavespeed"])
    ap.add_argument("--n", type=int, default=1, help="number of variations")
    ap.add_argument("--aspect", default=None, help="aspect ratio, e.g. 1:1 16:9 9:16 (default: the model's own)")
    ap.add_argument("--ref", action="append", default=[], help="reference image URL or local path (repeatable); routes to the model's edit variant")
    ap.add_argument("--seed", type=int, default=None, help="base seed (incremented per variation); ignored by models that reject seeds")
    ap.add_argument("--out", default="./generations", help="output dir")
    ap.add_argument("--budget", type=float, default=None, help="hard session spend cap (USD) across --out ledger")
    ap.add_argument("--max-cost", type=float, default=None, help="refuse if THIS call's estimate exceeds it")
    ap.add_argument("--dry-run", action="store_true", help="print prompt + cost estimate, generate nothing")
    ap.add_argument("--timeout", type=int, default=300, help="per-request wait seconds")
    args = ap.parse_args()

    if args.n < 1:
        raise SystemExit("--n must be at least 1")

    provider, host, kind = resolve(args.provider, args.model, require_key=not args.dry_run)
    unit = host["cost"]
    est = unit * args.n
    os.makedirs(args.out, exist_ok=True)
    prior = read_spend(args.out)

    try:
        preview_slug, preview_input, per_call = build_input(
            provider, host, kind, args.prompt, args.aspect, args.ref, args.seed, args.n)
    except ApiError as e:
        raise SystemExit(str(e))
    calls = 1 if per_call > 1 else args.n

    # ---- HARD budget rules (the whole point of this skill) ----
    print(f"provider={provider}  slug={preview_slug}  kind={kind}")
    print(f"variations={args.n} in {calls} call(s)  est unit=${unit:.3f}  est total=${est:.3f}")
    print(f"session spent so far=${prior:.3f}" + (f"  budget=${args.budget:.2f}" if args.budget else ""))
    if args.max_cost is not None and est > args.max_cost:
        raise SystemExit(f"REFUSED: est ${est:.3f} exceeds --max-cost ${args.max_cost:.2f}")
    if args.budget is not None and prior + est > args.budget:
        raise SystemExit(f"REFUSED: est ${est:.3f} would push session spend to "
                         f"${prior+est:.3f}, over --budget ${args.budget:.2f}")
    if args.dry_run:
        print("\n[dry-run] prompt:\n" + args.prompt)
        print("\n[dry-run] request input that would be posted:")
        print(json.dumps(preview_input, indent=2)[:1200])
        print(f"\n[dry-run] would generate {args.n} x {preview_slug} for ~${est:.3f}. No API calls made.")
        return

    key = os.environ[ENV_KEY[provider]]
    driver = DRIVERS[provider]
    ts = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    made = []
    for c in range(calls):
        seed = (args.seed + c) if args.seed is not None else None
        slug, inp, produced = build_input(provider, host, kind, args.prompt, args.aspect,
                                          args.ref, seed, args.n if calls == 1 else 1,
                                          warn=(c == 0))
        label = f"{produced} image(s)" if produced > 1 else f"{c+1}/{calls}"
        print(f"\n[{label}] generating...")
        try:
            urls, meta = driver(slug, key, inp, kind, args.timeout)
        except ApiError as e:
            eprint(f"  !! {e}")
            if c == 0:
                raise SystemExit("first call failed - stopping before spending more.")
            continue
        if not urls:
            eprint(f"  !! no output url returned for call {c+1}")
            continue
        for j, url in enumerate(urls):
            base = f"{ts}_{slugify(args.prompt)}_{c+1}" + (f"-{j+1}" if len(urls) > 1 else "")
            fpath = download(url, os.path.join(args.out, base), kind)
            side = {"prompt": args.prompt, "model": args.model, "slug": slug,
                    "provider": provider, "kind": kind, "aspect": args.aspect,
                    "seed": seed, "refs": args.ref, "source_url": url,
                    "request_input": inp, "est_cost": unit, "provider_meta": meta,
                    "created": datetime.now(timezone.utc).isoformat()}
            with open(os.path.join(args.out, base + ".json"), "w") as f:
                json.dump(side, f, indent=2)
            with open(os.path.join(args.out, "prompts.jsonl"), "a") as f:
                f.write(json.dumps({"file": os.path.basename(fpath), **side}) + "\n")
            made.append(fpath)
            print(f"  saved {fpath}")
        add_spend(args.out, unit * len(urls))

    total = read_spend(args.out)
    print(f"\nDone. {len(made)} file(s) in {args.out}. Session spend now ~${total:.3f}.")
    for m in made: print("  " + m)


if __name__ == "__main__":
    try:
        main()
    except ApiError as e:
        raise SystemExit(str(e))
    except KeyboardInterrupt:
        raise SystemExit("\ninterrupted")

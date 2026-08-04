# Providers

Open this when a call fails.

| Provider | Env var | Auth header | Notes |
|---|---|---|---|
| kie.ai | `KIE_API_KEY` | `Authorization: Bearer <key>` | cheapest; reliability dips under load |
| fal.ai | `FAL_KEY` | `Authorization: Key <key>` | most reliable; only one accepting local ref files |
| wavespeed.ai | `WAVESPEED_API_KEY` | `Authorization: Bearer <key>` | niche models; needs a top-up to activate |

Keys: kie.ai/api-key · fal.ai/dashboard/keys · wavespeed.ai dashboard.

## kie.ai

- **Create:** `POST https://api.kie.ai/api/v1/jobs/createTask`
  `{"model":"<slug>","input":{...},"callBackUrl":"<optional>"}`
- **Poll:** `GET https://api.kie.ai/api/v1/jobs/recordInfo?taskId=<id>` -
  `data.state` cycles `waiting|queuing|generating|success|fail`. On success
  `data.resultJson` is a JSON **string** -> parse -> `resultUrls[]`.
  `creditsConsumed` is real spend; `failMsg` explains a fail.
- **The envelope lies about HTTP status.** kie answers **HTTP 200 with a non-200
  `code`** for auth, credit and param errors. Check `code == 200` before reading
  `data`, or a rejected call looks like "no taskId".
- **Result URLs expire ~24h.** Download immediately.
- **Slugs are inconsistently namespaced:** `google/nano-banana`, bare
  `nano-banana-pro`, pathed `kling-3.0/video`. Never infer one.

## fal.ai

- **Submit:** `POST https://queue.fal.run/<slug>` -> `{request_id, status_url,
  response_url}`. Full slug stays in the requests path, subpaths included.
- **Poll:** `GET <status_url>` - `IN_QUEUE -> IN_PROGRESS -> COMPLETED`. **That
  enum has no failure value**; a failed job returns an HTTP 4xx/5xx on the status
  endpoint. Don't wait for a `FAILED` string.
- **Result:** `GET <response_url>` - `images[].url` / `video.url`.
- **Output URLs often have no file extension.** Read `.url` keys; never filter by
  extension.
- **Verify any slug for free, no key:**
  `curl "https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=<slug>"`
  returns the full input schema and 404s on a bad slug. The HTML docs sit behind
  a bot checkpoint; this JSON endpoint does not.
- A fake request id returns `COMPLETED`, so status alone doesn't prove a job ran.

## wavespeed.ai

- **Submit:** `POST https://api.wavespeed.ai/api/v3/<slug>` with
  `{"prompt":"...","size":"1024*1024"}` (note the `*`) -> `data.id`, `data.urls.get`
- **Poll:** `GET data.urls.get` - `data.status` is
  `created|processing|completed|failed|cancelled|timeout`; outputs in `data.outputs[]`.
  `enable_sync_mode:true` blocks and returns inline.
- Auth is checked before routing, so a 401 tells you nothing about the slug.

## When a call 4xx's

Check the field names first, not the prompt. Pull fal's OpenAPI JSON or the kie
model page and compare against the registry row.

---
name: Chrome browser identification
description: Maps Claude in Chrome deviceIds to the user's accounts so the right browser can be picked when calling select_browser
type: user
originSessionId: 74a384b5-cafb-46df-8f03-60f47ffc3abb
---
The user has two Chrome browsers connected to Claude in Chrome MCP. Display names in `list_connected_browsers` may revert to generic "Browser 1 / Browser 2" labels even after rename, so identify by **deviceId**.

| deviceId | Account / purpose | Notes |
|---|---|---|
| `9fdcdc33-163c-4bdc-839a-e7b36a483f32` | `yuki.watabe@someru.me` (work, GitHub `Someru-3321`) | Used for GitHub dotfiles setup on 2026-05-02. Renamed via `switch_browser` to `"yuki.watabe@someru.me"` on 2026-05-04. |
| `d49075eb-124e-450c-8e47-2fdcee80c6e2` | `entertainment@someru.me` (personal) | Not yet renamed at the extension level. Confirmed by user as the non-work browser. |

When the user asks to "use the browser logged into X" or "the work browser":
- Work / yuki.watabe / Someru-3321 GitHub → deviceId `9fdcdc33-...`
- Entertainment / personal → deviceId `d49075eb-...`

Calling `select_browser` with the right deviceId is more reliable than reading the display name.

**Note on cross-Mac portability**: deviceIds are unique per Chrome installation, so the IDs above only apply to **this** Mac. On a different Mac, the user has the same dual-account setup (work + entertainment) but with different deviceIds — re-derive the mapping by calling `list_connected_browsers` and asking the user once.

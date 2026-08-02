# Mods Listing: Filter/Sort Param Preservation Matrix

**Date:** 2026-08-01
**Status:** Approved (scope + verification decided in session)

## Problem

Changing the author filter resets the DL Type filter (and query and sort): `navigateToAuthor` (app/javascript/controllers/mods_controller.js:8-17) builds `origin + "/mods[/author]"` and discards the whole query string. Separately (previously parked): submitting the search form — typing a query or changing DL Type — preserves author/query/type but resets sort, because the form carries no sort state.

Expected: **every listing control preserves every other control's state**, except "Show All Mods", which resets everything.

## The Matrix (requirements)

| Control | Must preserve | Resets |
|---|---|---|
| Author select (incl. its "All" blank option) | query, type, sort, dir | page |
| Search query typing (debounced submit) | author (via path), type, sort, dir | page |
| DL Type select | author (via path), query, sort, dir | page |
| Sort header links | author (via path), query, type | page (already shipped) |
| Pagination links | author (via path), query, type, sort, dir | — (already shipped) |
| **Show All Mods link** | **nothing — bare `mods_path`, resets everything** (current behavior, now pinned) | all |

## Design

1. **`navigateToAuthor`** (mods_controller.js): keep building the path from the selected author, but append the current query string minus `page`:
   - `const params = new URLSearchParams(window.location.search); params.delete("page");`
   - navigate to `origin + modsPath + (params.size ? "?" + params : "")`.
   - Works for both selecting an author and selecting the blank "All" option (→ `/mods?type=...&sort=...`).
2. **Search form sort persistence** (index.html.erb + mods_controller.js):
   - Add hidden fields inside the form: `form.hidden_field :sort, value: params[:sort]` and `:dir` (rendered blank when absent — blank params are dropped server-side by the existing `presence_in` whitelists).
   - **Staleness guard:** the form lives OUTSIDE the `mods` turbo frame, so hidden values rendered at page load go stale after header-click sorting (frame navigation advances the URL without re-rendering the form). Fix in the existing Stimulus handlers: before `requestSubmit()` in both `search()` and `submit()`, sync the hidden fields from `new URLSearchParams(window.location.search)` (set to the current `sort`/`dir`, or clear when absent). Extract a small private `#syncSortFields(form)` used by both.
3. **Show All Mods:** unchanged (`link_to "Show All", mods_path`) — add a view-spec assertion pinning that its href is exactly the bare mods path, no params.

## Verification (per session decision: server specs + user smoke test; no new JS-test dependencies)

- Request specs (server-side composition — the contract the JS relies on): `GET /mods/:author?type=pak&sort=name&dir=desc` applies all three (author+type existed already; add sort to that matrix); `GET /mods?type=pak&sort=updated` etc. already covered.
- View specs: hidden `sort`/`dir` fields render inside the search form with current param values (and empty without params); Show All href is bare.
- JS changes: code-reviewed + verified by the user in the running dev server (no capybara/selenium — explicitly declined to keep dependencies minimal).
- Full suite green + rubocop clean, per house standard.

## Out of Scope

- System/JS test infrastructure (declined).
- Any change to Show All behavior.
- Tools page controls.

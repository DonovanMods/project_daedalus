# Mods Listing: Sortable Columns + Updated Column

**Date:** 2026-08-01
**Status:** Approved (design discussed and decided in session)

## Problem

The mods listing has a fixed order (name A→Z). Users can't sort by the columns they see, and there's no way to find recently updated mods — despite `Mod#updated_at` existing (Firestore document `update_time`, already shown on the detail page as "Last Updated on …").

## Requirements

1. **New "Updated" column** in the mods table, placed after Version, `hidden md:table-cell`, right-aligned, showing relative time (`time_ago_in_words(mod.updated_at) + " ago"`); em-dash placeholder when `updated_at` is nil (matching the Week column's `&mdash;` pattern).
2. **Clickable, sortable headers** for exactly: **Name, Download, Author, Updated**. Version/Week/Description headers stay plain text.
3. **Sort semantics:**
   - Params: `sort` ∈ `%w[updated name download author]`, `dir` ∈ `%w[asc desc]`; anything else falls back (invalid `sort` → default sort; invalid/absent `dir` → that column's first-click default).
   - First-click defaults: `updated` → `desc`; `name`/`download`/`author` → `asc`.
   - Clicking the active column's header toggles direction; clicking a different header switches to that column with its first-click default.
   - **Default order (no sort param): `updated` descending** — newest-first replaces name-A→Z as the landing order.
   - `name`/`author`: case-insensitive string compare.
   - `download`: sorts by the effective type label shown on the button (i.e. `download_type_for(params[:type]).to_s`), so it matches what the user sees under an active filter; ties break by name ascending for determinism.
   - `updated`: mods with nil `updated_at` sort LAST in both directions.
4. **Active-column indicator:** ▲ (asc) / ▼ (desc) appended to the active header's label; inactive headers show no arrow.
5. **Param preservation:** each header link carries the current `query` and `type` params along with its own `sort`/`dir` values. Links render inside the existing `mods` turbo frame with `turbo_action: advance` (URL bar reflects state). The pre-existing `navigateToAuthor` param-dropping bug is out of scope.
6. **Composition:** sorting applies AFTER query/type filters and BEFORE pagination. Sorting alone does not set `@filtered` (pagination still applies to sorted-unfiltered lists). `Mod.fetch_all`'s internal name sort and 5-minute cache are untouched — per-request sorting happens in the controller layer on the fetched array.

## Design

- **`app/models/mod.rb` / `Downloadable` boundary:** sorting is listing-presentation logic touching several attributes — put it on `Mod` directly (not the Downloadable concern):
  - `Mod::SORTKEYS` (vestigial today, only asserted in specs) becomes the whitelist: `%w[updated name download author]` — update the constant's spec accordingly. `Tool::SORTKEYS` untouched.
  - `Mod.sort_mods(mods, key:, dir:, type_filter: nil)` class method implementing requirement 3 (returns a new array; `download` key uses each mod's `download_type_for(type_filter)`).
- **`ModsController#index`:** private `sort_mods` step after `filter_by_type`, before `paginate_mods`: resolves whitelisted `params[:sort]`/`params[:dir]` (fallbacks per requirement 3), calls `Mod.sort_mods`, does NOT touch `@filtered`. Exposes `@sort`/`@dir` for the view.
- **`ModHelper`:**
  - `sort_link(label, key)` → returns the header link: href = `url_for` merging current `query`/`type` with `sort: key` and computed `dir` (toggle if `key == @sort`, else first-click default), `data: {turbo_action: "advance"}`, label suffixed with the arrow when active.
  - First-click defaults live in one place (e.g. `SORT_DEFAULT_DIRS = {"updated" => "desc"}.freeze` with `"asc"` fallback), used by both helper and controller — put the constant on `Mod` next to `SORTKEYS` so there's a single owner.
- **`app/views/mods/_mods.html.erb`:** the four `<th>` texts become `sort_link` calls; new Updated `<th>` + `<td>` (in `_mod.html.erb`) per requirement 1.

## Testing (test-first)

- Model: `Mod.sort_mods` — each key both directions, case-insensitivity, download-with-filter key, nil-updated_at-last both directions, name tiebreak on download, whitelist constant spec update.
- Request: default order is updated-desc; `sort=name` asc; `sort=name&dir=desc`; invalid sort/dir fallbacks; sort composes with `query`+`type`; sorted-unfiltered still paginates (page param honored).
- Helper: `sort_link` href param merging (preserves query/type), toggle vs first-click dir logic, arrow presence/absence.
- View: Updated column renders relative time and em-dash for nil; active header shows arrow.

## Out of Scope

- Fixing `navigateToAuthor` param dropping (pre-existing; separate story).
- Sorting on the Tools page.
- Any change to `fetch_all` caching or Firestore queries.

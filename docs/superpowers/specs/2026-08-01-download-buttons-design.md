# Download Buttons: Labels, Priority, and Per-Format Colors

**Date:** 2026-08-01
**Status:** Approved

## Problem

On the mods listing, the download column button renders as "downloadEXMODZ" / "downloadPAK" (the `Download ` prefix is `hidden sm:inline`, so on small screens the words smush together). All download buttons share one color, and the format-priority order no longer matches what the site should prefer.

## Requirements

1. **Listing button label** shows only the format name: `ZIP`, `PAK`, `EXMODZ`, or `EXMOD` — no `Download` prefix at any breakpoint.
2. **Format priority** (which single button the listing shows, via `Mod#preferred_type`): **ZIP > PAK > EXMODZ > EXMOD**. (Current code: pak > zip > exmodz > exmod.)
3. **Per-format button colors**, applied on BOTH the mods listing and the mod detail (show) page:
   - `PAK` → Tailwind emerald (`bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-400`), complementary green to the icarus gold.
   - `EXMODZ` / `EXMOD` → current icarus gold (`bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400`).
   - `ZIP` → indigo (`bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500`), the show page's current color.
4. **Show page** keeps its `DOWNLOAD <TYPE>` wording; only colors change there. Its buttons render in priority order: `Mod#download_types` intersection order becomes `%i[zip pak exmodz exmod]`.

## Design

- **`app/models/mod.rb`**
  - `preferred_type`: return order zip → pak → exmodz → exmod; update the priority comment.
  - `download_types`: `file_types.map(&:to_sym) & %i[zip pak exmodz exmod]` (intersection order = render order on show page).
- **`app/helpers/mods_helper.rb`** — new `download_button_classes(type)` returning the color-class string per format (single source of truth for both views). Structural/shared classes stay in the views; the helper returns only the per-format color classes (`bg-* hover:bg-* focus:ring-*`).
- **`app/views/mods/_mod.html.erb`** — remove the `<span class="hidden sm:inline">Download </span>`; use the helper for color classes.
- **`app/views/mods/show.html.erb`** — replace hardcoded indigo classes with the helper.

## Testing (test-first)

- `spec/models/mod_spec.rb` — update `#preferred_type` cases to the new order (e.g. zip+pak → :zip, pak+exmodz → :pak, exmodz+exmod → :exmodz); add a `#download_types` ordering expectation.
- `spec/helpers/mods_helper_spec.rb` — `download_button_classes` mapping for all four formats, plus: unknown/unexpected types return the icarus default (no raise — views already guard on real types).
- Request/view specs — update any assertion on the old `Download EXMODZ` button text.
- Visual: `bin/rails tailwindcss:build` then eyeball listing + show page (emerald/gold/indigo, light + dark).

## Out of Scope

- No change to download behavior/Stimulus controller, mod data, or other pages.
- No custom green palette entry (stock emerald chosen).

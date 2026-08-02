# Mods Search Bar: Download-Type Filter Select

**Date:** 2026-08-01
**Status:** Approved

## Problem

The mods listing can be searched by text and filtered by author, but not by download format. Users who only work with a given format (e.g. PAK) can't narrow the list to mods that offer it.

## Requirements

1. A **selectbox in the search bar** filters mods by download type. Options, in order:
   - `ALL` (value `all`) — default; no filtering
   - `PAK` (value `pak`)
   - `ZIP` (value `zip`)
   - `EXMOD(z)` (value `exmod`) — matches mods offering `exmod` OR `exmodz` files
2. Defaults to ALL; the selected value persists across turbo-frame refreshes via `params[:type]`.
3. Changing the select immediately refreshes the results (existing Stimulus `mods#submit` action).
4. Type filter **composes with the text query** (both apply). It also applies on author pages, since the form submits to `current_path`.
5. Unknown/absent `type` values behave as ALL. Param values are whitelisted; no user input reaches filtering logic unvalidated.
6. Filtered results follow the existing convention: `@filtered = true` (skips pagination), and the "N mods" count reflects the filtered size.

## Design

- **`app/models/mod.rb`** — `has_download_type?(type)`:
  - `"pak"` → `pak?`; `"zip"` → `zip?`; `"exmod"` → `exmod? || exmodz?`; anything else → `true`.
  - Accepts String or Symbol (normalize with `to_s.downcase`).
- **`app/controllers/mods_controller.rb`** — private `filter_by_type`, called from `index` immediately after `filter_by_query`:
  - `return if params[:type].blank? || !%w[pak zip exmod].include?(params[:type])` (whitelist; `all` and junk both fall through as no-ops)
  - `@mods = @mods.select { |mod| mod.has_download_type?(params[:type]) }`
  - `@filtered = true`
- **`app/views/mods/index.html.erb`** — inside the existing `form_with` (after the query text_field):
  - `form.select :type, [["ALL", "all"], ["PAK", "pak"], ["ZIP", "zip"], ["EXMOD(z)", "exmod"]], {selected: params[:type] || "all"}, data: {action: "change->mods#submit"}, class: <same classes as the author select>`

No JS changes (reuses `mods#submit`), no route changes, no new dependencies.

## Testing (test-first)

- Model spec: `has_download_type?` — pak/zip mappings, `exmod` matching exmod-only AND exmodz-only mods, unknown type → true, symbol input.
- Request specs (`spec/requests/`): `GET /mods?type=pak` shows only pak mods; `type=exmod` shows exmod and exmodz mods; `type=all` and `type=garbage` show everything; `query` + `type` combined narrows by both.
- View spec: select renders with the four options, ALL selected by default, `params[:type]` persisted as selection.

## Out of Scope

- Multi-select / checkbox combinations (revisit only if real need emerges; server can later accept comma-separated values without breaking URLs).
- Changes to pagination behavior for filtered results (existing convention kept).

## Amendment (2026-08-01, user request mid-implementation)

7. **Active filter overrides the listing's download button type.** When `params[:type]` is an active filter (`pak`/`zip`/`exmod`), each listed mod's download button offers that format instead of `preferred_type`:
   - `pak` → `:pak`; `zip` → `:zip`; `exmod` → `:exmodz` if the mod has one, else `:exmod` (reuse the existing `Mod#exmod_type` logic).
   - Label and color follow the resolved type via the existing `download_button_classes` helper — no new styling.
   - Safety: if the mod somehow lacks the filtered type (cannot happen through the UI), fall back to `preferred_type`.
   - Implementation: `Mod#download_type_for(filter)` (model) + `ModHelper#effective_download_type(mod)` reading `params[:type]` (helper) + `_mod.html.erb` switching from `mod.preferred_type` to `effective_download_type(mod)`.
   - Show page unaffected. ALL / no filter → existing `preferred_type` behavior, unchanged.

8. **Default option label.** The select's first option is labeled `DL Type` (value remains `all`), acting as the control's label the way "Filter By Author" does for the author select. Selecting it still resets to unfiltered. (Amended per user, 2026-08-01.)

# Download Buttons: Labels, Priority, Colors — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Listing download buttons show only the format name with per-format colors; format priority becomes ZIP > PAK > EXMODZ > EXMOD on both listing and show pages.

**Architecture:** Priority lives in `Mod#preferred_type`/`#download_types`; a new `ModHelper#download_button_classes(type)` is the single source of per-format color classes consumed by both `_mod.html.erb` (listing) and `show.html.erb` (detail).

**Tech Stack:** Rails 8.1, RSpec, Tailwind CSS v4 (stock emerald/indigo + custom icarus palette).

**Spec:** docs/superpowers/specs/2026-08-01-download-buttons-design.md

## Global Constraints

- Priority order everywhere: **ZIP > PAK > EXMODZ > EXMOD** (exact).
- Colors (exact classes): PAK `bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-400`; EXMODZ and EXMOD `bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400`; ZIP `bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500`; unknown types fall back to the icarus classes (no raise).
- Listing button text is ONLY the upcased type (`ZIP`/`PAK`/`EXMODZ`/`EXMOD`); show page keeps `DOWNLOAD <TYPE>`.
- Note: the spec says "ModsHelper" but the codebase's existing helper is `ModHelper` (`app/helpers/mod_helper.rb`) — use `ModHelper` (spec-name deviation approved by controller).
- Ruby style: 2-space indent, double quotes (per .rubocop.yml), frozen_string_literal comment present in helper files.
- Full suite (`bin/rspec`) green + `bundle exec rubocop --parallel` clean before each commit.

---

### Task 1: Mod model — new format priority

**Files:**
- Modify: `app/models/mod.rb:67-81` (`preferred_type`, `download_types`, comments)
- Test: `spec/models/mod_spec.rb` (existing `#preferred_type` block ~line 229, `#download_types` coverage)

**Interfaces:**
- Produces: `Mod#preferred_type` → one of `:zip, :pak, :exmodz, :exmod, nil` (first present in that order); `Mod#download_types` → Array<Symbol> ordered `%i[zip pak exmodz exmod]` ∩ present types. Task 3's views rely on both.

- [ ] **Step 1: Update/extend the model spec to the new priority (failing first)**

Replace the `#preferred_type` contexts in `spec/models/mod_spec.rb` (keep the existing `context/before/it` style) so they assert:

```ruby
describe "#preferred_type" do
  context "when zip, pak, and exmodz are all present" do
    before do
      mod.files = { pak: Faker::Internet.url, zip: Faker::Internet.url, exmodz: Faker::Internet.url }
    end

    it "prefers zip" do
      expect(mod.preferred_type).to eq(:zip)
    end
  end

  context "when pak and exmodz are present" do
    before { mod.files = { exmodz: Faker::Internet.url, pak: Faker::Internet.url } }

    it "prefers pak" do
      expect(mod.preferred_type).to eq(:pak)
    end
  end

  context "when exmodz and exmod are present" do
    before { mod.files = { exmod: Faker::Internet.url, exmodz: Faker::Internet.url } }

    it "prefers exmodz" do
      expect(mod.preferred_type).to eq(:exmodz)
    end
  end

  context "when only given an exmod object" do
    before { mod.files = { exmod: Faker::Internet.url } }

    it "returns exmod" do
      expect(mod.preferred_type).to eq(:exmod)
    end
  end

  context "when there are no files" do
    before { mod.files = {} }

    it "returns nil" do
      expect(mod.preferred_type).to be_nil
    end
  end
end
```

Also add, next to the existing `#file_types` describe block:

```ruby
describe "#download_types" do
  context "when files are present in arbitrary order" do
    before do
      mod.files = { exmod: Faker::Internet.url, pak: Faker::Internet.url, zip: Faker::Internet.url }
    end

    it "returns downloadable types in priority order" do
      expect(mod.download_types).to eq(%i[zip pak exmod])
    end
  end
end
```

- [ ] **Step 2: Run to verify the new expectations fail**

Run: `bin/rspec spec/models/mod_spec.rb -e preferred_type -e download_types`
Expected: FAIL — pak+exmodz case returns `:pak`? no: current code returns `:pak` there (passes); the zip-over-pak case fails (`:pak` returned, `:zip` expected), and download_types ordering fails (`%i[pak zip exmod]` vs `%i[zip pak exmod]`). At least one failure per changed behavior confirms the tests bite.

- [ ] **Step 3: Implement the new order in `app/models/mod.rb`**

```ruby
# Determines which file type is downloaded from the index page
# Priority: zip > pak > exmodz > exmod
def preferred_type
  return :zip if zip?
  return :pak if pak?
  return :exmodz if exmodz?
  return :exmod if exmod?

  nil
end

# Determines which file types can be downloaded from the show page,
# rendered in the same priority order as preferred_type
def download_types
  %i[zip pak exmodz exmod] & file_types.map(&:to_sym)
end
```

(Note the operand swap in `download_types`: Ruby's `Array#&` preserves the RECEIVER's order, so the priority list must be the receiver.)

- [ ] **Step 4: Run model spec — all green**

Run: `bin/rspec spec/models/mod_spec.rb`
Expected: PASS (all examples)

- [ ] **Step 5: Commit**

```bash
git add app/models/mod.rb spec/models/mod_spec.rb
git commit -m "Change download format priority to ZIP > PAK > EXMODZ > EXMOD"
```

---

### Task 2: ModHelper#download_button_classes

**Files:**
- Modify: `app/helpers/mod_helper.rb`
- Test: `spec/helpers/mod_helper_spec.rb`

**Interfaces:**
- Produces: `download_button_classes(type)` → String of Tailwind color classes; accepts Symbol or String, case-insensitive. Task 3's views call it.

- [ ] **Step 1: Write the failing helper spec**

Append inside the existing `RSpec.describe ModHelper` block:

```ruby
describe "#download_button_classes" do
  it "returns emerald classes for pak" do
    expect(helper.download_button_classes(:pak))
      .to eq("bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-400")
  end

  it "returns indigo classes for zip" do
    expect(helper.download_button_classes(:zip))
      .to eq("bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500")
  end

  it "returns icarus classes for exmodz" do
    expect(helper.download_button_classes(:exmodz))
      .to eq("bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400")
  end

  it "returns icarus classes for exmod" do
    expect(helper.download_button_classes(:exmod))
      .to eq("bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400")
  end

  it "falls back to icarus classes for unknown types" do
    expect(helper.download_button_classes(:tarball))
      .to eq("bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400")
  end

  it "accepts string types" do
    expect(helper.download_button_classes("PAK"))
      .to eq("bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-400")
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `bin/rspec spec/helpers/mod_helper_spec.rb`
Expected: FAIL with `undefined method 'download_button_classes'`

- [ ] **Step 3: Implement in `app/helpers/mod_helper.rb`**

Add inside the module:

```ruby
DOWNLOAD_BUTTON_CLASSES = {
  pak: "bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-400",
  zip: "bg-indigo-600 hover:bg-indigo-700 focus:ring-indigo-500",
}.freeze

ICARUS_BUTTON_CLASSES = "bg-icarus-500 hover:bg-icarus-600 focus:ring-icarus-400"

# Per-format color classes for download buttons (listing + show page).
# Exmod-family and unknown types use the default icarus gold.
def download_button_classes(type)
  DOWNLOAD_BUTTON_CLASSES.fetch(type.to_s.downcase.to_sym, ICARUS_BUTTON_CLASSES)
end
```

- [ ] **Step 4: Run helper spec — green**

Run: `bin/rspec spec/helpers/mod_helper_spec.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/helpers/mod_helper.rb spec/helpers/mod_helper_spec.rb
git commit -m "Add ModHelper#download_button_classes for per-format button colors"
```

---

### Task 3: Views — listing label + colors on both pages

**Files:**
- Modify: `app/views/mods/_mod.html.erb:12-13`
- Modify: `app/views/mods/show.html.erb:14`
- Test: `spec/views/mods/_mod.html.erb_spec.rb:41-44, 106-110`

**Interfaces:**
- Consumes: `download_button_classes(type)` from Task 2; `mod.preferred_type`/`download_types` order from Task 1.

- [ ] **Step 1: Update the listing view spec (failing first)**

In `spec/views/mods/_mod.html.erb_spec.rb`, replace the "renders download button" example (~line 41):

```ruby
it "renders download button labeled with only the format name" do
  render partial: "mods/mod", locals: { mod: mod }
  expect(rendered).to include(">PAK<")
  expect(rendered).not_to include("Download")
  expect(rendered).to include("bg-emerald-600")
end
```

and the "does not show download button" example (~line 106; that context's mod has `files: { exmodz: ... }` but a name of "No Files" — it actually renders an EXMODZ button, so assert on colors/labels instead):

```ruby
it "shows the exmodz button in icarus gold" do
  render partial: "mods/mod", locals: { mod: mod_no_files }
  expect(rendered).to include(">EXMODZ<")
  expect(rendered).to include("bg-icarus-500")
  expect(rendered).not_to include("Download")
end
```

- [ ] **Step 2: Run to verify failures**

Run: `bin/rspec spec/views/mods/_mod.html.erb_spec.rb`
Expected: FAIL (rendered output still contains "Download " and no emerald class)

- [ ] **Step 3: Update `app/views/mods/_mod.html.erb`**

Replace the button (lines 7-14) so the class list uses the helper and the label drops the prefix:

```erb
<button
  data-action="mods#download"
  data-mods-url-param="<%= raw_url(mod.get_url(type)) %>"
  data-mods-file-name-param="<%= mod.get_name(type) %>"
  type="button"
  class="z-10 inline-flex items-center px-2 py-1 sm:px-3 sm:py-1.5 text-xs font-medium text-white rounded-md shadow-xs focus:outline-hidden focus:ring-2 focus:ring-offset-2 <%= download_button_classes(type) %>">
  <%= type.to_s.upcase %>
</button>
```

(Structural classes stay inline; only `bg-*`/`hover:bg-*`/`focus:ring-<color>` move to the helper. Note `focus:ring-2` is structural and stays.)

- [ ] **Step 4: Update `app/views/mods/show.html.erb`**

Replace the button's class attribute (line 14), swapping hardcoded indigo for the helper:

```erb
class="inline-flex items-center px-4 py-2 ml-3 text-sm font-medium text-white border border-transparent rounded-md shadow-xs focus:outline-hidden focus:ring-2 focus:ring-offset-2 <%= download_button_classes(type) %>">
```

Label on the show page stays `DOWNLOAD <%= type.to_s.upcase %>`.

- [ ] **Step 5: Full verification**

Run: `bin/rspec`
Expected: all examples pass (269 + new ones). If any other spec asserts the old listing text, update it to the new label rules (listing: bare format name; show: `DOWNLOAD <TYPE>` — `spec/requests/tools_filtering_spec.rb:31` and `spec/views/tools/index.html.erb_spec.rb` reference the TOOLS pages, which are untouched; leave them alone).

Run: `bundle exec rubocop --parallel`
Expected: no offenses

Run: `bin/rails tailwindcss:build`
Expected: succeeds; `grep -c 'bg-emerald-600' app/assets/builds/tailwind.css` ≥ 1 (emerald utilities compiled in).

- [ ] **Step 6: Commit**

```bash
git add app/views/mods/_mod.html.erb app/views/mods/show.html.erb spec/views/mods/_mod.html.erb_spec.rb
git commit -m "Show format-only download labels with per-format colors"
```

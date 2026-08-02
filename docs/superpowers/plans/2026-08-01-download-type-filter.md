# Download-Type Filter Select — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `type` selectbox (ALL/PAK/ZIP/EXMOD(z), default ALL) in the mods search bar that filters the listing by download format, composing with the text query.

**Architecture:** Format knowledge goes in `Mod#has_download_type?`; `ModsController#filter_by_type` whitelists `params[:type]` and filters after the query filter; the view adds a `form.select` inside the existing search `form_with`, reusing the Stimulus `mods#submit` action. No JS/route/dependency changes.

**Tech Stack:** Rails 8.1, RSpec (request specs stub `Mod.all` with FactoryBot mods), Tailwind CSS v4.

**Spec:** docs/superpowers/specs/2026-08-01-download-type-filter-design.md

## Global Constraints

- Select options exactly, in order: `["ALL", "all"], ["PAK", "pak"], ["ZIP", "zip"], ["EXMOD(z)", "exmod"]`; default selection `all`; selection persists from `params[:type]`.
- `exmod` matches mods with `exmod` OR `exmodz` files. Unknown/absent/`all` types filter nothing.
- Controller whitelist: only `%w[pak zip exmod]` triggers filtering; `@filtered = true` when it does.
- Ruby style: 2-space, double quotes, rubocop clean (`bundle exec rubocop --parallel`). Full `bin/rspec` green before each commit (suite currently 278 examples).
- Request specs stub `allow(Mod).to receive(:all).and_return([...])` with `build(:mod, files: {...})`, mirroring spec/requests/mods_show_spec.rb.

---

### Task 1: Mod#has_download_type?

**Files:**
- Modify: `app/models/mod.rb` (after `exmodz?`, ~line 66)
- Test: `spec/models/mod_spec.rb` (new describe block near `#preferred_type`)

**Interfaces:**
- Produces: `Mod#has_download_type?(type)` → Boolean; accepts String/Symbol case-insensitively; `"pak"`→`pak?`, `"zip"`→`zip?`, `"exmod"`→`exmod? || exmodz?`, anything else → `true`. Task 2's controller calls it.

- [ ] **Step 1: Write the failing spec**

Add to `spec/models/mod_spec.rb` (alongside the other file-type describes, matching their `context/before/it` style):

```ruby
describe "#has_download_type?" do
  context "with a pak file" do
    before { mod.files = { pak: Faker::Internet.url } }

    it "matches pak" do
      expect(mod.has_download_type?("pak")).to be(true)
    end

    it "does not match zip" do
      expect(mod.has_download_type?("zip")).to be(false)
    end

    it "does not match exmod" do
      expect(mod.has_download_type?("exmod")).to be(false)
    end
  end

  context "with a zip file" do
    before { mod.files = { zip: Faker::Internet.url } }

    it "matches zip" do
      expect(mod.has_download_type?("zip")).to be(true)
    end
  end

  context "with only an exmod file" do
    before { mod.files = { exmod: Faker::Internet.url } }

    it "matches exmod" do
      expect(mod.has_download_type?("exmod")).to be(true)
    end
  end

  context "with only an exmodz file" do
    before { mod.files = { exmodz: Faker::Internet.url } }

    it "matches exmod" do
      expect(mod.has_download_type?("exmod")).to be(true)
    end
  end

  context "with any files" do
    before { mod.files = { pak: Faker::Internet.url } }

    it "matches unknown types" do
      expect(mod.has_download_type?("garbage")).to be(true)
    end

    it "accepts symbols and mixed case" do
      expect(mod.has_download_type?(:PAK)).to be(true)
    end
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/rspec spec/models/mod_spec.rb -e has_download_type`
Expected: FAIL with `NoMethodError: undefined method 'has_download_type?'`

- [ ] **Step 3: Implement in `app/models/mod.rb`** (directly after `exmodz?`)

```ruby
# Whether this mod offers the given download format.
# "exmod" covers both exmod and exmodz; unknown types match everything (ALL).
def has_download_type?(type)
  case type.to_s.downcase
  when "pak" then pak?
  when "zip" then zip?
  when "exmod" then exmod? || exmodz?
  else true
  end
end
```

- [ ] **Step 4: Run model spec — green**

Run: `bin/rspec spec/models/mod_spec.rb`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/models/mod.rb spec/models/mod_spec.rb
git commit -m "Add Mod#has_download_type? for format filtering"
```

---

### Task 2: Controller filter + request specs

**Files:**
- Modify: `app/controllers/mods_controller.rb` (index action ~line 10-20; new private method after `filter_by_query` ~line 57)
- Test: Create `spec/requests/mods_type_filter_spec.rb`

**Interfaces:**
- Consumes: `Mod#has_download_type?` from Task 1.
- Produces: `GET /mods?type=<pak|zip|exmod>` filters the listing; composes with `query`. Task 3's select submits this param.

- [ ] **Step 1: Write the failing request spec**

Create `spec/requests/mods_type_filter_spec.rb`:

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mods Type Filtering", type: :request do
  let(:pak_mod) { build(:mod, name: "Pak Only Mod", author: "Author One", files: { pak: "https://example.com/mod.pak" }) }
  let(:zip_mod) { build(:mod, name: "Zip Only Mod", author: "Author Two", files: { zip: "https://example.com/mod.zip" }) }
  let(:exmod_mod) { build(:mod, name: "Exmod Only Mod", author: "Author Three", files: { exmod: "https://example.com/mod.exmod" }) }
  let(:exmodz_mod) { build(:mod, name: "Exmodz Only Mod", author: "Author Four", files: { exmodz: "https://example.com/mod.exmodz" }) }

  before do
    allow(Mod).to receive(:all).and_return([pak_mod, zip_mod, exmod_mod, exmodz_mod])
  end

  describe "GET /mods?type=pak" do
    it "shows only mods with pak files" do
      get mods_path(type: "pak")

      expect(response.body).to include("Pak Only Mod")
      expect(response.body).not_to include("Zip Only Mod")
      expect(response.body).not_to include("Exmod Only Mod")
      expect(response.body).not_to include("Exmodz Only Mod")
    end
  end

  describe "GET /mods?type=zip" do
    it "shows only mods with zip files" do
      get mods_path(type: "zip")

      expect(response.body).to include("Zip Only Mod")
      expect(response.body).not_to include("Pak Only Mod")
    end
  end

  describe "GET /mods?type=exmod" do
    it "shows mods with exmod or exmodz files" do
      get mods_path(type: "exmod")

      expect(response.body).to include("Exmod Only Mod")
      expect(response.body).to include("Exmodz Only Mod")
      expect(response.body).not_to include("Pak Only Mod")
      expect(response.body).not_to include("Zip Only Mod")
    end
  end

  describe "GET /mods?type=all" do
    it "shows all mods" do
      get mods_path(type: "all")

      expect(response.body).to include("Pak Only Mod")
      expect(response.body).to include("Zip Only Mod")
      expect(response.body).to include("Exmod Only Mod")
      expect(response.body).to include("Exmodz Only Mod")
    end
  end

  describe "GET /mods?type=garbage" do
    it "shows all mods" do
      get mods_path(type: "garbage")

      expect(response.body).to include("Pak Only Mod")
      expect(response.body).to include("Zip Only Mod")
    end
  end

  describe "GET /mods with query and type combined" do
    it "applies both filters" do
      get mods_path(query: "Only Mod", type: "pak")

      expect(response.body).to include("Pak Only Mod")
      expect(response.body).not_to include("Zip Only Mod")
    end

    it "returns nothing when query matches but type does not" do
      get mods_path(query: "Zip Only", type: "pak")

      expect(response.body).not_to include("Zip Only Mod")
    end
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/rspec spec/requests/mods_type_filter_spec.rb`
Expected: FAIL — `type=pak` still shows all four mods (no filter yet). (`type=all`/`garbage` examples pass — that's expected; the filtering examples must fail.)

- [ ] **Step 3: Implement in `app/controllers/mods_controller.rb`**

In `index`, add `filter_by_type` immediately after `filter_by_query`:

```ruby
filter_by_query
filter_by_type
```

Add the private method directly after `filter_by_query`'s definition:

```ruby
FILTERABLE_TYPES = %w[pak zip exmod].freeze

def filter_by_type
  return unless FILTERABLE_TYPES.include?(params[:type])

  @mods = @mods.select { |mod| mod.has_download_type?(params[:type]) }
  @filtered = true
end
```

(Place `FILTERABLE_TYPES` with the class's constants if it has a constants section; otherwise directly above the method is fine.)

- [ ] **Step 4: Run request spec + full suite — green**

Run: `bin/rspec spec/requests/mods_type_filter_spec.rb` then `bin/rspec`
Expected: PASS (285 examples total: 278 + 7 from Task 1... run the numbers from the actual output; all must pass). Run `bundle exec rubocop --parallel` — no offenses.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/mods_controller.rb spec/requests/mods_type_filter_spec.rb
git commit -m "Filter mods listing by download type param"
```

---

### Task 3: Search-bar select

**Files:**
- Modify: `app/views/mods/index.html.erb` (inside the `form_with` block, after the query `text_field`, ~line 26-28)
- Test: `spec/views/mods/index.html.erb_spec.rb`

**Interfaces:**
- Consumes: `GET` param contract from Task 2 (`type` ∈ pak/zip/exmod/all); existing Stimulus `mods#submit` action (app/javascript/controllers/mods_controller.js, already present — no JS changes).

- [ ] **Step 1: Write the failing view spec**

Add to `spec/views/mods/index.html.erb_spec.rb` (match the file's existing setup — read it first; it already assigns whatever `@mods`/`@authors` the template needs). Use plain string assertions consistent with the rest of the file:

```ruby
describe "download type filter" do
  it "renders the type select with all options" do
    render

    expect(rendered).to include('name="type"')
    expect(rendered).to include(">ALL<")
    expect(rendered).to include(">PAK<")
    expect(rendered).to include(">ZIP<")
    expect(rendered).to include(">EXMOD(z)<")
  end

  it "marks the current param value as selected" do
    controller.params[:type] = "zip"
    render

    expect(rendered).to match(/<option selected="selected" value="zip">ZIP<\/option>/)
  end
end
```

(If `controller.params[:type] =` doesn't work in a view spec, use `controller.request.params[:type] = "zip"` or stub `view` params per the file's existing conventions; adapt and note the deviation in the report.)

- [ ] **Step 2: Run to verify failure**

Run: `bin/rspec spec/views/mods/index.html.erb_spec.rb`
Expected: FAIL — no `name="type"` select rendered yet.

- [ ] **Step 3: Implement in `app/views/mods/index.html.erb`**

Inside the `form_with` block, after the `form.text_field :query` line, add:

```erb
<%= form.select :type,
    [["ALL", "all"], ["PAK", "pak"], ["ZIP", "zip"], ["EXMOD(z)", "exmod"]],
    {selected: params[:type].presence_in(%w[pak zip exmod]) || "all"},
    data: {action: "change->mods#submit"},
    class: "px-3 py-2 text-sm border rounded-lg border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 focus:ring-2 focus:ring-icarus-500 focus:border-icarus-500 focus:outline-hidden" %>
```

(`presence_in` keeps junk params from producing a select with no matching option. The class string is copied from the author select in the same file — keep them identical.)

- [ ] **Step 4: Run view spec + full suite — green**

Run: `bin/rspec spec/views/mods/index.html.erb_spec.rb` then full `bin/rspec` and `bundle exec rubocop --parallel`
Expected: all green, no offenses. Then `bin/rails tailwindcss:build` (no new classes expected — all copied from the author select — but confirm build succeeds).

- [ ] **Step 5: Commit**

```bash
git add app/views/mods/index.html.erb spec/views/mods/index.html.erb_spec.rb
git commit -m "Add download-type filter select to mods search bar"
```

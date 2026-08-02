# Sortable Columns + Updated Column — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clickable sort headers (Name/Download/Author/Updated) on the mods listing with a new Updated column; default order becomes newest-updated-first; sorting composes with query/type filters and pagination.

**Architecture:** `Mod.sort_mods` owns sort logic behind the (previously vestigial) `Mod::SORTKEYS` whitelist; `ModsController#apply_sort` normalizes params and exposes `@sort`/`@dir`; `ModHelper#sort_link` builds param-preserving header links with ▲/▼ indicators; views swap header text for links and add the Updated column.

**Tech Stack:** Rails 8.1, RSpec, Tailwind v4, Turbo frames (existing `mods` frame).

**Spec:** docs/superpowers/specs/2026-08-01-column-sorting-design.md

## Global Constraints

- Whitelists: `sort` ∈ `Mod::SORTKEYS = %w[updated name download author]`; `dir` ∈ `%w[asc desc]`. Invalid sort → `"updated"`; invalid/absent dir → that column's first-click default (`Mod.default_dir_for(key)`: `"desc"` for updated, `"asc"` otherwise).
- Default order (no params): updated DESC; nil `updated_at` sorts LAST in both directions.
- `download` sort key = `download_type_for(type_filter).to_s` with name-asc tiebreak; `name`/`author` case-insensitive (author tiebreaks by name for determinism).
- Sorting never sets `@filtered`; runs after filters, before `@total_mods`/pagination. Sort links drop the `page` param (sorting resets to page 1) but preserve `query` and `type`.
- Evidence: every RED/GREEN run captured via `2>&1 | tee /tmp/claude-1000/-home-dyoung-Projects-web-project-daedalus/11a8b64d-2724-4913-92e5-e968b06467ae/scratchpad/sorting-<task>-<phase>.txt` and pasted COMPLETE (seed lines, summaries) into reports. No paraphrased transcripts.
- Full `bin/rspec` green + `bundle exec rubocop --parallel` clean (no config changes, no suppressions) before each commit. Suite currently 305 examples.
- Ruby style: 2-space, double quotes.

---

### Task 1: Mod.sort_mods + whitelist constants

**Files:**
- Modify: `app/models/mod.rb` (SORTKEYS at ~line 10; new class methods after `expire_cache`)
- Test: `spec/models/mod_spec.rb` (SORTKEYS assertion at ~line 50; new describe)

**Interfaces:**
- Produces: `Mod::SORTKEYS` (`%w[updated name download author]`), `Mod.default_dir_for(key)` → `"asc"|"desc"`, `Mod.sort_mods(mods, key:, dir:, type_filter: nil)` → new Array. Tasks 2-3 consume all three.

- [ ] **Step 1: Update/extend the model spec (failing first)**

Change the SORTKEYS assertion:

```ruby
describe "::SORTKEYS" do
  it "lists the sortable listing columns in default-priority order" do
    expect(described_class::SORTKEYS).to eq(%w[updated name download author])
  end
end
```

Add (near the other class-level describes):

```ruby
describe ".default_dir_for" do
  it "is desc for updated and asc otherwise" do
    expect(described_class.default_dir_for("updated")).to eq("desc")
    expect(described_class.default_dir_for("name")).to eq("asc")
    expect(described_class.default_dir_for("download")).to eq("asc")
    expect(described_class.default_dir_for("author")).to eq("asc")
  end
end

describe ".sort_mods" do
  let(:old_mod) do
    build(:mod, name: "Alpha", author: "zed", files: { zip: Faker::Internet.url }, updated_at: 3.days.ago)
  end
  let(:new_mod) do
    build(:mod, name: "beta", author: "Ann", files: { pak: Faker::Internet.url }, updated_at: 1.hour.ago)
  end
  let(:undated_mod) do
    build(:mod, name: "Gamma", author: "mid", files: { exmodz: Faker::Internet.url }, updated_at: nil)
  end
  let(:mods) { [old_mod, new_mod, undated_mod] }

  it "sorts by updated desc with nil updated_at last" do
    expect(described_class.sort_mods(mods, key: "updated", dir: "desc")).to eq([new_mod, old_mod, undated_mod])
  end

  it "sorts by updated asc with nil updated_at still last" do
    expect(described_class.sort_mods(mods, key: "updated", dir: "asc")).to eq([old_mod, new_mod, undated_mod])
  end

  it "sorts by name case-insensitively" do
    expect(described_class.sort_mods(mods, key: "name", dir: "asc")).to eq([old_mod, new_mod, undated_mod])
    expect(described_class.sort_mods(mods, key: "name", dir: "desc")).to eq([undated_mod, new_mod, old_mod])
  end

  it "sorts by author case-insensitively" do
    expect(described_class.sort_mods(mods, key: "author", dir: "asc")).to eq([new_mod, undated_mod, old_mod])
  end

  it "sorts by download label (exmodz < pak < zip) ascending" do
    expect(described_class.sort_mods(mods, key: "download", dir: "asc")).to eq([undated_mod, new_mod, old_mod])
  end

  it "uses the type filter for the download key" do
    both = build(:mod, name: "Both", author: "x", files: { pak: Faker::Internet.url, zip: Faker::Internet.url })
    result = described_class.sort_mods([both, new_mod], key: "download", dir: "asc", type_filter: "zip")
    # under zip filter, Both's effective label is "zip" (> "pak"), so new_mod (pak) comes first
    expect(result).to eq([new_mod, both])
  end

  it "breaks download ties by name ascending" do
    pak_b = build(:mod, name: "Bravo", author: "x", files: { pak: Faker::Internet.url })
    pak_a = build(:mod, name: "alpha2", author: "y", files: { pak: Faker::Internet.url })
    expect(described_class.sort_mods([pak_b, pak_a], key: "download", dir: "asc")).to eq([pak_a, pak_b])
  end

  it "returns the array unchanged for an unknown key" do
    expect(described_class.sort_mods(mods, key: "bogus", dir: "asc")).to eq(mods)
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run (tee per Global Constraints): `bin/rspec spec/models/mod_spec.rb -e SORTKEYS -e default_dir_for -e sort_mods`
Expected: FAIL — SORTKEYS eq mismatch + NoMethodError for the two new class methods.

- [ ] **Step 3: Implement in `app/models/mod.rb`**

Replace the SORTKEYS line and add below `self.expire_cache`:

```ruby
SORTKEYS = %w[updated name download author].freeze
SORT_DEFAULT_DIRS = { "updated" => "desc" }.freeze

def self.default_dir_for(key)
  SORT_DEFAULT_DIRS.fetch(key, "asc")
end

# Sorts a listing of mods for the index table. `key` must be in SORTKEYS
# (unknown keys return the input untouched). Mods without updated_at sort
# last regardless of direction; download sorts by the label the button
# shows under the active type filter.
def self.sort_mods(mods, key:, dir:, type_filter: nil)
  return mods unless SORTKEYS.include?(key)

  if key == "updated"
    dated, undated = mods.partition { |mod| mod.updated_at.present? }
    sorted = dated.sort_by(&:updated_at)
    sorted.reverse! if dir == "desc"
    sorted + undated
  else
    sorted = mods.sort_by { |mod| sort_key_for(mod, key, type_filter) }
    dir == "desc" ? sorted.reverse : sorted
  end
end

def self.sort_key_for(mod, key, type_filter)
  case key
  when "name" then [mod.name.to_s.downcase]
  when "author" then [mod.author.to_s.downcase, mod.name.to_s.downcase]
  when "download" then [mod.download_type_for(type_filter).to_s, mod.name.to_s.downcase]
  end
end
private_class_method :sort_key_for
```

- [ ] **Step 4: Model spec green**

Run: `bin/rspec spec/models/mod_spec.rb` (tee) → PASS. `bundle exec rubocop --parallel` → clean.

- [ ] **Step 5: Commit**

```bash
git add app/models/mod.rb spec/models/mod_spec.rb
git commit -m "Add Mod.sort_mods with updated/name/download/author keys"
```

---

### Task 2: Controller sort step + request specs

**Files:**
- Modify: `app/controllers/mods_controller.rb` (index; new private method after `filter_by_type`)
- Test: Create `spec/requests/mods_sorting_spec.rb`; update any existing specs that assumed name-A→Z default order (run the suite and fix deliberately — list every changed expectation in the report)

**Interfaces:**
- Consumes: `Mod.sort_mods`, `Mod::SORTKEYS`, `Mod.default_dir_for` (Task 1).
- Produces: `@sort`/`@dir` assigns (Tasks 3-4 consume); `GET /mods?sort=<key>&dir=<asc|desc>` contract.

- [ ] **Step 1: Write the failing request spec**

Create `spec/requests/mods_sorting_spec.rb`:

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mods Sorting", type: :request do
  let(:older_mod) do
    build(:mod, name: "Aardvark Mod", author: "Zeb", files: { pak: "https://example.com/a.pak" },
                updated_at: 3.days.ago)
  end
  let(:newer_mod) do
    build(:mod, name: "Zebra Mod", author: "Amy", files: { zip: "https://example.com/z.zip" },
                updated_at: 1.hour.ago)
  end

  before do
    allow(Mod).to receive(:all).and_return([older_mod, newer_mod])
  end

  def positions(body, *names)
    names.map { |name| body.index(name) }
  end

  describe "default order" do
    it "lists most recently updated first" do
      get mods_path

      zebra, aardvark = positions(response.body, "Zebra Mod", "Aardvark Mod")
      expect(zebra).to be < aardvark
    end
  end

  describe "GET /mods?sort=name" do
    it "sorts by name ascending by default" do
      get mods_path(sort: "name")

      aardvark, zebra = positions(response.body, "Aardvark Mod", "Zebra Mod")
      expect(aardvark).to be < zebra
    end

    it "honors dir=desc" do
      get mods_path(sort: "name", dir: "desc")

      zebra, aardvark = positions(response.body, "Zebra Mod", "Aardvark Mod")
      expect(zebra).to be < aardvark
    end
  end

  describe "invalid params" do
    it "falls back to updated desc for unknown sort" do
      get mods_path(sort: "bogus")

      zebra, aardvark = positions(response.body, "Zebra Mod", "Aardvark Mod")
      expect(zebra).to be < aardvark
    end

    it "falls back to the column default for unknown dir" do
      get mods_path(sort: "name", dir: "sideways")

      aardvark, zebra = positions(response.body, "Aardvark Mod", "Zebra Mod")
      expect(aardvark).to be < zebra
    end
  end

  describe "composition with filters" do
    it "sorts the type-filtered set" do
      pak_two = build(:mod, name: "Bison Mod", author: "Cal", files: { pak: "https://example.com/b.pak" },
                            updated_at: 2.days.ago)
      allow(Mod).to receive(:all).and_return([older_mod, newer_mod, pak_two])

      get mods_path(type: "pak", sort: "name", dir: "desc")

      expect(response.body).not_to include("Zebra Mod")
      bison, aardvark = positions(response.body, "Bison Mod", "Aardvark Mod")
      expect(bison).to be < aardvark
    end
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run (tee): `bin/rspec spec/requests/mods_sorting_spec.rb`
Expected: FAIL — default order and sort params have no effect yet (fetch_all name order governs). The `sort=name` asc example may pass incidentally (input already name-sorted); the default-order, desc, and fallback-to-updated examples MUST fail.

- [ ] **Step 3: Implement in `app/controllers/mods_controller.rb`**

In `index`, after `filter_by_type` and before `@total_mods = @mods.size`, add `apply_sort`. Add the private method after `filter_by_type`:

```ruby
def apply_sort
  @sort = params[:sort].to_s.presence_in(Mod::SORTKEYS) || "updated"
  @dir = params[:dir].to_s.presence_in(%w[asc desc]) || Mod.default_dir_for(@sort)
  @mods = Mod.sort_mods(@mods, key: @sort, dir: @dir, type_filter: params[:type])
end
```

- [ ] **Step 4: Run request spec, then FULL suite; fix order-dependent fallout deliberately**

Run (tee): `bin/rspec spec/requests/mods_sorting_spec.rb` → PASS.
Run (tee): full `bin/rspec`. The default-order change may break existing expectations that assumed name order (pagination specs, index view/request specs). Fix each one deliberately (usually by setting distinct `updated_at` values in fixtures or asserting presence instead of order) and LIST every touched expectation + rationale in the report. `bundle exec rubocop --parallel` → clean.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/mods_controller.rb spec/requests/mods_sorting_spec.rb <any adjusted spec files>
git commit -m "Sort mods listing via whitelisted sort/dir params, default updated desc"
```

---

### Task 3: ModHelper#sort_link

**Files:**
- Modify: `app/helpers/mod_helper.rb`
- Test: `spec/helpers/mod_helper_spec.rb`

**Interfaces:**
- Consumes: `@sort`/`@dir` assigns (Task 2), `Mod.default_dir_for`.
- Produces: `sort_link(label, key)` → SafeBuffer anchor. Task 4's headers call it.

- [ ] **Step 1: Write the failing helper spec**

Add inside the ModHelper describe (use `assign(:sort, ...)`/`assign(:dir, ...)`; if `assign` doesn't reach helper ivars in this repo's helper specs, use `helper.instance_variable_set` and note it):

```ruby
describe "#sort_link" do
  before do
    allow(helper).to receive(:params).and_return({ query: "ice", type: "pak" }.with_indifferent_access)
    allow(helper.request).to receive(:path).and_return("/mods")
  end

  context "when the column is inactive" do
    before do
      assign(:sort, "updated")
      assign(:dir, "desc")
    end

    it "links with the column's first-click default and no arrow" do
      html = helper.sort_link("Name", "name")

      expect(html).to include("sort=name")
      expect(html).to include("dir=asc")
      expect(html).to include(">Name</a>")
      expect(html).not_to include("▲")
      expect(html).not_to include("▼")
    end

    it "preserves query and type params and drops page" do
      allow(helper).to receive(:params)
        .and_return({ query: "ice", type: "pak", page: "3" }.with_indifferent_access)

      html = helper.sort_link("Name", "name")

      expect(html).to include("query=ice")
      expect(html).to include("type=pak")
      expect(html).not_to include("page=")
    end
  end

  context "when the column is active" do
    before do
      assign(:sort, "name")
      assign(:dir, "asc")
    end

    it "toggles direction and shows the ascending arrow" do
      html = helper.sort_link("Name", "name")

      expect(html).to include("dir=desc")
      expect(html).to include("▲")
    end
  end

  context "when the column is active descending" do
    before do
      assign(:sort, "updated")
      assign(:dir, "desc")
    end

    it "shows the descending arrow and toggles to asc" do
      html = helper.sort_link("Updated", "updated")

      expect(html).to include("dir=asc")
      expect(html).to include("▼")
    end
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run (tee): `bin/rspec spec/helpers/mod_helper_spec.rb` → FAIL (`undefined method 'sort_link'`).

- [ ] **Step 3: Implement in `app/helpers/mod_helper.rb`**

```ruby
# Header link for a sortable listing column: preserves the active
# query/type filters, resets pagination, toggles direction on the
# active column, and marks it with an arrow.
def sort_link(label, key)
  active = @sort == key
  next_dir = if active
    @dir == "asc" ? "desc" : "asc"
  else
    Mod.default_dir_for(key)
  end
  arrow = active ? (@dir == "asc" ? " ▲" : " ▼") : ""
  link_params = { query: params[:query], type: params[:type], sort: key, dir: next_dir }.compact_blank

  link_to "#{label}#{arrow}", "#{request.path}?#{link_params.to_query}",
          data: { turbo_action: "advance" }, class: "no-underline text-icarus-500"
end
```

- [ ] **Step 4: Helper spec green**

Run (tee): `bin/rspec spec/helpers/mod_helper_spec.rb` → PASS. Full `bin/rspec` → PASS. `bundle exec rubocop --parallel` → clean (if a metrics cop objects to method length, extract the `next_dir`/`arrow` computation into a small private helper method — no suppressions).

- [ ] **Step 5: Commit**

```bash
git add app/helpers/mod_helper.rb spec/helpers/mod_helper_spec.rb
git commit -m "Add sort_link helper for sortable column headers"
```

---

### Task 4: Views — sortable headers + Updated column

**Files:**
- Modify: `app/views/mods/_mods.html.erb` (thead + no-match colspan)
- Modify: `app/views/mods/_mod.html.erb` (new td)
- Test: `spec/views/mods/_mods.html.erb_spec.rb`, `spec/views/mods/_mod.html.erb_spec.rb`

**Interfaces:**
- Consumes: `sort_link` (Task 3), `@sort`/`@dir` (Task 2), `mod.updated_at`.

- [ ] **Step 1: Write the failing view specs**

In `spec/views/mods/_mods.html.erb_spec.rb` (read its existing setup first; it must now assign `@sort`/`@dir` — add `assign(:sort, "updated")` / `assign(:dir, "desc")` to the outer before block if the render blows up on nil):

```ruby
describe "sortable headers" do
  it "renders sort links for Name, Download, Author, and Updated" do
    render partial: "mods/mods", locals: { mods: mods }

    expect(rendered).to include("sort=name")
    expect(rendered).to include("sort=download")
    expect(rendered).to include("sort=author")
    expect(rendered).to include("sort=updated")
  end

  it "marks the active column with an arrow" do
    render partial: "mods/mods", locals: { mods: mods }

    expect(rendered).to include("Updated ▼")
  end

  it "renders an Updated header and plain Version header" do
    render partial: "mods/mods", locals: { mods: mods }

    expect(rendered).to include("Updated")
    expect(rendered).not_to include("sort=version")
  end
end
```

In `spec/views/mods/_mod.html.erb_spec.rb`:

```ruby
describe "updated column" do
  it "shows relative time when updated_at is present" do
    mod.updated_at = 3.days.ago
    render partial: "mods/mod", locals: { mod: mod }

    expect(rendered).to include("3 days ago")
  end

  it "shows an em-dash when updated_at is missing" do
    mod.updated_at = nil
    render partial: "mods/mod", locals: { mod: mod }

    expect(rendered).to include("&mdash;")
  end
end
```

(Adapt `mod` to the file's existing let/build conventions; the factory sets `updated_at { Time.now.utc }` so overriding per-example is enough.)

- [ ] **Step 2: Run to verify failure**

Run (tee): both view spec files → new examples FAIL (no sort links, no Updated cell).

- [ ] **Step 3: Update `app/views/mods/_mods.html.erb`**

Replace the four sortable `<th>` contents with `sort_link` calls (keep each th's existing classes):

```erb
<th class="p-3 text-left text-sm font-semibold text-icarus-500 sm:w-1/5"><%= sort_link("Name", "name") %></th>
<th class="p-3 text-left text-sm font-semibold text-icarus-500 w-auto sm:w-28"><%= sort_link("Download", "download") %></th>
<th class="hidden p-3 text-left text-sm font-semibold text-icarus-500 sm:table-cell sm:w-1/6"><%= sort_link("Author", "author") %></th>
```

After the Version th, add:

```erb
<th class="hidden p-3 text-right text-sm font-semibold text-icarus-500 md:table-cell w-28"><%= sort_link("Updated", "updated") %></th>
```

Version/Week/Description th text stays plain. Update the no-match row's `colspan="6"` to `colspan="7"`.

- [ ] **Step 4: Update `app/views/mods/_mod.html.erb`**

After the version `<td>`, add:

```erb
<td class="hidden p-3 text-sm text-right md:table-cell text-slate-600 dark:text-slate-400 whitespace-nowrap">
  <% if mod.updated_at.present? %>
    <%= time_ago_in_words(mod.updated_at) %> ago
  <% else %>
    <span class="text-xs text-slate-500">&mdash;</span>
  <% end %>
</td>
```

- [ ] **Step 5: Full verification**

Run (tee): both view spec files → PASS; full `bin/rspec` → PASS (fix any spec that counted columns or asserted the old header text — list them in the report); `bundle exec rubocop --parallel` → clean; `bin/rails tailwindcss:build` → succeeds.

- [ ] **Step 6: Commit**

```bash
git add app/views/mods/_mods.html.erb app/views/mods/_mod.html.erb spec/views/mods/_mods.html.erb_spec.rb spec/views/mods/_mod.html.erb_spec.rb
git commit -m "Add sortable column headers and Updated column to mods listing"
```

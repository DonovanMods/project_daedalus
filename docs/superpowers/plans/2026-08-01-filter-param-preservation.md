# Filter/Sort Param Preservation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every mods-listing control preserves every other control's state (author select carries query/type/sort; form submits carry sort), except Show All which resets everything (pinned).

**Architecture:** Two client-side changes in the existing Stimulus `mods` controller (query-string carry-over in `navigateToAuthor`; submit-time hidden-field sync in `search`/`submit`), hidden `sort`/`dir` fields in the search form, plus server-side pinning specs for the param-composition contract the JS relies on.

**Tech Stack:** Rails 8.1, Stimulus (importmap, no build step), RSpec. NO new dependencies — JS verified by code review + user smoke test per the spec's explicit decision.

**Spec:** docs/superpowers/specs/2026-08-01-filter-param-preservation-design.md

## Global Constraints

- JS: plain Stimulus in `app/javascript/controllers/mods_controller.js`; private method syntax (`#name`) is fine (already an importmap/no-transpile app — verify the file's existing style and match it).
- Blank/absent sort state must NOT produce `sort=&dir=` in URLs: sync logic disables empty hidden fields before submit (disabled fields aren't submitted).
- Show All stays exactly `link_to "Show All", mods_path` — pinned by spec, never "improved".
- Server behavior is already correct; request-spec additions are REGRESSION PINS for the contract (author+type+sort compose) — they are expected to pass immediately. The view-spec additions (hidden fields) are genuine TDD (RED first). State which is which in reports; no fabricated RED for pins.
- Evidence: every run tee'd to /tmp/claude-1000/-home-dyoung-Projects-web-project-daedalus/11a8b64d-2724-4913-92e5-e968b06467ae/scratchpad/preserve-<task>-<phase>.txt, pasted COMPLETE (seeds, summaries).
- Full `bin/rspec` green (331 examples currently) + `bundle exec rubocop --parallel` clean, zero suppressions, before each commit.

---

### Task 1: navigateToAuthor carries the query string + composition pin specs

**Files:**
- Modify: `app/javascript/controllers/mods_controller.js:8-17`
- Test: `spec/requests/mods_sorting_spec.rb` (add a describe)

**Interfaces:**
- Consumes: existing server param handling (`filter_by_author` → `filter_by_query` → `filter_by_type` → `apply_sort`).
- Produces: author navigation URLs of the form `/mods[/author]?query=..&type=..&sort=..&dir=..` (no page).

- [ ] **Step 1: Add the composition pin spec (expected to pass — it pins the contract, state that in the report)**

Add to `spec/requests/mods_sorting_spec.rb`:

```ruby
describe "GET /mods/:author with type and sort combined" do
  let(:author_pak_a) do
    build(:mod, name: "Alpha Pak", author: "Shared Author",
                files: { pak: "https://example.com/a.pak" }, updated_at: 3.days.ago)
  end
  let(:author_pak_b) do
    build(:mod, name: "Beta Pak", author: "Shared Author",
                files: { pak: "https://example.com/b.pak" }, updated_at: 2.days.ago)
  end
  let(:author_zip) do
    build(:mod, name: "Gamma Zip", author: "Shared Author",
                files: { zip: "https://example.com/g.zip" }, updated_at: 1.day.ago)
  end

  before do
    allow(Mod).to receive(:all).and_return([author_pak_a, author_pak_b, author_zip])
  end

  it "applies author, type, and sort together" do
    get mods_author_path(author: author_pak_a.author_slug, type: "pak", sort: "name", dir: "desc")

    expect(response.body).not_to include("Gamma Zip")
    beta, alpha = [response.body.index("Beta Pak"), response.body.index("Alpha Pak")]
    expect(beta).to be < alpha
  end
end
```

Run (tee): `bin/rspec spec/requests/mods_sorting_spec.rb` → expect ALL green including the new pin (if the pin FAILS, stop and report BLOCKED — that would mean the server contract is broken, which contradicts the final reviews).

- [ ] **Step 2: Fix `navigateToAuthor`**

Replace the method body in `app/javascript/controllers/mods_controller.js`:

```javascript
navigateToAuthor(event) {
  const author = event.target.value;
  let modsPath = "/mods";

  if (author) {
    modsPath = `${modsPath}/${author}`;
  }

  const params = new URLSearchParams(window.location.search);
  params.delete("page");
  const queryString = params.toString();

  window.location.href = `${window.location.origin}${modsPath}${queryString ? `?${queryString}` : ""}`;
}
```

- [ ] **Step 3: Verify and commit**

Run (tee): full `bin/rspec` → green (332 expected); `bundle exec rubocop --parallel` → clean (JS files aren't linted by rubocop; this catches ruby-side drift only).

```bash
git add app/javascript/controllers/mods_controller.js spec/requests/mods_sorting_spec.rb
git commit -m "Preserve listing params when navigating by author"
```

---

### Task 2: Search form carries sort state (hidden fields + submit-time sync)

**Files:**
- Modify: `app/views/mods/index.html.erb` (inside the form, after the type select)
- Modify: `app/javascript/controllers/mods_controller.js` (`search`, `submit`, new private method)
- Test: `spec/views/mods/index.html.erb_spec.rb`

**Interfaces:**
- Consumes: server `presence_in` whitelists (blank/absent sort/dir → defaults) — already shipped.
- Produces: form submits that include `sort`/`dir` matching the CURRENT URL (synced at submit time; empty fields disabled so they don't serialize).

- [ ] **Step 1: Write the failing view specs**

Add to `spec/views/mods/index.html.erb_spec.rb` (match the file's `allow(view).to receive(:params)` convention):

```ruby
describe "sort state hidden fields" do
  it "renders hidden sort and dir fields with current values" do
    allow(view).to receive(:params)
      .and_return({ sort: "name", dir: "desc" }.with_indifferent_access)
    render

    expect(rendered).to match(/<input[^>]*type="hidden"[^>]*name="sort"[^>]*value="name"/)
    expect(rendered).to match(/<input[^>]*type="hidden"[^>]*name="dir"[^>]*value="desc"/)
  end

  it "renders the hidden fields empty when no sort is active" do
    render

    expect(rendered).to match(/<input[^>]*type="hidden"[^>]*name="sort"/)
    expect(rendered).not_to include('name="sort" value=')
  end
end

describe "Show All link" do
  it "resets everything: bare mods path with no params" do
    allow(view).to receive(:params)
      .and_return({ query: "ice", type: "pak", sort: "name" }.with_indifferent_access)
    render

    expect(rendered).to match(%r{<a[^>]*href="/mods"[^>]*>Show All</a>})
  end
end
```

(Attribute order in rendered HTML may differ — adjust the regexes to the actual output shape observed in the RED run, keeping the assertions' meaning: hidden field named sort/dir with the right value attribute, and a Show All anchor whose href is exactly "/mods". Note any adjustment in the report.)

Run (tee): `bin/rspec spec/views/mods/index.html.erb_spec.rb` → hidden-field examples FAIL (no such inputs yet); Show All example may pass already (it pins current behavior).

- [ ] **Step 2: Add the hidden fields to the form**

In `app/views/mods/index.html.erb`, inside the `form_with` block after the type select:

```erb
<%= form.hidden_field :sort, value: params[:sort] %>
<%= form.hidden_field :dir, value: params[:dir] %>
```

- [ ] **Step 3: Sync fields at submit time in the Stimulus controller**

In `app/javascript/controllers/mods_controller.js`, update both handlers and add the private helper (match the file's existing style):

```javascript
search(event) {
  clearTimeout(this.timeout)
  this.timeout = setTimeout(() => {
    this.#syncSortFields(event.target.form);
    event.target.form.requestSubmit();
  }, 400)
}

submit(event) {
  this.#syncSortFields(event.target.form);
  event.target.form.requestSubmit();
}

#syncSortFields(form) {
  const params = new URLSearchParams(window.location.search);

  ["sort", "dir"].forEach((name) => {
    const field = form.elements[name];
    if (!field) return;

    const value = params.get(name) || "";
    field.value = value;
    field.disabled = !value;
  });
}
```

(The form renders hidden fields server-side with the page-load values; the sync makes them track the URL after in-frame sort navigation, and disables them when empty so URLs stay clean.)

- [ ] **Step 4: Verify and commit**

Run (tee): `bin/rspec spec/views/mods/index.html.erb_spec.rb` → green; full `bin/rspec` → green; `bundle exec rubocop --parallel` → clean; `bin/rails tailwindcss:build` → succeeds (no new classes expected).

```bash
git add app/views/mods/index.html.erb app/javascript/controllers/mods_controller.js spec/views/mods/index.html.erb_spec.rb
git commit -m "Carry sort state through search form submits"
```

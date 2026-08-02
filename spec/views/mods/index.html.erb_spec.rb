# frozen_string_literal: true

require "rails_helper"

RSpec.describe "mods/index.html.erb", type: :view do
  let(:mod1) { build(:mod, name: "Mod One", author: "Author A") }
  let(:mod2) { build(:mod, name: "Mod Two", author: "Author B") }
  let(:mods) { [mod1, mod2] }
  let(:authors) { ["Author A", "Author B"] }

  before do
    assign(:mods, mods)
    assign(:authors, authors)
    assign(:total_mods, mods.size)
    allow(view).to receive(:params).and_return(ActionController::Parameters.new({}))
  end

  describe "page structure" do
    it "renders the page title" do
      render
      expect(rendered).to include("Icarus Mods")
    end

    it "has a link to mods_path in title" do
      render
      expect(rendered).to include('href="/mods"')
    end
  end

  describe "search functionality" do
    it "renders search form with query input" do
      render
      expect(rendered).to include('placeholder="Search mods..."')
      expect(rendered).to include('name="query"')
    end

    it "has search input with Stimulus action" do
      render
      expect(rendered).to include('data-action="input-&gt;mods#search"')
    end

    it "renders Show All button" do
      render
      expect(rendered).to include("Show All")
    end

    it "form has turbo frame targeting" do
      render
      expect(rendered).to include('data-turbo-frame="mods"')
    end
  end

  describe "author filter dropdown" do
    it "renders collection_select with all unique authors" do
      render
      expect(rendered).to include("Author A")
      expect(rendered).to include("Author B")
    end

    it "includes 'All' blank option" do
      render
      expect(rendered).to include('<option value="">All</option>')
    end

    it "includes Filter By Author prompt" do
      render
      expect(rendered).to include("Filter By Author")
    end

    it "has Stimulus action for navigateToAuthor" do
      render
      expect(rendered).to include('data-action="change-&gt;mods#navigateToAuthor"')
    end

    context "with author param" do
      before do
        allow(view).to receive(:params).and_return(ActionController::Parameters.new(author: "author-a"))
      end

      it "preselects current author" do
        render
        expect(rendered).to include('selected="selected" value="author-a"')
      end
    end
  end

  describe "feedback link" do
    it "displays link to feedback page" do
      render
      expect(rendered).to include("https://feedback.projectdaedalus.app")
    end

    it "mentions upvote page" do
      render
      expect(rendered).to include("Icarus Modding Upvote Page")
    end
  end

  describe "instructions" do
    it "displays instruction to click rows" do
      render
      expect(rendered).to include("Click on any row to view additional mod details")
    end
  end

  describe "mods partial rendering" do
    it "renders _mods partial with mods collection" do
      render
      # The partial will be rendered with the mods
      expect(rendered).to include("Mod One")
      expect(rendered).to include("Mod Two")
    end
  end

  describe "with no mods" do
    before do
      assign(:mods, [])
      assign(:total_mods, 0)
    end

    it "still renders the page structure" do
      render
      expect(rendered).to include("Icarus Mods")
      expect(rendered).to include("Search mods...")
    end
  end

  describe "download type filter" do
    it "renders the type select with all options" do
      render

      expect(rendered).to include('name="type"')
      expect(rendered).to include(">DL Type<")
      expect(rendered).to include(">PAK<")
      expect(rendered).to include(">ZIP<")
      expect(rendered).to include(">EXMOD(z)<")
    end

    it "renders the options in order" do
      render

      expect(rendered.index(">DL Type<")).to be < rendered.index(">PAK<")
      expect(rendered.index(">PAK<")).to be < rendered.index(">ZIP<")
      expect(rendered.index(">ZIP<")).to be < rendered.index(">EXMOD(z)<")
    end

    context "with type param" do
      before do
        allow(view).to receive(:params).and_return(ActionController::Parameters.new(type: "zip"))
      end

      it "marks the current param value as selected" do
        render

        expect(rendered).to include('<option selected="selected" value="zip">ZIP</option>')
      end
    end
  end

  describe "sort state hidden fields" do
    it "renders hidden sort and dir fields with current values" do
      allow(view).to receive(:params)
        .and_return({ sort: "name", dir: "desc" }.with_indifferent_access)
      render

      expect(rendered).to match(/<input[^>]*value="name"[^>]*type="hidden"[^>]*name="sort"/)
      expect(rendered).to match(/<input[^>]*value="desc"[^>]*type="hidden"[^>]*name="dir"/)
    end

    it "renders the hidden fields empty when no sort is active" do
      render

      expect(rendered[/<input[^>]*name="sort"[^>]*>/]).not_to include("value=")
      expect(rendered[/<input[^>]*name="dir"[^>]*>/]).not_to include("value=")
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
end

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
      expect(rendered).to include('placeholder="Start Typing to Search"')
      expect(rendered).to include('name="query"')
    end

    it "has search input with Stimulus action" do
      render
      expect(rendered).to include('data-action="input-&gt;mods#search"')
    end

    it "renders Show All Mods button" do
      render
      expect(rendered).to include("Show All Mods")
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
      expect(rendered).to include("Start Typing to Search")
    end
  end
end

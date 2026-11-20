# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#markdown" do
    context "with basic markdown" do
      it "renders basic markdown to HTML" do
        result = helper.markdown("**bold** and *italic*")
        expect(result).to include("<strong>bold</strong>")
        expect(result).to include("<em>italic</em>")
      end

      it "renders headings" do
        result = helper.markdown("# Heading 1\n## Heading 2")
        expect(result).to include("<h1>Heading 1</h1>")
        expect(result).to include("<h2>Heading 2</h2>")
      end

      it "renders lists" do
        result = helper.markdown("- Item 1\n- Item 2")
        expect(result).to include("<ul>")
        expect(result).to include("<li>Item 1</li>")
      end

      it "renders links" do
        result = helper.markdown("[Link](https://example.com)")
        expect(result).to include('<a href="https://example.com">Link</a>')
      end
    end

    context "with code blocks" do
      it "renders code blocks with CodeRay syntax highlighting" do
        code = "```ruby\ndef hello\n  puts 'world'\nend\n```"
        result = helper.markdown(code)
        expect(result).to include('<div class="CodeRay">')
        expect(result).to include("def")
        expect(result).to include("hello")
      end

      it "renders fenced code blocks with language specification" do
        code = "```javascript\nconst x = 42;\n```"
        result = helper.markdown(code)
        expect(result).to include('<div class="CodeRay">')
      end

      it "renders code blocks without language as plain text" do
        code = "```\nplain text\n```"
        result = helper.markdown(code)
        expect(result).to include('<div class="CodeRay">')
        expect(result).to include("plain text")
      end

      it "escapes HTML entities in code blocks" do
        code = "```html\n<script>alert('xss')</script>\n```"
        result = helper.markdown(code)
        expect(result).to include("&lt;script&gt;")
        expect(result).not_to include("<script>alert")
      end
    end

    context "with tables" do
      let(:table) { "| Tier | HP |\n|------|----|\n| Boss | +75% |" }

      it "renders a table" do
        result = helper.markdown(table)
        expect(result).to include("<table>")
        expect(result).to include("<th>Tier</th>")
        expect(result).to include("<td>+75%</td>")
      end

      it "does not leave the pipe syntax in the output" do
        expect(helper.markdown(table)).not_to include("|")
      end

      it "wraps the table so that a wide one scrolls sideways instead of widening the page" do
        expect(helper.markdown(table)).to include('<div class="table-scroll"><table>')
      end

      it "keeps column alignment" do
        result = helper.markdown("| L | C | R |\n|:--|:-:|--:|\n| a | b | c |")
        expect(result).to include('<th class="text-left">L</th>')
        expect(result).to include('<td class="text-center">b</td>')
        expect(result).to include('<td class="text-right">c</td>')
      end

      it "still removes scripts inside a table cell" do
        result = helper.markdown("| A |\n|---|\n| <script>alert(1)</script> |")
        expect(result).not_to include("<script>")
      end

      # 150 columns by 300 rows is over the bound, yet small enough that a broken bound fails the example
      # instead of exhausting the machine's memory.
      it "renders an oversized table as text rather than as tens of thousands of cells" do
        oversized = "|#{"a|" * 150}\n|#{"-|" * 150}\n#{"|\n" * 300}"

        expect(helper.markdown(oversized)).not_to include("<table>")
      end

      it "applies the bound when lines end in a lone carriage return, which Redcarpet also treats as a line end" do
        oversized = "|#{"a|" * 150}\r|#{"-|" * 150}\r#{"|\r" * 300}"

        expect(helper.markdown(oversized)).not_to include("<table>")
      end

      it "still renders a long table that is within the bound" do
        long = "|#{"a|" * 8}\n|#{"-|" * 8}\n#{"|b|\n" * 300}"

        expect(helper.markdown(long)).to include("<table>")
      end
    end

    context "with non-ASCII text" do
      it "keeps UTF-8 characters intact" do
        result = helper.markdown("50% — permanent · 3× faster")
        expect(result).to include("50% — permanent · 3× faster")
      end
    end

    context "with security features" do
      it "sanitizes malicious HTML/JavaScript" do
        malicious = "<script>alert('XSS')</script>"
        result = helper.markdown(malicious)
        expect(result).not_to include("<script>")
        expect(result).not_to include("</script>")
        # Text content remains after tag stripping, which is safe
      end

      it "prevents XSS attacks through markdown injection" do
        xss_attempt = "[Click me](javascript:alert('XSS'))"
        result = helper.markdown(xss_attempt)
        expect(result).not_to include("javascript:")
      end

      it "removes onclick and other event handlers" do
        malicious = '<img src="x" onclick="alert(1)">'
        result = helper.markdown(malicious)
        expect(result).not_to include("onclick")
        expect(result).not_to include("alert(1)")
      end

      it "sanitizes iframe injections" do
        malicious = '<iframe src="https://evil.com"></iframe>'
        result = helper.markdown(malicious)
        expect(result).not_to include("<iframe")
      end
    end

    context "with markdown options" do
      it "converts autolinks to clickable links" do
        result = helper.markdown("https://example.com")
        expect(result).to include('<a href="https://example.com">https://example.com</a>')
      end

      it "disables intra-emphasis (underscores in words)" do
        result = helper.markdown("foo_bar_baz")
        expect(result).not_to include("<em>bar</em>")
        expect(result).to include("foo_bar_baz")
      end

      it "handles hard wraps in text" do
        result = helper.markdown("Line 1\nLine 2")
        expect(result).to include("<br>")
      end
    end

    context "with edge cases" do
      it "handles nil input gracefully" do
        expect(helper.markdown(nil)).to be_nil
      end

      it "handles empty string input" do
        expect(helper.markdown("")).to be_nil
      end

      it "handles whitespace-only input" do
        expect(helper.markdown("   ")).to be_nil
      end

      it "handles very long text" do
        long_text = "word " * 10_000
        expect { helper.markdown(long_text) }.not_to raise_error
      end

      it "handles special characters" do
        result = helper.markdown("< > & \" '")
        expect(result).to include("&lt;")
        expect(result).to include("&gt;")
        expect(result).to include("&amp;")
      end
    end
  end

  describe "#current_path" do
    it "returns PATH_INFO from request" do
      allow(request).to receive(:env).and_return({ "PATH_INFO" => "/test/path" })
      expect(helper.current_path).to eq("/test/path")
    end

    it "returns correct path for root" do
      allow(request).to receive(:env).and_return({ "PATH_INFO" => "/" })
      expect(helper.current_path).to eq("/")
    end
  end
end

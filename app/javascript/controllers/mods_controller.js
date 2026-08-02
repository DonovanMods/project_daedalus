import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigateTo({ params }) {
    window.location.href = params.path;
  }

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

  download(event) {
    const params = event.params
    const [url, fileName] = [params.url, params.fileName];
    const anchor = document.createElement("a");

    event.preventDefault();
    event.stopImmediatePropagation();

    anchor.href = url;
    anchor.download = fileName;

    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
  }

  search(event) {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      event.target.form.requestSubmit();
    }, 400)
  }

  submit(event) {
    event.target.form.requestSubmit();
  }
}

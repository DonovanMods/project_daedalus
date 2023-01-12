import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigateTo({ params }) {
    window.location.href = params.path;
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
}

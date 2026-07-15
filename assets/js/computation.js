(function () {
  "use strict";

  function element(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  function key() {
    return new URLSearchParams(window.location.search).get("study") || "animated-parametric-model";
  }

  function normalize(value) {
    return String(value || "").trim().toLowerCase();
  }

  function href(study) {
    return `computation.html?study=${encodeURIComponent(study.slug || study.id)}`;
  }

  function renderError(main) {
    main.textContent = "";
    const section = element("section", "computation-detail__error page-width");
    section.append(element("p", "", "COMPUTATIONAL ARCHIVE / INVALID ROUTE"), element("h1", "", "STUDY NOT FOUND"));
    const link = element("a", "", "RETURN TO COMPUTATION");
    link.href = "/#computation";
    section.appendChild(link);
    main.appendChild(section);
  }

  function render(main, studies, study) {
    document.title = `${study.title} — Ahmad Alhadidii`;
    const canonical = document.querySelector('link[rel="canonical"]');
    if (canonical) canonical.href = new URL(href(study), "https://www.ahmadalhadidii.manmatic.institute/").href;
    const header = element("header", "computation-detail__header page-width");
    header.append(
      element("p", "editorial-label", `COMPUTATIONAL STUDY ${study.number}`),
      element("h1", "", study.title),
      element("p", "computation-detail__subtitle", study.subtitle),
      element("p", "computation-detail__statement", study.statement)
    );

    const process = element("section", "computation-detail__process page-width");
    process.appendChild(element("h2", "", "PROCESS SEQUENCE"));
    const sequence = element("ol", "computation-detail__sequence");
    (study.sequence || []).forEach(function (item, index) {
      const row = element("li");
      row.append(element("span", "", String(index + 1).padStart(2, "0")), element("strong", "", item));
      sequence.appendChild(row);
    });
    process.appendChild(sequence);

    const technical = element("section", "computation-detail__technical page-width");
    technical.append(element("h2", "", "TECHNICAL RECORD"));
    const meta = element("dl", "computation-detail__meta");
    [
      ["STATUS", study.status],
      ["EQUATION", study.equation || "NOT PUBLISHED — SOURCE NOT VERIFIED"],
      ["MEDIA", Array.isArray(study.media) && study.media.length ? `${study.media.length} VERIFIED FILES` : "NO VERIFIED FILES AVAILABLE"]
    ].forEach(function (entry) {
      const row = element("div");
      row.append(element("dt", "", entry[0]), element("dd", "", entry[1]));
      meta.appendChild(row);
    });
    technical.appendChild(meta);
    const requirements = element("ul", "computation-detail__requirements");
    (study.sourceRequirements || []).forEach(function (item) { requirements.appendChild(element("li", "", item)); });
    technical.append(element("h3", "", "REQUIRED SOURCE MATERIAL"), requirements);

    const nav = element("nav", "computation-detail__navigation page-width");
    nav.setAttribute("aria-label", "Computational study navigation");
    studies.forEach(function (item) {
      const link = element("a", "", `${item.number} / ${item.title}`);
      link.href = href(item);
      if (item === study) link.setAttribute("aria-current", "page");
      nav.appendChild(link);
    });
    main.replaceChildren(header, process, technical, nav);
  }

  function init() {
    const main = document.getElementById("computation-detail");
    const studies = window.siteContent && Array.isArray(window.siteContent.computations) ? window.siteContent.computations : [];
    const requested = normalize(key());
    const study = studies.find(function (item) { return [item.id, item.slug, item.number].some(function (value) { return normalize(value) === requested; }); });
    if (!main || !study) return main && renderError(main);
    render(main, studies, study);
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init, { once: true });
  else init();
})();

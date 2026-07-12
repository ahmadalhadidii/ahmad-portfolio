(function () {
  "use strict";

  function element(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined && text !== null) node.textContent = text;
    return node;
  }

  function normalize(value) {
    return String(value || "").trim().toLowerCase();
  }

  function hasText(value) {
    return typeof value === "string" && value.trim().length > 0;
  }

  function requestedKey() {
    const params = new URLSearchParams(window.location.search);
    return params.get("visual") || params.get("slug") || params.get("id") || "";
  }

  function findVisual(visuals, key) {
    const normalized = normalize(key);
    if (!normalized) return null;
    return visuals.find(function (visual, index) {
      return [
        visual.slug,
        visual.id,
        visual.index,
        String(index + 1),
        String(index + 1).padStart(2, "0")
      ].map(normalize).includes(normalized);
    }) || null;
  }

  function visualHref(visual) {
    return `visual.html?visual=${encodeURIComponent(visual.slug)}`;
  }

  function safeClass(value, fallback) {
    const normalized = normalize(value);
    return /^[a-z0-9_-]+$/.test(normalized) ? normalized : fallback;
  }

  function setMeta(visual) {
    const title = `${visual.title} — Ahmad Alhadidii`;
    const description = visual.description || "Selected visual narrative by Ahmad Alhadidii.";
    document.title = title;
    const selectors = [
      ['meta[name="description"]', description],
      ['meta[property="og:title"]', title],
      ['meta[property="og:description"]', description],
      ['meta[property="og:image"]', visual.src]
    ];
    selectors.forEach(function (entry) {
      const node = document.querySelector(entry[0]);
      if (node) node.setAttribute("content", entry[1]);
    });
    const canonical = document.querySelector('link[rel="canonical"]');
    if (canonical) canonical.setAttribute("href", visualHref(visual));
    const runningHeader = document.getElementById("running-header-text");
    if (runningHeader) {
      runningHeader.textContent = `VISUAL ${visual.index} / ${visual.title.toUpperCase()} / ${visual.year || "ARCHIVE"}`;
    }
  }

  function metadataRow(label, value) {
    const row = element("div");
    row.append(element("dt", "", label), element("dd", "", value));
    return row;
  }

  function createHeader(visual, total) {
    const header = element("header", "visual-record__header");
    const metadata = element("dl", "visual-record__meta");
    metadata.appendChild(metadataRow("RECORD", `VISUAL ${visual.index} / ${String(total).padStart(2, "0")}`));
    metadata.appendChild(metadataRow("CATEGORY", visual.category || "VISUAL NARRATIVE"));
    metadata.appendChild(metadataRow("YEAR", visual.year || "ARCHIVE"));
    if (hasText(visual.relatedProject || visual.project)) {
      metadata.appendChild(metadataRow("RELATED FIELD", visual.relatedProject || visual.project));
    }
    const title = element("h1", "", visual.title);
    header.append(metadata, title);
    return header;
  }

  function createMedia(visual) {
    const orientation = safeClass(visual.orientation, "landscape");
    const fit = ["contain", "cover"].includes(normalize(visual.fit)) ? normalize(visual.fit) : "contain";
    const figure = element(
      "figure",
      `visual-record__media orientation--${orientation} media--${fit}`
    );
    figure.dataset.orientation = orientation;
    figure.dataset.mediaFit = fit;
    if (visual.width && visual.height) {
      figure.style.setProperty("--media-ratio", `${visual.width} / ${visual.height}`);
    }

    const frame = element("div", "visual-record__image-frame");
    const image = element("img");
    image.src = visual.src;
    if (hasText(visual.srcset)) image.srcset = visual.srcset;
    image.sizes = "(max-width: 700px) calc(100vw - 36px), (max-width: 1100px) 58vw, min(980px, 62vw)";
    image.alt = visual.alt || "";
    if (visual.width) image.width = visual.width;
    if (visual.height) image.height = visual.height;
    image.loading = "eager";
    image.decoding = "async";
    image.fetchPriority = "high";
    image.addEventListener("error", function () {
      figure.classList.add("is-media-missing");
    }, { once: true });
    frame.appendChild(image);
    figure.append(frame, element("figcaption", "", visual.caption || `VISUAL ${visual.index}`));
    return figure;
  }

  function createNarrative(visual) {
    const narrative = element("div", "visual-record__narrative");
    narrative.appendChild(element("p", "visual-record__description", visual.description || ""));
    if (hasText(visual.context)) {
      narrative.appendChild(element("p", "visual-record__context", visual.context));
    }
    return narrative;
  }

  function createNavigation(visuals, activeIndex) {
    const previous = visuals[(activeIndex - 1 + visuals.length) % visuals.length];
    const next = visuals[(activeIndex + 1) % visuals.length];
    const navigation = element("nav", "visual-record__navigation");
    navigation.setAttribute("aria-label", "Visual narrative navigation");

    const indexLink = element("a", "visual-record__all", "ALL VISUALS ↗");
    indexLink.href = "index.html#visual-studies";

    const previousLink = element("a", "visual-record__previous");
    previousLink.href = visualHref(previous);
    previousLink.rel = "prev";
    previousLink.setAttribute("aria-label", `Previous visual: ${previous.title}`);
    previousLink.append(element("span", "", "PREVIOUS VISUAL"), element("strong", "", previous.title));

    const nextLink = element("a", "visual-record__next");
    nextLink.href = visualHref(next);
    nextLink.rel = "next";
    nextLink.setAttribute("aria-label", `Next visual: ${next.title}`);
    nextLink.append(element("span", "", "NEXT VISUAL"), element("strong", "", next.title));

    navigation.append(previousLink, nextLink, indexLink);
    return navigation;
  }

  function renderError(container) {
    const error = element("section", "visual-detail__error page-width");
    error.append(
      element("p", "", "VISUAL ARCHIVE"),
      element("h1", "", "VISUAL NOT FOUND"),
      element("p", "", "The requested visual record is unavailable or the link is incomplete.")
    );
    const link = element("a", "", "RETURN TO VISUALS ↗");
    link.href = "index.html#visual-studies";
    error.appendChild(link);
    container.replaceChildren(error);
  }

  function init() {
    const container = document.getElementById("visual-detail");
    const visuals = window.siteContent && Array.isArray(window.siteContent.visuals)
      ? window.siteContent.visuals
      : [];
    if (!container) return;
    const visual = findVisual(visuals, requestedKey());
    if (!visual) {
      renderError(container);
      return;
    }

    const activeIndex = visuals.indexOf(visual);
    setMeta(visual);
    document.body.dataset.visualSlug = visual.slug;
    const record = element(
      "section",
      `visual-record page-width orientation--${safeClass(visual.orientation, "landscape")}`
    );
    record.dataset.visualId = visual.id;
    record.append(
      createHeader(visual, visuals.length),
      createMedia(visual),
      createNarrative(visual),
      createNavigation(visuals, activeIndex)
    );
    container.replaceChildren(record);

    if (window.PortfolioEnhance && typeof window.PortfolioEnhance.refresh === "function") {
      window.PortfolioEnhance.refresh(record);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }
})();

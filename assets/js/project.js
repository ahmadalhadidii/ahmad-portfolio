(function () {
  "use strict";

  function element(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined && text !== null) node.textContent = text;
    return node;
  }

  function hasText(value) {
    return typeof value === "string" && value.trim().length > 0;
  }

  function requestedKey() {
    const params = new URLSearchParams(window.location.search);
    return document.documentElement.dataset.projectKey ||
      params.get("project") ||
      params.get("slug") ||
      params.get("id") ||
      "";
  }

  function normalize(value) {
    return String(value || "").trim().toLowerCase();
  }

  function assetHref(value) {
    const href = String(value || "");
    if (/^(?:[a-z]+:|\/\/|\/)/i.test(href)) return href;
    return `/${href.replace(/^\/+/, "")}`;
  }

  function assetSrcset(value) {
    return String(value || "").replace(/(^|,\s*)assets\//g, "$1/assets/");
  }

  function archiveTitle(project) {
    return hasText(project && project.archiveTitle) ? project.archiveTitle : project.title;
  }

  function archiveSubtitle(project) {
    return hasText(project && project.archiveSubtitle) ? project.archiveSubtitle : "";
  }

  function navigationTitle(project) {
    if (hasText(project && project.navigationTitle)) return project.navigationTitle;
    const title = archiveTitle(project);
    const subtitle = archiveSubtitle(project);
    return subtitle ? `${title} — ${subtitle}` : title;
  }

  function projectTheme(project) {
    return normalize(project && project.theme) === "manmatic" ? "manmatic" : "light";
  }

  function projectFileNumber(project) {
    const value = String((project && project.number) || "").trim();
    const branch = value.match(/^(\d+)\.([a-z])$/i);
    if (branch) return `${branch[1].padStart(3, "0")}.${branch[2].toUpperCase()}`;
    const numeric = Number.parseInt(value, 10);
    return Number.isFinite(numeric) ? String(numeric).padStart(2, "0") : value;
  }

  function setTheme(project) {
    const theme = projectTheme(project);
    const themeColor = document.querySelector('meta[name="theme-color"]');
    document.documentElement.dataset.initialTheme = theme;
    document.documentElement.dataset.siteTheme = theme;
    if (themeColor) {
      themeColor.setAttribute("content", theme === "manmatic" ? "#0a0a0a" : "#ffffff");
    }
  }

  function setRunningHeader(project) {
    const target = document.getElementById("running-header-text");
    if (!target) return;
    if (!project) {
      target.textContent = "PROJECT ARCHIVE / SELECTED WORK / 2026";
      return;
    }
    if (projectTheme(project) === "manmatic") {
      target.textContent = "MANMATIC / HUMAN–MACHINE COLLABORATION / ACTIVE FIELD";
      return;
    }
    target.textContent = `PROJECT FILE ${projectFileNumber(project)} / ${archiveTitle(project)} / ${project.year || "ARCHIVE"}`;
  }

  function addMediaClasses(node, value) {
    if (!hasText(value)) return;
    value.split(/\s+/).forEach(function (className) {
      if (/^[a-z0-9_-]+$/i.test(className)) node.classList.add(className);
    });
  }

  function findProject(projects, key) {
    const normalized = normalize(key);
    if (!normalized) return null;

    return (
      projects.find(function (project, index) {
        const aliases = [
          project.slug,
          project.id,
          project.number,
          String(index + 1),
          String(index + 1).padStart(2, "0")
        ].map(normalize);
        return aliases.includes(normalized);
      }) || null
    );
  }

  function projectHref(project) {
    return `/${String(project.route || `projects/${project.slug}/`).replace(/^\/+/, "")}`;
  }

  const canonicalBase = "https://www.ahmadalhadidii.manmatic.institute/";

  function absoluteProjectHref(project) {
    return new URL(projectHref(project), canonicalBase).href;
  }

  function ensureMeta(selector, attributes) {
    let node = document.querySelector(selector);
    if (!node) {
      node = document.createElement("meta");
      Object.keys(attributes).forEach(function (name) {
        node.setAttribute(name, attributes[name]);
      });
      document.head.appendChild(node);
    }
    return node;
  }

  function setMeta(project) {
    const title = hasText(project.seoTitle)
      ? project.seoTitle
      : `${navigationTitle(project)} — Ahmad Alhadidii`;
    document.title = title;
    const description = hasText(project.metaDescription)
      ? project.metaDescription
      : hasText(project.definition)
        ? project.definition
        : "Selected architecture and design research project by Ahmad Alhadidii.";
    const descriptionMeta = document.querySelector('meta[name="description"]');
    const ogTitle = document.querySelector('meta[property="og:title"]');
    const ogDescription = document.querySelector('meta[property="og:description"]');
    const canonicalUrl = absoluteProjectHref(project);
    const imageUrl = project.hero && project.hero.src
      ? new URL(project.hero.src, canonicalBase).href
      : `${canonicalBase}assets/images/architecture-of-elsewhere-1400.jpg`;
    if (descriptionMeta) descriptionMeta.setAttribute("content", description);
    if (ogTitle) ogTitle.setAttribute("content", title);
    if (ogDescription) ogDescription.setAttribute("content", description);
    [
      ['meta[property="og:url"]', { property: "og:url" }, canonicalUrl],
      ['meta[property="og:image"]', { property: "og:image" }, imageUrl],
      ['meta[name="twitter:title"]', { name: "twitter:title" }, title],
      ['meta[name="twitter:description"]', { name: "twitter:description" }, description],
      ['meta[name="twitter:image"]', { name: "twitter:image" }, imageUrl]
    ].forEach(function (entry) {
      ensureMeta(entry[0], entry[1]).setAttribute("content", entry[2]);
    });
    const canonical = document.querySelector('link[rel="canonical"]');
    if (canonical) canonical.setAttribute("href", canonicalUrl);
  }

  function appendMetadata(parent, project) {
    const values = [
      ["YEAR", project.year],
      ["LOCATION", project.location],
      ["TYPE", project.type || project.category],
      ["CONTEXT", project.context],
      ["OFFICE", project.office],
      ["RELATION", project.relation],
      ["AWARD", project.award],
      ["ROLE", project.role]
    ].filter(function (item) {
      return hasText(item[1]);
    });

    const list = element("dl", "project-meta");
    values.forEach(function (item) {
      const wrapper = element("div");
      wrapper.append(element("dt", "", item[0]), element("dd", "", item[1]));
      list.appendChild(wrapper);
    });
    parent.appendChild(list);
  }

  function createProjectHeader(project) {
    const header = element("header", "project-header");
    header.dataset.projectTheme = projectTheme(project);
    const eyebrow = element(
      "p",
      "project-header__eyebrow",
      `PROJECT FILE ${projectFileNumber(project)} / ${project.category}`
    );
    eyebrow.setAttribute("data-scramble", "");
    const title = element("h1");
    title.setAttribute("aria-label", navigationTitle(project));
    const titleVisual = element(
      "span",
      "project-header__archive-title pointer-scan",
      archiveTitle(project)
    );
    titleVisual.setAttribute("data-scramble", "");
    titleVisual.setAttribute("data-pointer-scan", "");
    titleVisual.setAttribute("data-pointer-text", archiveTitle(project));
    title.appendChild(titleVisual);
    if (archiveSubtitle(project)) {
      const subtitleVisual = element(
        "span",
        "project-header__archive-subtitle",
        archiveSubtitle(project)
      );
      title.append(" ", subtitleVisual);
    }
    const definition = element("p", "project-header__definition", project.definition);
    if (hasText(project.systemMarker)) {
      const systemNav = element("div", "project-header__system-nav");
      systemNav.appendChild(element("p", "", project.systemMarker));
      if (hasText(project.systemBack)) {
        const back = element("a", "", "BACK TO MANMATIC SYSTEM ←");
        back.href = project.systemBack;
        systemNav.appendChild(back);
      }
      header.appendChild(systemNav);
    }
    header.append(eyebrow, title, definition);
    appendMetadata(header, project);
    if (hasText(project.status)) {
      const status = element("div", "project-status");
      status.append(
        element("p", "project-status__label", `STATUS / ${project.status}`),
        element("p", "project-status__note", project.statusNote || "")
      );
      header.appendChild(status);
    }
    if (projectTheme(project) === "manmatic" && project.slug !== "protocol-port") {
      const fieldLink = element("a", "project-header__field-link", "MANMATIC FIELD ↗");
      fieldLink.href = "https://www.manmatic.institute/";
      fieldLink.target = "_blank";
      fieldLink.rel = "noopener noreferrer";
      fieldLink.setAttribute(
        "aria-label",
        "Open the ManMaTIC Institute field website in a new tab"
      );
      header.appendChild(fieldLink);
    }
    return header;
  }

  function createHero(project) {
    if (!project.hero || !hasText(project.hero.src)) return null;
    const fit = ["contain", "cover"].includes(normalize(project.hero.fit))
      ? normalize(project.hero.fit)
      : "cover";
    const section = element("section", "project-hero");
    section.setAttribute("aria-label", "Project visual");
    const figure = element("figure", "project-hero__media image-frame image-reveal");
    figure.classList.add(`media--${fit}`);
    figure.classList.add(`orientation--${/^[a-z0-9_-]+$/i.test(normalize(project.hero.orientation)) ? normalize(project.hero.orientation) : "landscape"}`);
    addMediaClasses(figure, project.hero.mediaClass);
    figure.dataset.mediaFit = fit;
    if (project.hero.width && project.hero.height) {
      figure.style.setProperty(
        "--media-ratio",
        `${project.hero.width} / ${project.hero.height}`
      );
    }
    figure.setAttribute("data-image-reveal", "");
    const crop = element("div", "image-frame__crop");
    const image = element("img");
    image.src = assetHref(project.hero.src);
    if (hasText(project.hero.srcset)) image.srcset = assetSrcset(project.hero.srcset);
    image.sizes = "(max-width: 760px) calc(100vw - 36px), (max-width: 960px) calc(100vw - 48px), min(960px, 56vw)";
    image.alt = project.hero.alt || "";
    if (project.hero.width) image.width = project.hero.width;
    if (project.hero.height) image.height = project.hero.height;
    image.loading = "eager";
    image.decoding = "async";
    image.fetchPriority = "high";
    image.draggable = false;
    image.style.objectFit = fit;
    crop.appendChild(image);
    figure.appendChild(crop);
    if (hasText(project.hero.caption)) {
      figure.appendChild(element("figcaption", "", project.hero.caption));
    }
    section.appendChild(figure);
    return section;
  }

  function createCopySection(number, label, title, copy) {
    if (!hasText(copy)) return null;
    const section = element("section", "project-copy-section page-width");
    const sectionLabel = element("p", "project-copy-section__label", `${number} / ${label}`);
    const body = element("div", "project-copy-section__body");
    body.append(element("h2", "", title), element("p", "", copy));
    section.append(sectionLabel, body);
    return section;
  }

  function createFramework(project) {
    const points = Array.isArray(project.points) ? project.points.filter(hasText) : [];
    if (!points.length) return null;
    const section = element("section", "project-copy-section page-width");
    const sectionLabel = element("p", "project-copy-section__label", "02 / FRAMEWORK");
    const body = element("div", "project-copy-section__body");
    body.appendChild(element("h2", "", "Concept and design framework"));
    const list = element("ol", "project-logic-list");
    points.forEach(function (point, index) {
      const item = element("li");
      item.append(
        element("span", "", String(index + 1).padStart(2, "0")),
        element("p", "", point)
      );
      list.appendChild(item);
    });
    body.appendChild(list);
    section.append(sectionLabel, body);
    return section;
  }

  function createProjectSection(record) {
    if (!record || !hasText(record.title)) return null;
    const section = element("section", "project-copy-section project-expanded-section page-width");
    section.id = normalize(record.title).replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
    const sectionLabel = element("p", "project-copy-section__label", `${record.code || "--"} / RECORD`);
    const body = element("div", "project-copy-section__body");
    body.appendChild(element("h2", "", record.title));
    if (hasText(record.text)) body.appendChild(element("p", "", record.text));
    if (hasText(record.status)) {
      body.appendChild(element("p", "project-status__label", `STATUS / ${record.status}`));
      if (hasText(record.statusNote)) body.appendChild(element("p", "project-status__note", record.statusNote));
    }

    function createRecordFigure(media, className) {
      if (!media || !hasText(media.src)) return null;
      const figure = element("figure", className || "project-record-media");
      const image = element("img");
      image.src = assetHref(media.src);
      if (hasText(media.srcset)) image.srcset = assetSrcset(media.srcset);
      image.sizes = "(max-width: 760px) calc(100vw - 36px), min(1180px, 82vw)";
      image.alt = media.alt || "";
      if (media.width) image.width = media.width;
      if (media.height) image.height = media.height;
      image.loading = "lazy";
      image.decoding = "async";
      figure.appendChild(image);
      if (hasText(media.caption)) figure.appendChild(element("figcaption", "", media.caption));
      return figure;
    }

    const primaryMedia = createRecordFigure(record.media);
    if (primaryMedia) body.appendChild(primaryMedia);

    if (Array.isArray(record.facts) && record.facts.length) {
      const facts = element("dl", "project-facts");
      record.facts.forEach(function (fact) {
        if (!Array.isArray(fact) || fact.length < 2) return;
        const row = element("div");
        row.append(element("dt", "", fact[0]), element("dd", "", fact[1]));
        facts.appendChild(row);
      });
      body.appendChild(facts);
    }

    if (Array.isArray(record.items) && record.items.length) {
      const list = element("ol", "project-sequence");
      record.items.filter(hasText).forEach(function (item, index) {
        const row = element("li");
        row.append(element("span", "", String(index + 1).padStart(2, "0")), element("p", "", item));
        list.appendChild(row);
      });
      body.appendChild(list);
    }

    if (Array.isArray(record.groups) && record.groups.length) {
      const groups = element("dl", "project-programme");
      record.groups.forEach(function (group) {
        if (!Array.isArray(group) || group.length < 2) return;
        const row = element("div");
        row.append(element("dt", "", group[0]), element("dd", "", group[1]));
        groups.appendChild(row);
      });
      body.appendChild(groups);
    }

    if (Array.isArray(record.roomIndex) && record.roomIndex.length) {
      body.appendChild(element("h3", "project-room-index__title", "ROOM INDEX"));
      const rooms = element("dl", "project-room-index");
      record.roomIndex.forEach(function (room) {
        if (!Array.isArray(room) || room.length < 2) return;
        const row = element("div");
        row.append(element("dt", "", room[0]), element("dd", "", room[1]));
        rooms.appendChild(row);
      });
      body.appendChild(rooms);
    }

    if (Array.isArray(record.gallery) && record.gallery.length) {
      const gallery = element("div", "project-record-gallery");
      record.gallery.forEach(function (media) {
        const figure = createRecordFigure(media, "project-record-media");
        if (figure) gallery.appendChild(figure);
      });
      body.appendChild(gallery);
    }

    if (Array.isArray(record.links) && record.links.length) {
      const links = element("div", "project-record-links");
      record.links.forEach(function (entry) {
        if (!Array.isArray(entry) || entry.length < 2) return;
        const link = element("a", "", entry[0]);
        link.href = entry[1];
        if (/^https?:\/\//i.test(entry[1])) {
          link.target = "_blank";
          link.rel = "noopener noreferrer";
        }
        links.appendChild(link);
      });
      body.appendChild(links);
    }
    section.append(sectionLabel, body);
    return section;
  }

  function createCredits(project) {
    const credits = [
      ["ROLE", project.role],
      ["CATEGORY", project.category],
      ["CONTEXT", project.context],
      ["ORGANISATIONS", project.organisations],
      ["OFFICE", project.office],
      ["SUPERVISION", project.supervision]
    ].filter(function (item) {
      return hasText(item[1]);
    });
    if (!credits.length) return null;

    const section = element("section", "project-copy-section page-width");
    const sectionLabel = element("p", "project-copy-section__label", "03 / CREDITS");
    const body = element("div", "project-copy-section__body");
    body.appendChild(element("h2", "", "Project contribution"));
    const list = element("dl", "project-credit-list");
    credits.forEach(function (credit) {
      const wrapper = element("div");
      wrapper.append(element("dt", "", credit[0]), element("dd", "", credit[1]));
      list.appendChild(wrapper);
    });
    body.appendChild(list);
    section.append(sectionLabel, body);
    return section;
  }

  function createNavigation(projects, currentIndex) {
    const previous = projects[(currentIndex - 1 + projects.length) % projects.length];
    const next = projects[(currentIndex + 1) % projects.length];
    const section = element("nav", "project-navigation page-width");
    section.setAttribute("aria-label", "Project navigation");

    const top = element("div", "project-navigation__top");
    const back = element("a", "", "BACK TO WORK ←");
    back.href = "/#work";
    const indexLink = element("a", "", "PORTFOLIO INDEX ↑");
    indexLink.href = "/#index";
    top.append(back, indexLink);

    if (currentIndex < 0) {
      const systemLink = element("a", "project-navigation__link", "BACK TO MANMATIC METHODOLOGY ←");
      systemLink.href = "/projects/manmatic/";
      section.append(top, systemLink);
      return section;
    }

    const grid = element("div", "project-navigation__grid");
    const previousLink = element("a", "project-navigation__link");
    previousLink.href = projectHref(previous);
    previousLink.rel = "prev";
    previousLink.setAttribute("aria-label", `Previous project, ${navigationTitle(previous)}`);
    previousLink.append(
      element("p", "project-navigation__direction", `PREVIOUS / ${previous.number}`),
      element("p", "project-navigation__title", navigationTitle(previous))
    );

    const nextLink = element("a", "project-navigation__link");
    nextLink.href = projectHref(next);
    nextLink.rel = "next";
    nextLink.setAttribute("aria-label", `Next project, ${navigationTitle(next)}`);
    nextLink.append(
      element("p", "project-navigation__direction", `NEXT / ${next.number}`),
      element("p", "project-navigation__title", navigationTitle(next))
    );
    grid.append(previousLink, nextLink);
    section.append(top, grid);
    return section;
  }

  function renderInvalid(article) {
    setTheme(null);
    setRunningHeader(null);
    document.title = "Project Not Found — Ahmad Alhadidii";
    article.textContent = "";
    const section = element("section", "project-detail__error page-width");
    section.append(
      element("p", "", "PROJECT ARCHIVE / INVALID ROUTE"),
      element("h1", "", "PROJECT NOT FOUND"),
      element("p", "", "The requested project is not part of the selected work index.")
    );
    const link = element("a", "", "RETURN TO SELECTED WORK");
    link.href = "/#work";
    section.appendChild(link);
    article.appendChild(section);
  }

  function renderProject(article, projects, project) {
    const currentIndex = projects.indexOf(project);
    setTheme(project);
    setRunningHeader(project);
    setMeta(project);
    document.body.dataset.project = project.slug;
    article.textContent = "";

    const header = createProjectHeader(project);
    const hero = createHero(project);
    const intro = element("div", "project-intro page-width");
    intro.appendChild(header);
    if (hero) intro.appendChild(hero);
    const overview = createCopySection("01", "OVERVIEW", "Project overview", project.overview);
    const framework = Array.isArray(project.sections) && project.sections.length
      ? null
      : createFramework(project);
    const expanded = Array.isArray(project.sections)
      ? project.sections.map(createProjectSection).filter(Boolean)
      : [];
    const credits = createCredits(project);
    const navigation = createNavigation(projects, currentIndex);

    [intro, overview, framework].concat(expanded, [credits, navigation]).forEach(function (node) {
      if (node) article.appendChild(node);
    });

    function enhanceProjectEntry() {
      if (window.PortfolioEnhance) window.PortfolioEnhance.refresh(article);
    }

    if (document.documentElement.classList.contains("loader-complete")) {
      enhanceProjectEntry();
    } else {
      document.addEventListener("portfolio:ready", enhanceProjectEntry, { once: true });
    }
  }

  function init() {
    const article = document.getElementById("project-detail");
    const content = window.siteContent;
    const allProjects = content && Array.isArray(content.projects) ? content.projects : [];
    const projects = allProjects
      .filter(function (project) { return project.featured !== false; })
      .sort(function (a, b) { return (a.displayOrder || 999) - (b.displayOrder || 999); });
    if (!article || !projects.length) {
      if (article) renderInvalid(article);
      return;
    }

    const requested = findProject(allProjects, requestedKey());
    const project = requested && requested.parentSystem
      ? findProject(allProjects, requested.parentSystem)
      : requested;
    if (!project) {
      renderInvalid(article);
      return;
    }

    renderProject(article, projects, project);
    if (requested && requested.parentSystem) {
      window.requestAnimationFrame(function () {
        const target = document.getElementById("protocol-port");
        if (target) target.scrollIntoView({ block: "start" });
      });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }
})();

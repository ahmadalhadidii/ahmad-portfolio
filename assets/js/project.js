(function () {
  "use strict";

  const content = window.siteContent || {};
  const projectRoot = document.getElementById("project-detail");

  function makeElement(tag, className, text) {
    const element = document.createElement(tag);
    if (className) {
      element.className = className;
    }
    if (typeof text === "string") {
      element.textContent = text;
    }
    return element;
  }

  function safeArray(value) {
    return Array.isArray(value) ? value : [];
  }

  function hasValue(value) {
    if (typeof value === "string") {
      return value.trim().length > 0;
    }
    if (Array.isArray(value)) {
      return value.some(hasValue);
    }
    if (typeof value === "number") {
      return true;
    }
    if (value && typeof value === "object") {
      return Object.keys(value).some(function (key) {
        return hasValue(value[key]);
      });
    }
    return false;
  }

  function firstValue() {
    for (let index = 0; index < arguments.length; index += 1) {
      if (hasValue(arguments[index])) {
        return arguments[index];
      }
    }
    return "";
  }

  function normalizeKey(value) {
    return String(value || "").trim().toLowerCase();
  }

  function projectAliases(project, index) {
    const aliases = [project.slug, project.id, project.number, String(index + 1)];
    if (/^\d+$/.test(String(project.number || ""))) {
      aliases.push(String(Number(project.number)));
    }
    return aliases.filter(hasValue).map(normalizeKey);
  }

  function requestedProjectKey() {
    const parameters = new URLSearchParams(window.location.search);
    return normalizeKey(
      parameters.get("project") || parameters.get("slug") || parameters.get("id")
    );
  }

  function findProject(projects, key) {
    if (!key) {
      return { project: null, index: -1 };
    }

    for (let index = 0; index < projects.length; index += 1) {
      if (projectAliases(projects[index], index).includes(key)) {
        return { project: projects[index], index: index };
      }
    }
    return { project: null, index: -1 };
  }

  function projectKey(project, index) {
    return String(firstValue(project.slug, project.id, project.number, index + 1));
  }

  function projectHref(project, index) {
    return "project.html?project=" + encodeURIComponent(projectKey(project, index));
  }

  function repairProjectNavigation() {
    const homeLink = document.querySelector(".site-header__name");
    if (homeLink) {
      homeLink.setAttribute("href", "index.html#top");
      if (content.person && content.person.displayName) {
        homeLink.textContent = content.person.displayName;
        homeLink.setAttribute(
          "aria-label",
          content.person.name + ", return to portfolio home"
        );
      }
    }

    document.querySelectorAll(".site-nav a").forEach(function (link, index) {
      const navItem = safeArray(content.nav)[index] || {};
      const href = link.getAttribute("href") || "";
      link.removeAttribute("data-scramble-text");
      if (hasValue(navItem.target)) {
        link.setAttribute("href", "index.html" + String(navItem.target));
      } else if (href.charAt(0) === "#") {
        link.setAttribute("href", "index.html" + href);
      }

      const isWork = (link.getAttribute("href") || "").endsWith("#work");
      link.classList.toggle("is-active", isWork);
      const sectionName = normalizeKey(
        navItem.target ? String(navItem.target).replace(/^#/, "") : ""
      );
      if (sectionName) {
        link.dataset.sectionLink = sectionName;
      }
      if (hasValue(navItem.number) || hasValue(navItem.label)) {
        const number = makeElement("span", "", String(navItem.number || ""));
        link.replaceChildren(number, document.createTextNode(String(navItem.label || "")));
      }
      if (isWork) {
        link.setAttribute("aria-current", "location");
      } else {
        link.removeAttribute("aria-current");
      }
    });
  }

  function setMeta(project) {
    const personName = content.person && content.person.name;
    const detail = project.detail || {};
    const introduction = detail.introduction || project.introduction || {};
    const title = [project.title, personName].filter(hasValue).join(" — ");
    const description = String(
      firstValue(project.description, introduction.statement, introduction.concept, content.meta && content.meta.description)
    );

    if (title) {
      document.title = title;
    }

    if (content.meta && content.meta.language) {
      document.documentElement.lang = content.meta.language;
    }

    setMetaContent('meta[name="description"]', description);
    setMetaContent('meta[property="og:title"]', title);
    setMetaContent('meta[property="og:description"]', description);

    const hero = getHeroMedia(project);
    if (hero && hero.src) {
      let imageUrl = hero.src;
      try {
        imageUrl = new URL(hero.src, document.baseURI).href;
      } catch (error) {
        imageUrl = hero.src;
      }
      setMetaContent('meta[property="og:image"]', imageUrl, "property", "og:image");
    }
  }

  function setMetaContent(selector, value, attributeName, attributeValue) {
    if (!hasValue(value)) {
      return;
    }

    let meta = document.querySelector(selector);
    if (!meta && attributeName && attributeValue) {
      meta = document.createElement("meta");
      meta.setAttribute(attributeName, attributeValue);
      document.head.appendChild(meta);
    }
    if (meta) {
      meta.setAttribute("content", String(value));
    }
  }

  function formatValue(value) {
    if (Array.isArray(value)) {
      return value
        .map(function (item) {
          if (typeof item === "string" || typeof item === "number") {
            return String(item);
          }
          if (item && typeof item === "object") {
            return String(firstValue(item.name, item.title, item.value));
          }
          return "";
        })
        .filter(hasValue)
        .join(" / ");
    }
    if (typeof value === "string" || typeof value === "number") {
      return String(value);
    }
    if (value && typeof value === "object") {
      return String(firstValue(value.value, value.name, value.title));
    }
    return "";
  }

  function appendDefinition(list, label, value) {
    const formatted = formatValue(value);
    if (!hasValue(formatted)) {
      return;
    }

    const group = makeElement("div", "project-meta__item");
    group.append(
      makeElement("dt", "project-meta__label", label),
      makeElement("dd", "project-meta__value", formatted)
    );
    list.appendChild(group);
  }

  function sanitizeClass(value) {
    return String(value || "")
      .toLowerCase()
      .replace(/[^a-z0-9_-]+/g, "-")
      .replace(/^-+|-+$/g, "");
  }

  function validRatio(value, fallback) {
    const ratio = String(value || "").trim();
    return /^\d+(?:\.\d+)?\s*\/\s*\d+(?:\.\d+)?$/.test(ratio)
      ? ratio
      : fallback;
  }

  function createConstructionGrid() {
    const namespace = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(namespace, "svg");
    svg.setAttribute("class", "construction-grid");
    svg.setAttribute("viewBox", "0 0 800 500");
    svg.setAttribute("preserveAspectRatio", "none");
    svg.setAttribute("aria-hidden", "true");

    const fine = document.createElementNS(namespace, "path");
    fine.setAttribute(
      "d",
      "M100 0V500M200 0V500M300 0V500M400 0V500M500 0V500M600 0V500M700 0V500M0 100H800M0 200H800M0 300H800M0 400H800"
    );

    const strong = document.createElementNS(namespace, "path");
    strong.setAttribute("class", "construction-grid__strong");
    strong.setAttribute("d", "M0 0L800 500M800 0L0 500M400 0V500M0 250H800");

    const circle = document.createElementNS(namespace, "circle");
    circle.setAttribute("cx", "400");
    circle.setAttribute("cy", "250");
    circle.setAttribute("r", "62");

    svg.append(fine, strong, circle);
    return svg;
  }

  function createPlaceholder(mediaData) {
    const placeholder = makeElement("div", "media-fallback image-placeholder");
    placeholder.setAttribute("aria-hidden", "true");
    placeholder.appendChild(createConstructionGrid());

    const copy = makeElement("div", "media-fallback__label image-placeholder__copy");
    copy.appendChild(makeElement("span", "", "IMAGE PENDING"));
    if (hasValue(mediaData.src)) {
      copy.appendChild(makeElement("span", "", mediaData.src));
    }
    placeholder.appendChild(copy);

    if (hasValue(mediaData.code)) {
      placeholder.appendChild(
        makeElement("span", "media-fallback__code image-placeholder__code image-code", String(mediaData.code))
      );
    }
    return placeholder;
  }

  function makePlaceholderAccessible(placeholder, mediaData) {
    const label = String(firstValue(mediaData.alt, mediaData.caption, mediaData.code, "Image unavailable"));
    placeholder.setAttribute("aria-hidden", "false");
    placeholder.setAttribute("role", "img");
    placeholder.setAttribute("aria-label", label);
  }

  function monitorImage(frame, image, placeholder, mediaData) {
    let settled = false;

    function finish(state) {
      if (settled) {
        return;
      }
      settled = true;
      frame.classList.remove("is-pending", "has-image", "is-missing");
      frame.classList.add(state);

      if (state === "has-image") {
        placeholder.setAttribute("aria-hidden", "true");
      } else {
        image.hidden = true;
        image.removeAttribute("src");
        image.removeAttribute("srcset");
        makePlaceholderAccessible(placeholder, mediaData);
      }
    }

    image.addEventListener("load", function () {
      finish("has-image");
    }, { once: true });
    image.addEventListener("error", function () {
      finish("is-missing");
    }, { once: true });

    if (hasValue(mediaData.srcset)) {
      image.setAttribute("srcset", mediaData.srcset);
    }
    image.src = mediaData.src;
    if (image.complete) {
      finish(image.naturalWidth > 0 ? "has-image" : "is-missing");
    }
  }

  function createMediaFigure(mediaData, project, options) {
    const settings = options || {};
    const figure = makeElement(
      "figure",
      "project-detail-figure project-figure" + (settings.className ? " " + settings.className : "")
    );
    const mediaClass = sanitizeClass(mediaData.type);
    if (mediaClass) {
      figure.classList.add("project-detail-figure--" + mediaClass);
    }

    const frame = makeElement("div", "project-detail-media project-media media-frame is-pending");
    frame.style.aspectRatio = validRatio(
      mediaData.ratio,
      settings.hero ? "16 / 9" : settings.split ? "4 / 3" : "16 / 10"
    );

    const placeholder = createPlaceholder(mediaData);
    frame.appendChild(placeholder);

    if (hasValue(mediaData.src)) {
      const image = makeElement("img", "project-detail-media__image");
      image.alt = typeof mediaData.alt === "string" ? mediaData.alt : "";
      image.loading = settings.hero ? "eager" : "lazy";
      image.decoding = "async";
      if (settings.hero) {
        image.setAttribute("fetchpriority", "high");
      }
      image.setAttribute(
        "sizes",
        String(firstValue(mediaData.sizes, settings.split ? "(max-width: 760px) 100vw, 50vw" : "100vw"))
      );
      if (Number(mediaData.width) > 0 && Number(mediaData.height) > 0) {
        image.width = Number(mediaData.width);
        image.height = Number(mediaData.height);
      }
      if (hasValue(mediaData.position)) {
        image.style.objectPosition = mediaData.position;
      }
      frame.prepend(image);
      monitorImage(frame, image, placeholder, mediaData);
    } else {
      frame.classList.remove("is-pending");
      frame.classList.add("is-missing");
      makePlaceholderAccessible(placeholder, mediaData);
    }

    figure.appendChild(frame);

    if (hasValue(mediaData.caption) || hasValue(mediaData.code)) {
      const caption = makeElement("figcaption", "project-detail-figure__caption image-caption");
      if (hasValue(mediaData.caption)) {
        caption.appendChild(makeElement("span", "", String(mediaData.caption)));
      }
      if (hasValue(mediaData.code)) {
        caption.appendChild(makeElement("span", "image-code", String(mediaData.code)));
      }
      figure.appendChild(caption);
    }

    if (project && project.title) {
      figure.dataset.projectTitle = project.title;
    }
    return figure;
  }

  function getHeroMedia(project) {
    const detail = project.detail || {};
    return firstValue(
      detail.hero,
      project.hero,
      project.previewImage,
      project.preview,
      safeArray(detail.images)[0],
      safeArray(project.images)[0]
    );
  }

  function renderProjectHero(project) {
    const detail = project.detail || {};
    const metadata = detail.metadata || project.metadata || {};
    const header = makeElement("header", "project-detail__hero project-hero");
    const identity = makeElement("div", "project-hero__identity page-grid shell");

    const indexText = hasValue(project.number)
      ? "PROJECT / " + project.number
      : "PROJECT";
    identity.appendChild(makeElement("p", "project-hero__index eyebrow", indexText));

    const title = makeElement("h1", "project-hero__title", String(project.title || ""));
    title.id = "project-title";
    identity.appendChild(title);

    if (hasValue(project.subtitle)) {
      identity.appendChild(makeElement("p", "project-hero__subtitle", String(project.subtitle)));
    }
    if (hasValue(project.description)) {
      identity.appendChild(makeElement("p", "project-hero__description", String(project.description)));
    }

    const tags = safeArray(project.tags).filter(hasValue);
    if (tags.length) {
      const tagList = makeElement("ul", "project-hero__tags");
      tagList.setAttribute("aria-label", "Project tags");
      tags.forEach(function (tag) {
        tagList.appendChild(makeElement("li", "", String(tag)));
      });
      identity.appendChild(tagList);
    }
    header.appendChild(identity);

    const heroMedia = getHeroMedia(project);
    if (heroMedia && typeof heroMedia === "object") {
      const mediaWrap = makeElement("div", "project-hero__media page-grid shell");
      mediaWrap.appendChild(
        createMediaFigure(heroMedia, project, {
          hero: true,
          className: "project-detail-figure--hero"
        })
      );
      header.appendChild(mediaWrap);
    }

    const meta = makeElement("dl", "project-meta page-grid shell");
    appendDefinition(meta, "YEAR", project.year);
    appendDefinition(meta, "LOCATION", project.location);
    appendDefinition(meta, "TYPOLOGY", firstValue(project.typology, project.type));
    appendDefinition(meta, "STATUS", firstValue(metadata.status, project.status));
    appendDefinition(meta, "ROLE", firstValue(metadata.role, project.role));
    appendDefinition(meta, "TEAM", firstValue(metadata.team, project.team));
    if (meta.children.length) {
      header.appendChild(meta);
    }

    return header;
  }

  function appendParagraphs(parent, value, className) {
    let values = [];
    if (typeof value === "string" || typeof value === "number") {
      values = [String(value)];
    } else if (Array.isArray(value)) {
      values = value.map(formatValue).filter(hasValue);
    } else if (value && typeof value === "object") {
      values = safeArray(firstValue(value.paragraphs, value.copy));
      if (!values.length) {
        const single = firstValue(value.text, value.description, value.value);
        if (hasValue(single)) {
          values = [formatValue(single)];
        }
      }
    }

    values.filter(hasValue).forEach(function (paragraph) {
      parent.appendChild(makeElement("p", className || "", String(paragraph)));
    });
  }

  function createIntroductionItem(label, value, modifier) {
    if (!hasValue(value)) {
      return null;
    }
    const item = makeElement("div", "project-introduction__item project-introduction__item--" + modifier);
    item.appendChild(makeElement("h3", "project-introduction__label eyebrow", label));
    appendParagraphs(item, value, "project-introduction__text");
    return item.children.length > 1 ? item : null;
  }

  function renderIntroduction(project) {
    const detail = project.detail || {};
    const introduction = detail.introduction || project.introduction || {};
    const statement = firstValue(introduction.statement, introduction.concept);
    const question = firstValue(introduction.question, introduction.problem);
    const response = firstValue(introduction.response, introduction.mainResponse);

    const items = [
      createIntroductionItem("CONCEPT", statement, "concept"),
      createIntroductionItem("PROJECT QUESTION", question, "question"),
      createIntroductionItem("MAIN RESPONSE", response, "response")
    ].filter(Boolean);

    if (!items.length) {
      return null;
    }

    const section = makeElement("section", "project-introduction page-grid shell");
    section.setAttribute("aria-labelledby", "project-introduction-title");
    const heading = makeElement("h2", "project-section-title", "PROJECT INTRODUCTION");
    heading.id = "project-introduction-title";
    const grid = makeElement("div", "project-introduction__grid");
    grid.append.apply(grid, items);
    section.append(heading, grid);
    return section;
  }

  function isSplitLayout(value) {
    return ["half", "split", "two-column", "two_column"].includes(normalizeKey(value));
  }

  function appendMediaSequence(parent, items, project, defaultLayout) {
    let splitGroup = null;

    safeArray(items).forEach(function (mediaData) {
      if (!mediaData || typeof mediaData !== "object" || !hasValue(firstValue(mediaData.src, mediaData.code, mediaData.caption))) {
        return;
      }

      const split = isSplitLayout(firstValue(mediaData.layout, defaultLayout));
      if (split) {
        if (!splitGroup || splitGroup.children.length >= 2) {
          splitGroup = makeElement("div", "project-narrative__split page-grid shell");
          parent.appendChild(splitGroup);
        }
        splitGroup.appendChild(
          createMediaFigure(mediaData, project, {
            split: true,
            className: "project-detail-figure--split"
          })
        );
      } else {
        splitGroup = null;
        const full = makeElement("div", "project-narrative__full page-grid shell");
        full.appendChild(
          createMediaFigure(mediaData, project, {
            className: "project-detail-figure--full"
          })
        );
        parent.appendChild(full);
      }
    });
  }

  function createNarrativeText(block) {
    const text = firstValue(block.paragraphs, block.copy, block.text, block.description);
    if (!hasValue(firstValue(block.label, block.title, text))) {
      return null;
    }

    const article = makeElement("article", "project-narrative__text page-grid shell");
    if (hasValue(block.label)) {
      article.appendChild(makeElement("p", "eyebrow", String(block.label)));
    }
    if (hasValue(block.title)) {
      article.appendChild(makeElement("h3", "project-narrative__title", String(block.title)));
    }
    appendParagraphs(article, text, "project-narrative__copy");
    return article;
  }

  function renderNarrative(project) {
    const detail = project.detail || {};
    const structured = safeArray(firstValue(detail.narrative, project.narrative));
    const legacyImages = safeArray(firstValue(detail.images, project.images));
    const flow = makeElement("div", "project-narrative__flow");

    if (structured.length) {
      structured.forEach(function (block) {
        if (!block || typeof block !== "object") {
          return;
        }
        const kind = normalizeKey(
          block.kind || (block.items || block.images ? "media" : "text")
        );
        if (kind === "media" || kind === "images" || kind === "gallery") {
          appendMediaSequence(flow, safeArray(firstValue(block.items, block.images)), project, block.layout);
        } else if (hasValue(block.src)) {
          appendMediaSequence(flow, [block], project, block.layout);
        } else {
          const textBlock = createNarrativeText(block);
          if (textBlock) {
            flow.appendChild(textBlock);
          }
        }
      });
    } else {
      appendMediaSequence(flow, legacyImages, project, "full");
    }

    if (!flow.children.length) {
      return null;
    }

    const section = makeElement("section", "project-narrative");
    section.setAttribute("aria-labelledby", "project-narrative-title");
    const headingWrap = makeElement("header", "project-narrative__header page-grid shell");
    const heading = makeElement("h2", "project-section-title", "VISUAL NARRATIVE");
    heading.id = "project-narrative-title";
    headingWrap.appendChild(heading);
    section.append(headingWrap, flow);
    return section;
  }

  function informationRows(information) {
    if (Array.isArray(information)) {
      return information.map(function (item) {
        return {
          label: item && firstValue(item.label, item.title),
          value: item && firstValue(item.paragraphs, item.copy, item.text, item.description, item.value)
        };
      });
    }

    const source = information && typeof information === "object" ? information : {};
    return [
      { label: "RESEARCH", value: source.research },
      { label: "PROCESS", value: source.process },
      { label: "DESIGN SYSTEM", value: source.designSystem },
      { label: "TECHNICAL DEVELOPMENT", value: source.technicalDevelopment },
      { label: "OUTCOME", value: source.outcome }
    ];
  }

  function renderInformation(project) {
    const detail = project.detail || {};
    const information = firstValue(detail.information, project.information);
    const rows = informationRows(information).filter(function (row) {
      return row && hasValue(row.label) && hasValue(row.value);
    });

    if (!rows.length) {
      return null;
    }

    const section = makeElement("section", "project-information page-grid shell");
    section.setAttribute("aria-labelledby", "project-information-title");
    const heading = makeElement("h2", "project-section-title", "PROJECT INFORMATION");
    heading.id = "project-information-title";
    const list = makeElement("div", "project-information__list");

    rows.forEach(function (row, index) {
      const article = makeElement("article", "project-information__item");
      const label = makeElement("h3", "project-information__label", String(row.label));
      label.prepend(makeElement("span", "project-information__index", String(index + 1).padStart(2, "0")));
      article.appendChild(label);
      appendParagraphs(article, row.value, "project-information__copy");
      if (article.children.length > 1) {
        list.appendChild(article);
      }
    });

    if (!list.children.length) {
      return null;
    }
    section.append(heading, list);
    return section;
  }

  function createProjectNavLink(direction, project, index) {
    const link = makeElement("a", "project-pagination__link project-pagination__link--" + direction);
    link.href = projectHref(project, index);
    link.dataset.pageTransition = "project";
    const directionLabel = direction === "previous" ? "Previous project" : "Next project";
    link.setAttribute(
      "aria-label",
      hasValue(project.title) ? directionLabel + ": " + project.title : directionLabel
    );
    link.append(
      makeElement(
        "span",
        "project-pagination__direction eyebrow",
        direction === "previous" ? "← PREVIOUS PROJECT" : "NEXT PROJECT →"
      ),
      makeElement("span", "project-pagination__title", String(project.title || ""))
    );
    return link;
  }

  function renderPagination(projects, currentIndex) {
    const navigation = makeElement("nav", "project-pagination page-grid shell");
    navigation.setAttribute("aria-label", "Project navigation");

    if (projects.length > 1) {
      const previousIndex = (currentIndex - 1 + projects.length) % projects.length;
      navigation.appendChild(createProjectNavLink("previous", projects[previousIndex], previousIndex));
    }

    const indexLink = makeElement("a", "project-pagination__index text-link", "PROJECT INDEX");
    indexLink.href = "index.html#work";
    indexLink.setAttribute("aria-label", "Return to selected work project index");
    navigation.appendChild(indexLink);

    if (projects.length > 1) {
      const nextIndex = (currentIndex + 1) % projects.length;
      navigation.appendChild(createProjectNavLink("next", projects[nextIndex], nextIndex));
    }
    return navigation;
  }

  function renderInvalidProject(hasRequestedKey) {
    if (!projectRoot) {
      return;
    }

    const personName = content.person && content.person.name;
    const errorTitle = ["Project not found", personName].filter(hasValue).join(" — ");
    const errorDescription = hasRequestedKey
      ? "The requested project is not available in the portfolio index."
      : "Open a project from the selected work index.";
    document.title = errorTitle;
    setMetaContent('meta[name="description"]', errorDescription);
    setMetaContent('meta[property="og:title"]', errorTitle);
    setMetaContent('meta[property="og:description"]', errorDescription);
    const section = makeElement("section", "project-detail__error page-grid shell");
    section.setAttribute("aria-labelledby", "project-error-title");
    section.appendChild(makeElement("p", "eyebrow", "PROJECT ARCHIVE / ERROR"));

    const title = makeElement("h1", "project-detail__error-title", "PROJECT NOT FOUND");
    title.id = "project-error-title";
    section.appendChild(title);
    section.appendChild(
      makeElement(
        "p",
        "project-detail__error-copy",
        hasRequestedKey
          ? "The requested project is not available in the portfolio index."
          : "Open a project from the selected work index."
      )
    );
    const link = makeElement("a", "text-link", "RETURN TO PROJECT INDEX");
    link.href = "index.html#work";
    section.appendChild(link);
    projectRoot.setAttribute("aria-labelledby", "project-error-title");
    projectRoot.replaceChildren(section);
  }

  function renderProject(projects, project, index) {
    setMeta(project);
    document.body.dataset.project = projectKey(project, index);
    projectRoot.setAttribute("aria-labelledby", "project-title");

    const fragment = document.createDocumentFragment();
    fragment.appendChild(renderProjectHero(project));

    const introduction = renderIntroduction(project);
    if (introduction) {
      fragment.appendChild(introduction);
    }

    const narrative = renderNarrative(project);
    if (narrative) {
      fragment.appendChild(narrative);
    }

    const information = renderInformation(project);
    if (information) {
      fragment.appendChild(information);
    }

    fragment.appendChild(renderPagination(projects, index));
    projectRoot.replaceChildren(fragment);
  }

  function init() {
    repairProjectNavigation();

    const footer = document.getElementById("footer-copy");
    if (footer && content.footer && content.footer.text) {
      footer.textContent = content.footer.text;
    }

    const projects = safeArray(content.projects).filter(function (project) {
      return project && typeof project === "object";
    });
    const key = requestedProjectKey();
    const match = findProject(projects, key);

    if (!projectRoot || !match.project) {
      renderInvalidProject(Boolean(key));
      return;
    }

    renderProject(projects, match.project, match.index);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }
})();

(function () {
  "use strict";

  const content = window.siteContent || {};
  const root = document.documentElement;
  const body = document.body;
  const isHome = body.classList.contains("home-page");
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  let menuPreviouslyFocused = null;
  let themeFrame = 0;

  function byId(id) {
    return document.getElementById(id);
  }

  function safeArray(value) {
    return Array.isArray(value) ? value : [];
  }

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

  function setText(id, value) {
    const element = byId(id);
    if (element && typeof value === "string") {
      element.textContent = value;
    }
  }

  function hasValue(value) {
    return typeof value === "string"
      ? value.trim().length > 0
      : value !== null && value !== undefined;
  }

  function clamp(value, minimum, maximum) {
    return Math.min(Math.max(value, minimum), maximum);
  }

  function updateDocumentMeta() {
    if (content.meta && content.meta.title) {
      document.title = content.meta.title;
    }
    if (content.meta && content.meta.description) {
      const description = document.querySelector('meta[name="description"]');
      if (description) {
        description.content = content.meta.description;
      }
    }
    if (content.meta && content.meta.language) {
      root.lang = content.meta.language;
    }
  }

  function createConstructionGrid() {
    const namespace = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(namespace, "svg");
    svg.setAttribute("viewBox", "0 0 800 500");
    svg.setAttribute("preserveAspectRatio", "none");
    svg.setAttribute("aria-hidden", "true");

    const fine = document.createElementNS(namespace, "path");
    fine.setAttribute(
      "d",
      "M100 0V500M200 0V500M300 0V500M400 0V500M500 0V500M600 0V500M700 0V500M0 100H800M0 200H800M0 300H800M0 400H800"
    );

    const strong = document.createElementNS(namespace, "path");
    strong.setAttribute("class", "strong");
    strong.setAttribute("d", "M0 0L800 500M800 0L0 500M400 0V500M0 250H800");

    const circle = document.createElementNS(namespace, "circle");
    circle.setAttribute("cx", "400");
    circle.setAttribute("cy", "250");
    circle.setAttribute("r", "64");

    svg.append(fine, strong, circle);
    return svg;
  }

  function createMediaFallback(mediaData, label) {
    const fallback = makeElement("div", "media-fallback");
    fallback.setAttribute("aria-hidden", "true");
    fallback.appendChild(createConstructionGrid());

    const copy = makeElement("div", "media-fallback__label");
    copy.appendChild(makeElement("span", "", label || "IMAGE PENDING"));
    copy.appendChild(makeElement("span", "", mediaData.src || "ADD IMAGE PATH"));
    fallback.appendChild(copy);

    if (mediaData.code) {
      fallback.appendChild(makeElement("span", "media-code", mediaData.code));
    }
    return fallback;
  }

  function applyResponsiveImageAttributes(image, mediaData, sizes) {
    image.sizes = mediaData.sizes || sizes || "100vw";
    if (Number(mediaData.width) > 0 && Number(mediaData.height) > 0) {
      image.width = Number(mediaData.width);
      image.height = Number(mediaData.height);
    }
    if (mediaData.position) {
      image.style.objectPosition = mediaData.position;
    }
  }

  function monitorImage(frame, image, fallback, mediaData) {
    let settled = false;

    function cleanup() {
      image.removeEventListener("load", onLoad);
      image.removeEventListener("error", onError);
    }

    function finish(loaded) {
      if (settled) {
        return;
      }
      settled = true;
      cleanup();
      frame.classList.remove("is-pending", "has-image", "is-missing");
      frame.classList.add(loaded ? "has-image" : "is-missing");

      if (loaded) {
        fallback.setAttribute("aria-hidden", "true");
      } else {
        image.hidden = true;
        image.removeAttribute("src");
        image.removeAttribute("srcset");
        fallback.setAttribute("aria-hidden", "false");
        fallback.setAttribute("role", "img");
        fallback.setAttribute(
          "aria-label",
          mediaData.alt || mediaData.caption || "Image pending replacement"
        );
      }
    }

    function onLoad() {
      finish(true);
    }

    function onError() {
      finish(false);
    }

    image.addEventListener("load", onLoad, { once: true });
    image.addEventListener("error", onError, { once: true });

    if (mediaData.srcset) {
      image.srcset = mediaData.srcset;
    }

    if (image.getAttribute("src") !== mediaData.src) {
      image.src = mediaData.src;
    } else if (image.complete) {
      finish(image.naturalWidth > 0);
    }
  }

  function prepareExistingMedia(frame, image, fallback, mediaData, sizes) {
    if (!frame || !image || !fallback || !mediaData || !mediaData.src) {
      return;
    }
    image.alt = mediaData.alt || "";
    applyResponsiveImageAttributes(image, mediaData, sizes);
    monitorImage(frame, image, fallback, mediaData);
  }

  function createMediaFrame(mediaData, options) {
    const settings = options || {};
    const frame = makeElement("div", "media-frame is-pending " + (settings.className || ""));
    if (settings.ratio) {
      frame.style.aspectRatio = settings.ratio;
    }

    const image = makeElement("img");
    image.alt = mediaData.alt || "";
    image.loading = settings.eager ? "eager" : "lazy";
    image.decoding = "async";
    if (settings.eager) {
      image.setAttribute("fetchpriority", "high");
    }
    applyResponsiveImageAttributes(image, mediaData, settings.sizes);

    const fallback = createMediaFallback(mediaData, settings.label);
    frame.append(image, fallback);
    monitorImage(frame, image, fallback, mediaData);
    return frame;
  }

  function renderNavigation() {
    if (!isHome) {
      return;
    }
    const nav = byId("primary-navigation");
    const items = safeArray(content.nav);
    if (!nav || !items.length) {
      return;
    }

    const fragment = document.createDocumentFragment();
    items.forEach(function (item) {
      const link = makeElement("a");
      const sectionName = String(item.target || "").replace(/^#/, "");
      link.href = item.target;
      link.dataset.sectionLink = sectionName;
      link.append(
        makeElement("span", "", item.number),
        document.createTextNode(item.label)
      );
      fragment.appendChild(link);
    });
    nav.replaceChildren(fragment);
  }

  function bindSectionHeading(sectionId, sectionData, note) {
    const section = byId(sectionId);
    if (!section || !sectionData) {
      return;
    }
    const number = section.querySelector(".section-heading__number");
    const title = section.querySelector(".section-heading h2");
    const headingNote = section.querySelector(".section-heading__note");
    if (number && sectionData.number) {
      number.textContent = sectionData.number;
    }
    if (title && sectionData.title) {
      title.textContent = sectionData.title;
    }
    if (headingNote && note) {
      headingNote.textContent = String(note).toUpperCase();
    }
  }

  function renderSharedIdentity() {
    const person = content.person || {};
    const headerName = document.querySelector(".site-header__name");
    if (headerName && person.displayName) {
      headerName.textContent = person.displayName;
      headerName.setAttribute("aria-label", person.name + ", return to top");
    }

    const intro = byId("intro");
    if (intro && person.name) {
      intro.setAttribute("aria-label", "Opening " + person.name + " architecture portfolio");
    }

    const contactIdentity = document.querySelector(".contact__identity");
    if (contactIdentity) {
      contactIdentity.textContent = [person.displayName, person.discipline]
        .filter(hasValue)
        .join("\n");
    }

    bindSectionHeading("profile", content.profile);
    bindSectionHeading("cv", content.cv, content.cv && content.cv.eyebrow);
    bindSectionHeading("work", content.work, content.work && content.work.eyebrow);
    bindSectionHeading("method", content.method);
    bindSectionHeading("contact", content.contact, content.contact && content.contact.availability);
  }

  function applyContentLink(element, linkData) {
    if (!element || !linkData) {
      return;
    }
    element.href = linkData.href || "#";
    if (linkData.placeholder || linkData.href === "#") {
      element.dataset.placeholder = "true";
      element.setAttribute("aria-disabled", "true");
      element.title = "Replace this placeholder link in content.js";
    }
  }

  function renderHeroAndProfile() {
    const hero = content.hero || {};
    const profile = content.profile || {};

    setText("hero-name", hero.name);
    setText("hero-discipline", hero.discipline);
    setText("hero-edition", hero.edition);
    setText("hero-location", hero.location);
    setText("hero-concept", hero.conceptualTitle);
    setText("hero-scroll-label", hero.scrollLabel);

    if (hero.image) {
      setText("hero-path", hero.image.src);
      setText("hero-code", hero.image.code);
      prepareExistingMedia(
        byId("hero-media"),
        byId("hero-image"),
        byId("hero-media") && byId("hero-media").querySelector(".media-fallback"),
        hero.image,
        "100vw"
      );
    }

    if (profile.portrait) {
      setText("portrait-path", profile.portrait.src);
      setText("portrait-code", profile.portrait.code);
      prepareExistingMedia(
        byId("portrait-media"),
        byId("portrait-image"),
        byId("portrait-media") && byId("portrait-media").querySelector(".media-fallback"),
        profile.portrait,
        "(max-width: 820px) 82vw, 33vw"
      );
    }

    setText("profile-statement", profile.positionStatement);

    const profileCopy = byId("profile-copy");
    if (profileCopy && safeArray(profile.paragraphs).length) {
      const fragment = document.createDocumentFragment();
      profile.paragraphs.forEach(function (paragraph) {
        fragment.appendChild(makeElement("p", "", paragraph));
      });
      profileCopy.replaceChildren(fragment);
    }

    const metadata = byId("profile-metadata");
    if (metadata && safeArray(profile.metadata).length) {
      const fragment = document.createDocumentFragment();
      profile.metadata.forEach(function (item) {
        const group = makeElement("div");
        group.append(
          makeElement("dt", "", item.label),
          makeElement("dd", "", item.value)
        );
        fragment.appendChild(group);
      });
      metadata.replaceChildren(fragment);
    }

    const profileLink = byId("profile-cv-link");
    if (profileLink && profile.cvLink) {
      profileLink.firstChild.textContent = profile.cvLink.label + " ";
      applyContentLink(profileLink, profile.cvLink);
    }
  }

  function createCVEntry(record, kind) {
    const entry = makeElement("article", "cv-entry");
    const index = makeElement("p", "cv-entry__index", record.index || "—");
    const contentColumn = makeElement("div", "cv-entry__content");

    let role = record.role || record.qualification || record.title || "";
    let institution = record.institution || record.result || "";
    contentColumn.appendChild(makeElement("h4", "cv-entry__role", role));
    if (institution) {
      contentColumn.appendChild(makeElement("p", "cv-entry__institution", institution));
    }
    if (record.description) {
      contentColumn.appendChild(makeElement("p", "cv-entry__description", record.description));
    }

    const context = makeElement("div", "cv-entry__context");
    if (record.location) {
      context.appendChild(makeElement("span", "", record.location));
    }
    if (record.date) {
      context.appendChild(makeElement("time", "", record.date));
    }

    entry.append(index, contentColumn, context);
    entry.dataset.cvKind = kind;
    return entry;
  }

  function createCVGroup(title, records, modifier) {
    const section = makeElement("section", "cv-group cv-group--" + modifier);
    section.appendChild(makeElement("h3", "cv-group__title", title));
    safeArray(records).forEach(function (record) {
      section.appendChild(createCVEntry(record, modifier));
    });
    return section;
  }

  function createSupportGroup(title, values, type) {
    const section = makeElement("section", "cv-support-group cv-support-group--" + type);
    section.appendChild(makeElement("h3", "cv-support-group__title", title));

    if (!safeArray(values).length) {
      section.classList.add("is-empty");
      section.appendChild(makeElement("p", "", "—"));
      return section;
    }

    if (type === "software") {
      const list = makeElement("ul", "software-index");
      values.forEach(function (value) {
        const item = makeElement("li");
        item.append(
          makeElement("span", "", value),
          makeElement("span", "software-index__signal")
        );
        list.appendChild(item);
      });
      section.appendChild(list);
    } else {
      const list = makeElement("ul", "cv-support-list");
      values.forEach(function (value) {
        list.appendChild(makeElement("li", "", value));
      });
      section.appendChild(list);
    }
    return section;
  }

  function renderCV() {
    const cv = content.cv || {};
    const timeline = cv.timeline || {};
    const supporting = cv.supporting || {};
    const main = byId("cv-main");
    const support = byId("cv-support");

    if (main) {
      main.replaceChildren(
        createCVGroup("EXPERIENCE", timeline.experience, "experience"),
        createCVGroup("EDUCATION", timeline.education, "education"),
        createCVGroup("AWARDS / COMPETITIONS", timeline.awards, "awards")
      );
    }

    if (support) {
      support.replaceChildren(
        createSupportGroup("SOFTWARE", supporting.software, "software"),
        createSupportGroup("DESIGN STRENGTHS", supporting.designStrengths, "strengths"),
        createSupportGroup("TECHNICAL SKILLS", supporting.technicalSkills, "technical"),
        createSupportGroup("LANGUAGES", supporting.languages, "languages"),
        createSupportGroup("CERTIFICATIONS", supporting.certifications, "certifications")
      );
    }

    const actions = byId("cv-actions");
    if (actions && cv.links) {
      const links = [cv.links.view, cv.links.download];
      const existing = actions.querySelectorAll("a");
      links.forEach(function (linkData, index) {
        const link = existing[index];
        if (link && linkData) {
          link.firstChild.textContent = linkData.label + " ";
          applyContentLink(link, linkData);
        }
      });
    }
  }

  function createDefinition(label, value) {
    const group = makeElement("div");
    group.append(
      makeElement("dt", "", label),
      makeElement("dd", "", value || "—")
    );
    return group;
  }

  function renderProjects() {
    const container = byId("project-previews");
    const projects = safeArray(content.projects);
    if (!container) {
      return;
    }

    const fragment = document.createDocumentFragment();
    projects.forEach(function (project, index) {
      const article = makeElement("article", "project-preview");
      if ((index + 1) % 3 === 0) {
        article.classList.add("is-featured");
      }

      const link = makeElement("a", "project-preview__link");
      link.href = "project.html?project=" + encodeURIComponent(project.slug || project.id || project.number);
      link.dataset.pageTransition = "project";
      link.setAttribute("aria-label", "View project " + project.number + ": " + project.title);

      const media = createMediaFrame(project.previewImage || {}, {
        className: "project-preview__media",
        sizes: (index + 1) % 3 === 0
          ? "100vw"
          : "(max-width: 820px) 100vw, 66vw",
        label: "ADD PROJECT PREVIEW"
      });

      const info = makeElement("div", "project-preview__info");
      info.append(
        makeElement("p", "project-preview__index", "PROJECT / " + project.number),
        makeElement("h3", "project-preview__title", project.title),
        makeElement("p", "project-preview__description", project.description)
      );

      const meta = makeElement("dl", "project-preview__meta");
      meta.append(
        createDefinition("YEAR", project.year),
        createDefinition("LOCATION", project.location),
        createDefinition("TYPE", project.type)
      );
      info.appendChild(meta);

      const tags = makeElement("ul", "project-preview__tags");
      safeArray(project.tags).forEach(function (tag) {
        tags.appendChild(makeElement("li", "", tag));
      });
      info.appendChild(tags);

      const action = makeElement("p", "project-preview__action");
      action.append(
        makeElement("span", "", (content.work && content.work.viewLabel) || "VIEW PROJECT"),
        makeElement("span", "", "→")
      );
      info.appendChild(action);

      link.append(media, info);
      article.appendChild(link);
      fragment.appendChild(article);
    });
    container.replaceChildren(fragment);
  }

  function createMethodDiagram(type) {
    const namespace = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(namespace, "svg");
    svg.setAttribute("class", "method-diagram");
    svg.setAttribute("viewBox", "0 0 220 92");
    svg.setAttribute("aria-hidden", "true");
    svg.setAttribute("focusable", "false");

    function add(tag, attributes, className) {
      const node = document.createElementNS(namespace, tag);
      Object.keys(attributes).forEach(function (name) {
        node.setAttribute(name, attributes[name]);
      });
      if (className) {
        node.setAttribute("class", className);
      }
      svg.appendChild(node);
    }

    if (type === "research-grid") {
      add("path", { d: "M18 12V80M64 12V80M110 12V80M156 12V80M202 12V80M10 24H210M10 46H210M10 68H210" }, "soft");
      add("path", { d: "M18 68L64 52L110 60L156 28L202 38" });
      add("circle", { cx: 156, cy: 28, r: 3 });
    } else if (type === "connected-system") {
      add("path", { d: "M14 68L52 22L98 54L148 18L204 64M52 22L148 18M98 54L204 64" });
      [[14, 68], [52, 22], [98, 54], [148, 18], [204, 64]].forEach(function (point) {
        add("circle", { cx: point[0], cy: point[1], r: 3 });
      });
    } else if (type === "iteration-series") {
      add("path", { d: "M12 68C52 68 56 18 94 18S140 68 178 68M30 76C68 76 72 34 110 34S156 76 208 76" });
      add("path", { d: "M94 18V74M110 34V82" }, "soft");
      add("circle", { cx: 94, cy: 18, r: 3 });
      add("circle", { cx: 110, cy: 34, r: 3 });
    } else if (type === "rule-to-space") {
      add("path", { d: "M12 22H84M12 46H84M12 70H84M104 12L208 22V74L104 82ZM104 12L154 34L208 22M154 34V66M104 82L154 66L208 74" });
      add("path", { d: "M84 22L104 12M84 46L154 34M84 70L104 82" }, "soft");
    } else {
      add("path", { d: "M16 74H204M28 60H192M44 46H176M64 32H156M88 18H132" });
      add("path", { d: "M16 74L88 18M204 74L132 18" }, "soft");
      add("circle", { cx: 110, cy: 18, r: 3 });
    }
    return svg;
  }

  function renderMethod() {
    const sequence = byId("method-sequence");
    const stages = content.method && safeArray(content.method.stages);
    if (!sequence || !stages) {
      return;
    }

    const fragment = document.createDocumentFragment();
    stages.forEach(function (stage) {
      const article = makeElement("article", "method-stage");
      article.append(
        makeElement("p", "method-stage__number", stage.number),
        makeElement("h3", "method-stage__title", stage.title),
        makeElement("p", "method-stage__sentence", stage.sentence),
        createMethodDiagram(stage.diagram)
      );
      fragment.appendChild(article);
    });
    sequence.replaceChildren(fragment);
  }

  function renderContactAndFooter() {
    const contact = content.contact || {};
    const linksContainer = byId("contact-links");
    setText("contact-availability", String(contact.availability || "").toUpperCase());

    if (linksContainer) {
      const fragment = document.createDocumentFragment();
      safeArray(contact.links).forEach(function (linkData) {
        const link = makeElement("a");
        link.href = linkData.href || "#";
        if (linkData.placeholder || linkData.href === "#") {
          link.dataset.placeholder = "true";
          link.setAttribute("aria-disabled", "true");
          link.title = "Replace this placeholder link in content.js";
        }
        link.append(
          makeElement("span", "", linkData.label),
          makeElement("span", "", linkData.value)
        );
        fragment.appendChild(link);
      });
      linksContainer.replaceChildren(fragment);
    }
    if (content.footer && content.footer.text) {
      setText("footer-text", content.footer.text);
    }
  }

  function setupMobileMenu() {
    const toggle = byId("nav-toggle");
    const navigation = byId("primary-navigation");
    if (!toggle || !navigation) {
      return;
    }

    function menuLinks() {
      return Array.from(navigation.querySelectorAll("a[href]"));
    }

    function openMenu() {
      menuPreviouslyFocused = document.activeElement;
      toggle.setAttribute("aria-expanded", "true");
      navigation.classList.add("is-open");
      body.classList.add("nav-open");
      const links = menuLinks();
      if (links.length) {
        links[0].focus();
      }
    }

    function closeMenu(restoreFocus) {
      toggle.setAttribute("aria-expanded", "false");
      navigation.classList.remove("is-open");
      body.classList.remove("nav-open");
      if (restoreFocus && menuPreviouslyFocused && typeof menuPreviouslyFocused.focus === "function") {
        menuPreviouslyFocused.focus({ preventScroll: true });
      }
      menuPreviouslyFocused = null;
    }

    toggle.addEventListener("click", function () {
      if (toggle.getAttribute("aria-expanded") === "true") {
        closeMenu(false);
      } else {
        openMenu();
      }
    });

    navigation.addEventListener("click", function (event) {
      if (event.target.closest("a") && toggle.getAttribute("aria-expanded") === "true") {
        closeMenu(true);
      }
    });

    document.addEventListener("keydown", function (event) {
      if (toggle.getAttribute("aria-expanded") !== "true") {
        return;
      }

      if (event.key === "Escape") {
        event.preventDefault();
        closeMenu(true);
        return;
      }

      if (event.key === "Tab") {
        const focusable = [toggle].concat(menuLinks());
        const first = focusable[0];
        const last = focusable[focusable.length - 1];
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault();
          last.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first.focus();
        }
      }
    });

    window.addEventListener("resize", function () {
      if (window.innerWidth > 820 && toggle.getAttribute("aria-expanded") === "true") {
        closeMenu(false);
      }
    });
  }

  function setActiveNavigation(sectionName) {
    document.querySelectorAll("[data-section-link]").forEach(function (link) {
      const active = link.dataset.sectionLink === sectionName;
      link.classList.toggle("is-active", active);
      if (active) {
        link.setAttribute("aria-current", "location");
      } else {
        link.removeAttribute("aria-current");
      }
    });
  }

  function updateScrollState() {
    themeFrame = 0;
    if (!isHome) {
      return;
    }

    const work = byId("work");
    const contact = byId("contact");
    const hero = byId("top");
    const header = byId("site-header");
    const sections = Array.from(document.querySelectorAll("[data-nav-section]"));
    const viewport = window.innerHeight || 800;
    const scrollTop = window.scrollY || window.pageYOffset;

    if (!work || !contact || !hero || !header) {
      return;
    }

    let darkness;
    if (reducedMotion.matches) {
      darkness = scrollTop >= work.offsetTop - viewport * 0.18 &&
        scrollTop < contact.offsetTop - viewport * 0.18 ? 1 : 0;
    } else {
      const sectionPadding = Number.parseFloat(window.getComputedStyle(work).paddingTop) || 160;
      const boundarySpace = Math.max(120, Math.min(viewport * 0.28, sectionPadding));
      const darkStart = work.offsetTop - boundarySpace;
      const darkEnd = work.offsetTop - 20;
      const lightStart = contact.offsetTop - boundarySpace;
      const lightEnd = contact.offsetTop - 20;
      const darkIn = clamp((scrollTop - darkStart) / Math.max(darkEnd - darkStart, 1), 0, 1);
      const lightOut = clamp((scrollTop - lightStart) / Math.max(lightEnd - lightStart, 1), 0, 1);
      darkness = darkIn * (1 - lightOut);
    }
    root.style.setProperty("--dark-progress", darkness.toFixed(3));

    const overHero = scrollTop < hero.offsetHeight - 100;
    header.classList.toggle("is-over-hero", overHero);
    header.classList.toggle("is-scrolled", !overHero);
    header.classList.toggle("is-dark", !overHero && darkness >= 0.5);
    header.classList.toggle("is-light", !overHero && darkness < 0.5);

    const readingLine = scrollTop + 64 + viewport * 0.25;
    let current = "";
    sections.forEach(function (section) {
      if (section.offsetTop <= readingLine) {
        current = section.dataset.navSection;
      }
    });
    setActiveNavigation(current);

    const themeMeta = document.querySelector('meta[name="theme-color"]');
    if (themeMeta) {
      themeMeta.content = overHero || darkness >= 0.5 ? "#090909" : "#f1f0eb";
    }
  }

  function requestScrollUpdate() {
    if (!themeFrame) {
      themeFrame = window.requestAnimationFrame(updateScrollState);
    }
  }

  function setupScrollState() {
    if (!isHome) {
      return;
    }
    window.addEventListener("scroll", requestScrollUpdate, { passive: true });
    window.addEventListener("resize", requestScrollUpdate);
    window.addEventListener("pageshow", requestScrollUpdate);
    if (document.fonts && document.fonts.ready) {
      document.fonts.ready.then(requestScrollUpdate);
    }
    updateScrollState();
  }

  function setupPlaceholderLinks() {
    document.addEventListener("click", function (event) {
      const placeholder = event.target.closest('a[data-placeholder="true"], a[href="#"]');
      if (placeholder) {
        event.preventDefault();
      }
    });
  }

  function setupPageTransitions() {
    document.addEventListener("click", function (event) {
      const link = event.target.closest("a[data-page-transition]");
      if (!link || event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
        return;
      }
      if (link.target || link.hasAttribute("download") || reducedMotion.matches) {
        return;
      }
      const href = link.getAttribute("href");
      if (!href) {
        return;
      }
      event.preventDefault();
      body.classList.add("is-leaving");
      window.setTimeout(function () {
        window.location.href = href;
      }, 280);
    });

    window.addEventListener("pageshow", function () {
      body.classList.remove("is-leaving");
    });
  }

  function runIntro() {
    if (!isHome) {
      return;
    }
    const intro = byId("intro");
    const count = byId("intro-count");
    const introImage = byId("intro-image");
    const loader = content.loader || {};
    const heroImage = content.hero && content.hero.image;
    const startValue = Number.parseInt(loader.start, 10);
    const endValue = Number.parseInt(loader.end, 10);
    const duration = clamp(Number(loader.duration) || 2300, 1800, 2500);
    const exitDuration = Math.min(620, duration * 0.3);
    const counterDuration = Math.max(duration - exitDuration - 30, 900);
    const shouldPlay = root.classList.contains("intro-pending") && !reducedMotion.matches;
    let finished = false;

    function finish() {
      if (finished) {
        return;
      }
      finished = true;
      root.classList.remove("intro-pending", "intro-revealing");
      root.classList.add("intro-complete");
      if (intro) {
        intro.hidden = true;
      }
      requestScrollUpdate();
    }

    if (!intro || !shouldPlay) {
      finish();
      return;
    }

    setText("intro-label", loader.label || "ARCHIVE / INITIALIZING");
    if (count) {
      count.textContent = String(Number.isFinite(startValue) ? startValue : 0).padStart(3, "0");
    }

    if (introImage) {
      introImage.addEventListener("error", function () {
        introImage.hidden = true;
        introImage.removeAttribute("src");
      }, { once: true });
      if (introImage.complete && introImage.naturalWidth === 0) {
        introImage.hidden = true;
        introImage.removeAttribute("src");
      }
      if (heroImage && heroImage.src && introImage.getAttribute("src") !== heroImage.src) {
        introImage.hidden = false;
        if (heroImage.srcset) {
          introImage.srcset = heroImage.srcset;
        }
        introImage.src = heroImage.src;
      }
    }

    window.requestAnimationFrame(function () {
      intro.classList.add("is-active");
    });

    const start = performance.now();
    function updateCounter(now) {
      const ratio = clamp((now - start) / counterDuration, 0, 1);
      if (count) {
        const from = Number.isFinite(startValue) ? startValue : 0;
        const to = Number.isFinite(endValue) ? endValue : 100;
        count.textContent = String(Math.round(from + (to - from) * ratio)).padStart(3, "0");
      }
      if (ratio < 1 && !finished) {
        window.requestAnimationFrame(updateCounter);
      }
    }
    window.requestAnimationFrame(updateCounter);

    window.setTimeout(function () {
      root.classList.add("intro-revealing");
      intro.classList.add("is-exiting");
    }, duration - exitDuration);

    window.setTimeout(finish, duration);
    window.setTimeout(finish, Math.min(duration + 180, 2500));
  }

  function initHome() {
    runIntro();
    updateDocumentMeta();
    renderNavigation();
    renderSharedIdentity();
    renderHeroAndProfile();
    renderCV();
    renderProjects();
    renderMethod();
    renderContactAndFooter();
    setupScrollState();
  }

  function init() {
    setupMobileMenu();
    setupPlaceholderLinks();
    setupPageTransitions();
    if (isHome) {
      initHome();
    }
  }

  window.PortfolioUI = {
    createMediaFrame: createMediaFrame,
    monitorImage: monitorImage,
    requestScrollUpdate: requestScrollUpdate
  };

  init();
})();

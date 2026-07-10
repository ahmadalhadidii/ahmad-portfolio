(function () {
  "use strict";

  const content = window.siteContent || {};
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const scrambleFrames = new WeakMap();
  let openProject = null;

  function byId(id) {
    return document.getElementById(id);
  }

  function setText(id, value) {
    const element = byId(id);
    if (element && typeof value === "string") {
      element.textContent = value;
    }
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

  function safeArray(value) {
    return Array.isArray(value) ? value : [];
  }

  function updateDocumentMeta() {
    if (content.meta && content.meta.title) {
      document.title = content.meta.title;
    }

    if (content.meta && content.meta.description) {
      const description = document.querySelector('meta[name="description"]');
      if (description) {
        description.setAttribute("content", content.meta.description);
      }
    }
  }

  function renderNavigation() {
    const nav = document.querySelector(".site-nav");
    const items = safeArray(content.nav);
    if (!nav || !items.length) {
      return;
    }

    const fragment = document.createDocumentFragment();
    items.forEach(function (item) {
      const link = makeElement("a", "nav-link", item.label);
      link.href = item.target;
      link.dataset.scrambleText = item.label;
      fragment.appendChild(link);
    });
    nav.replaceChildren(fragment);
  }

  function renderIdentity() {
    const person = content.person || {};
    const hero = content.hero || {};
    const profile = content.profile || {};

    setText("hero-name", person.displayName);
    setText("hero-role", person.role);
    setText("hero-statement", person.statement);

    const metadata = safeArray(hero.metadata);
    setText("hero-location", metadata[0]);
    setText("hero-years", metadata[1]);
    setText("hero-availability", metadata[2]);

    const heroImage = byId("hero-image");
    const heroFrame = byId("hero-media-frame");
    if (heroImage && heroFrame && hero.image) {
      heroImage.alt = "Selected architectural work by " + (person.name || "Ahmad Alhadidii");
      setText("hero-caption", hero.caption);
      setText("hero-image-code", hero.imageLabel);
      setText("hero-placeholder-path", hero.image);
      const placeholderCode = heroFrame.querySelector(".image-placeholder__code");
      if (placeholderCode) {
        placeholderCode.textContent = hero.imageLabel;
      }
      monitorImage(heroFrame, heroImage, hero.image);
    }

    const profileCopy = byId("profile-copy");
    if (profileCopy && safeArray(profile.paragraphs).length) {
      const fragment = document.createDocumentFragment();
      profile.paragraphs.forEach(function (paragraph) {
        fragment.appendChild(makeElement("p", "", paragraph));
      });
      profileCopy.replaceChildren(fragment);
    }

    const facts = byId("profile-facts");
    if (facts && safeArray(profile.facts).length) {
      const fragment = document.createDocumentFragment();
      profile.facts.forEach(function (fact, index) {
        const item = makeElement("li");
        item.appendChild(makeElement("span", "", String(index + 1).padStart(2, "0")));
        item.appendChild(document.createTextNode(fact));
        fragment.appendChild(item);
      });
      facts.replaceChildren(fragment);
    }

    applyLink(byId("profile-cv-link"), profile.cvLink);
  }

  function applyLink(element, linkData) {
    if (!element || !linkData) {
      return;
    }
    if (linkData.href) {
      element.setAttribute("href", linkData.href);
    }
    if (linkData.label) {
      element.firstChild.textContent = linkData.label + " ";
    }
  }

  function monitorImage(frame, image, source) {
    frame.classList.remove("has-image", "is-missing");
    frame.classList.add("is-pending");

    let settled = false;

    function clearListeners() {
      image.removeEventListener("load", onLoad);
      image.removeEventListener("error", onError);
    }

    function onLoad() {
      if (settled) {
        return;
      }
      settled = true;
      clearListeners();
      frame.classList.remove("is-pending", "is-missing");
      frame.classList.add("has-image");
      frame.dataset.imageState = "loaded";
    }

    function onError() {
      if (settled) {
        return;
      }
      settled = true;
      clearListeners();
      image.removeAttribute("src");
      frame.classList.remove("is-pending", "has-image");
      frame.classList.add("is-missing");
      frame.dataset.imageState = "missing";
    }

    image.addEventListener("load", onLoad, { once: true });
    image.addEventListener("error", onError, { once: true });

    if (image.getAttribute("src") !== source) {
      image.setAttribute("src", source);
    } else if (image.complete) {
      if (image.naturalWidth > 0) {
        onLoad();
      } else {
        onError();
      }
    }
  }

  function createConstructionGrid() {
    const namespace = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(namespace, "svg");
    svg.setAttribute("class", "construction-grid");
    svg.setAttribute("viewBox", "0 0 800 600");
    svg.setAttribute("preserveAspectRatio", "none");
    svg.setAttribute("aria-hidden", "true");

    const fine = document.createElementNS(namespace, "path");
    fine.setAttribute("d", "M100 0V600M200 0V600M300 0V600M400 0V600M500 0V600M600 0V600M700 0V600M0 100H800M0 200H800M0 300H800M0 400H800M0 500H800");

    const strong = document.createElementNS(namespace, "path");
    strong.setAttribute("class", "construction-grid__strong");
    strong.setAttribute("d", "M0 0L800 600M800 0L0 600M400 0V600M0 300H800");

    const circle = document.createElementNS(namespace, "circle");
    circle.setAttribute("cx", "400");
    circle.setAttribute("cy", "300");
    circle.setAttribute("r", "74");

    svg.append(fine, strong, circle);
    return svg;
  }

  function createPlaceholder(source, code) {
    const placeholder = makeElement("div", "image-placeholder");
    placeholder.setAttribute("aria-hidden", "true");
    placeholder.appendChild(createConstructionGrid());

    const copy = makeElement("div", "image-placeholder__copy");
    copy.appendChild(makeElement("span", "", "REPLACE IMAGE"));
    copy.appendChild(makeElement("span", "", source));
    placeholder.appendChild(copy);
    placeholder.appendChild(makeElement("span", "image-placeholder__code image-code", code));
    return placeholder;
  }

  function createMetaRow(label, value) {
    const item = makeElement("li");
    item.append(makeElement("span", "", label), makeElement("span", "", value));
    return item;
  }

  function createProjectFigure(project, imageData) {
    const figure = makeElement("figure", "project-figure");
    const media = makeElement("div", "project-media is-pending");
    media.dataset.source = imageData.src;

    const image = makeElement("img");
    image.loading = "lazy";
    image.decoding = "async";
    image.alt = project.title + " — " + imageData.caption + " (" + imageData.code + ")";
    media.append(image, createPlaceholder(imageData.src, imageData.code));

    const caption = makeElement("figcaption", "image-caption");
    caption.append(
      makeElement("span", "", imageData.caption),
      makeElement("span", "image-code", imageData.code)
    );

    figure.append(media, caption);
    return figure;
  }

  function renderProjects() {
    const list = byId("project-list");
    const projects = safeArray(content.projects);
    if (!list) {
      return;
    }

    const fragment = document.createDocumentFragment();

    projects.forEach(function (project, projectIndex) {
      const article = makeElement("article", "project");
      const triggerId = "project-trigger-" + project.number;
      const panelId = "project-panel-" + project.number;

      const trigger = makeElement("button", "project__trigger");
      trigger.type = "button";
      trigger.id = triggerId;
      trigger.setAttribute("aria-expanded", "false");
      trigger.setAttribute("aria-controls", panelId);
      trigger.dataset.projectIndex = String(projectIndex);

      const state = makeElement(
        "span",
        "project__state",
        (content.work && content.work.openLabel) || "[OPEN]"
      );
      state.dataset.projectState = "";

      trigger.append(
        makeElement("span", "project__number", project.number),
        makeElement("span", "project__title", project.title),
        makeElement("span", "project__type", project.type),
        makeElement("span", "project__year", project.year),
        state
      );

      const panel = makeElement("div", "project__panel");
      panel.id = panelId;
      panel.hidden = true;
      panel.inert = true;
      panel.setAttribute("role", "region");
      panel.setAttribute("aria-labelledby", triggerId);

      const sheet = makeElement("div", "project-sheet");
      const sheetHeader = makeElement("div", "project-sheet__header");
      sheetHeader.appendChild(
        makeElement(
          "p",
          "project-sheet__number",
          project.number + " / " + String(projects.length).padStart(2, "0")
        )
      );

      const identity = makeElement("div", "project-sheet__identity");
      identity.append(
        makeElement("h3", "", project.title),
        makeElement("p", "", project.subtitle)
      );
      sheetHeader.appendChild(identity);

      const meta = makeElement("ul", "project-sheet__meta");
      meta.append(
        createMetaRow("YEAR", project.year),
        createMetaRow("TYPE", project.type),
        createMetaRow("STATUS", project.status)
      );
      sheetHeader.appendChild(meta);

      const sheetBody = makeElement("div", "project-sheet__body");
      sheetBody.appendChild(makeElement("p", "project-sheet__description", project.description));
      const details = makeElement("ol", "project-sheet__details");
      safeArray(project.details).forEach(function (detail) {
        details.appendChild(makeElement("li", "", detail));
      });
      sheetBody.appendChild(details);

      const gallery = makeElement("div", "project-gallery");
      gallery.setAttribute("aria-label", project.title + " image gallery");
      safeArray(project.images).forEach(function (imageData) {
        gallery.appendChild(createProjectFigure(project, imageData));
      });

      sheet.append(sheetHeader, sheetBody, gallery);
      panel.appendChild(sheet);
      article.append(trigger, panel);
      fragment.appendChild(article);
    });

    list.replaceChildren(fragment);
    bindProjectAccordions();
  }

  function hydrateProjectImages(panel) {
    panel.querySelectorAll(".project-media[data-source]").forEach(function (media) {
      if (media.dataset.imageState) {
        return;
      }
      const image = media.querySelector("img");
      const source = media.dataset.source;
      if (image && source) {
        monitorImage(media, image, source);
      }
    });
  }

  function setProjectState(trigger, expanded, restoreFocus) {
    const panel = byId(trigger.getAttribute("aria-controls"));
    const state = trigger.querySelector("[data-project-state]");
    const finalText = expanded
      ? (content.work && content.work.closeLabel) || "[CLOSE]"
      : (content.work && content.work.openLabel) || "[OPEN]";

    trigger.setAttribute("aria-expanded", String(expanded));
    if (panel) {
      panel.hidden = !expanded;
      panel.inert = !expanded;
      if (expanded) {
        hydrateProjectImages(panel);
      }
    }
    if (state) {
      scrambleText(state, finalText, 150);
    }
    if (!expanded && restoreFocus) {
      trigger.focus({ preventScroll: true });
    }
  }

  function toggleProject(trigger) {
    const willOpen = trigger.getAttribute("aria-expanded") !== "true";

    if (openProject && openProject !== trigger) {
      setProjectState(openProject, false, false);
    }

    setProjectState(trigger, willOpen, false);
    openProject = willOpen ? trigger : null;
  }

  function bindProjectAccordions() {
    const triggers = Array.from(document.querySelectorAll(".project__trigger"));

    triggers.forEach(function (trigger, index) {
      trigger.addEventListener("click", function () {
        toggleProject(trigger);
      });

      trigger.addEventListener("pointerenter", function () {
        const state = trigger.querySelector("[data-project-state]");
        if (state) {
          scrambleText(state, state.textContent, 130);
        }
      });

      trigger.addEventListener("keydown", function (event) {
        let nextIndex = null;
        if (event.key === "ArrowDown") {
          nextIndex = (index + 1) % triggers.length;
        } else if (event.key === "ArrowUp") {
          nextIndex = (index - 1 + triggers.length) % triggers.length;
        } else if (event.key === "Home") {
          nextIndex = 0;
        } else if (event.key === "End") {
          nextIndex = triggers.length - 1;
        }

        if (nextIndex !== null) {
          event.preventDefault();
          triggers[nextIndex].focus();
        }
      });
    });

    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape" && openProject) {
        const trigger = openProject;
        setProjectState(trigger, false, true);
        openProject = null;
      }
    });
  }

  function createMethodDiagram(type) {
    const namespace = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(namespace, "svg");
    svg.setAttribute("class", "method-diagram");
    svg.setAttribute("viewBox", "0 0 240 72");
    svg.setAttribute("aria-hidden", "true");
    svg.setAttribute("focusable", "false");

    function add(tag, attributes, className) {
      const node = document.createElementNS(namespace, tag);
      Object.keys(attributes).forEach(function (key) {
        node.setAttribute(key, attributes[key]);
      });
      if (className) {
        node.setAttribute("class", className);
      }
      svg.appendChild(node);
      return node;
    }

    if (type === "connected-nodes") {
      add("path", { d: "M14 54L62 20L111 45L164 14L226 48" }, "");
      [[14, 54], [62, 20], [111, 45], [164, 14], [226, 48]].forEach(function (point) {
        add("circle", { cx: point[0], cy: point[1], r: 3.5 }, "");
      });
      add("path", { d: "M62 20L164 14M111 45L226 48" }, "soft-line");
    } else if (type === "coordinate-grid") {
      add("path", { d: "M20 8V64M60 8V64M100 8V64M140 8V64M180 8V64M220 8V64M12 18H228M12 36H228M12 54H228" }, "soft-line");
      add("path", { d: "M20 54L60 46L100 48L140 27L180 31L220 15" }, "");
      add("circle", { cx: 140, cy: 27, r: 3.5 }, "");
    } else if (type === "line-interpolation") {
      add("path", { d: "M12 57C62 57 70 15 120 15S177 57 228 57" }, "");
      add("path", { d: "M12 46C62 46 72 24 120 24S179 46 228 46M12 35C62 35 74 33 120 33S181 35 228 35" }, "soft-line");
      add("circle", { cx: 120, cy: 15, r: 3.5 }, "");
    } else if (type === "radial-logic") {
      add("circle", { cx: 120, cy: 36, r: 24 }, "");
      add("circle", { cx: 120, cy: 36, r: 4 }, "");
      add("path", { d: "M120 36L120 5M120 36L151 12M120 36L166 36M120 36L151 60M120 36L120 67M120 36L89 60M120 36L74 36M120 36L89 12" }, "soft-line");
      [[120, 5], [151, 12], [166, 36], [151, 60], [120, 67], [89, 60], [74, 36], [89, 12]].forEach(function (point) {
        add("circle", { cx: point[0], cy: point[1], r: 2.5 }, "");
      });
    } else if (type === "stacked-section-lines") {
      add("path", { d: "M14 58H226M24 48H216M36 38H204M50 28H190M69 18H171" }, "");
      add("path", { d: "M14 58L69 18M226 58L171 18" }, "soft-line");
      add("circle", { cx: 120, cy: 18, r: 3 }, "");
    } else {
      add("rect", { x: 24, y: 10, width: 192, height: 52 }, "");
      add("path", { d: "M24 26H216M24 44H216M72 10V62M154 10V62" }, "soft-line");
      add("path", { d: "M82 35H143M82 53H125" }, "");
      add("circle", { cx: 188, cy: 35, r: 4 }, "");
    }

    return svg;
  }

  function renderMethod() {
    const list = byId("method-list");
    const rows = content.method && safeArray(content.method.rows);
    if (!list || !rows || !rows.length) {
      return;
    }

    const fragment = document.createDocumentFragment();
    rows.forEach(function (row) {
      const article = makeElement("article", "method-row");
      article.append(
        makeElement("p", "method-row__number", row.number),
        makeElement("h3", "method-row__title", row.title),
        makeElement("p", "method-row__description", row.description),
        createMethodDiagram(row.diagramType)
      );
      fragment.appendChild(article);
    });
    list.replaceChildren(fragment);
  }

  function renderCV() {
    const cv = content.cv || {};
    const table = byId("cv-table");
    const groups = [
      ["EDUCATION", cv.education, false],
      ["EXPERIENCE", cv.experience, false],
      ["AWARDS", cv.awards, false],
      ["SKILLS", cv.skills, true],
      ["SOFTWARE", cv.software, true]
    ];

    if (table) {
      const fragment = document.createDocumentFragment();
      groups.forEach(function (groupData) {
        const group = makeElement("section", "cv-group");
        group.appendChild(makeElement("h3", "", groupData[0]));
        const list = makeElement(
          "ul",
          "cv-group__entries" + (groupData[2] ? " cv-group__entries--inline" : "")
        );
        safeArray(groupData[1]).forEach(function (entry) {
          list.appendChild(makeElement("li", "", entry));
        });
        group.appendChild(list);
        fragment.appendChild(group);
      });
      table.replaceChildren(fragment);
    }

    applyLink(byId("cv-download-link"), cv.downloadLink);
  }

  function renderContact() {
    const contact = content.contact || {};
    setText("contact-statement", contact.text);

    const links = byId("contact-links");
    if (links && safeArray(contact.links).length) {
      const fragment = document.createDocumentFragment();
      contact.links.forEach(function (linkData) {
        const link = makeElement("a");
        link.href = linkData.href || "#";
        link.append(
          makeElement("span", "", linkData.label),
          makeElement("span", "", linkData.value)
        );
        fragment.appendChild(link);
      });
      links.replaceChildren(fragment);
    }

    if (content.footer && content.footer.text) {
      setText("footer-copy", content.footer.text);
    }
  }

  function scrambleText(element, finalText, duration) {
    if (!element || !finalText) {
      return;
    }

    const previousFrame = scrambleFrames.get(element);
    if (previousFrame) {
      window.cancelAnimationFrame(previousFrame);
    }

    if (reducedMotion.matches) {
      element.textContent = finalText;
      return;
    }

    const characters = "01/\\+—×";
    const start = performance.now();

    function frame(now) {
      const progress = Math.min((now - start) / duration, 1);
      const fixedCount = Math.floor(finalText.length * progress);
      let output = "";

      for (let index = 0; index < finalText.length; index += 1) {
        const character = finalText[index];
        if (index < fixedCount || character === " ") {
          output += character;
        } else {
          output += characters[Math.floor(Math.random() * characters.length)];
        }
      }

      element.textContent = output;
      if (progress < 1) {
        const frameId = window.requestAnimationFrame(frame);
        scrambleFrames.set(element, frameId);
      } else {
        element.textContent = finalText;
        scrambleFrames.delete(element);
      }
    }

    const frameId = window.requestAnimationFrame(frame);
    scrambleFrames.set(element, frameId);
  }

  function bindNavScramble() {
    document.querySelectorAll(".nav-link[data-scramble-text]").forEach(function (link) {
      function run() {
        scrambleText(link, link.dataset.scrambleText, 160);
      }
      link.addEventListener("pointerenter", run);
      link.addEventListener("focus", run);
    });
  }

  function setActiveNav(sectionName) {
    document.querySelectorAll(".nav-link").forEach(function (link) {
      const active = link.getAttribute("href") === "#" + sectionName;
      link.classList.toggle("is-active", active);
      if (active) {
        link.setAttribute("aria-current", "location");
      } else {
        link.removeAttribute("aria-current");
      }
    });
  }

  function observeSections() {
    const sections = Array.from(document.querySelectorAll("[data-nav-section]"));
    if (!sections.length) {
      return;
    }
    let scheduled = false;

    function update() {
      scheduled = false;
      const readingLine = window.scrollY + 56 + window.innerHeight * 0.24;
      let current = "";

      sections.forEach(function (section) {
        if (section.offsetTop <= readingLine) {
          current = section.dataset.navSection;
        }
      });

      setActiveNav(current);
    }

    function requestUpdate() {
      if (!scheduled) {
        scheduled = true;
        window.requestAnimationFrame(update);
      }
    }

    window.addEventListener("scroll", requestUpdate, { passive: true });
    window.addEventListener("resize", requestUpdate);
    update();
  }

  function startClock() {
    const clock = byId("local-time");
    if (!clock || !content.person || !content.person.timezone) {
      return;
    }

    let formatter;
    try {
      formatter = new Intl.DateTimeFormat("en-GB", {
        timeZone: content.person.timezone,
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        hour12: false
      });
    } catch (error) {
      return;
    }

    function update() {
      const now = new Date();
      clock.textContent = formatter.format(now);
      clock.dateTime = now.toISOString();
    }

    update();
    window.setInterval(update, 1000);
  }

  function preventPlaceholderJumps() {
    document.addEventListener("click", function (event) {
      const link = event.target.closest('a[href="#"]');
      if (link) {
        event.preventDefault();
      }
    });
  }

  function runBoot() {
    const boot = byId("boot");
    const screen = byId("boot-screen");
    const target = byId("hero-media-frame");
    const progress = byId("boot-progress");
    let finished = false;

    function finish() {
      if (finished) {
        return;
      }
      finished = true;
      document.body.classList.remove("is-booting", "is-revealing");
      document.body.classList.add("is-ready");
      if (boot) {
        boot.classList.add("is-complete");
        window.setTimeout(function () {
          boot.hidden = true;
        }, 180);
      }
    }

    if (!boot || !screen || reducedMotion.matches) {
      finish();
      return;
    }

    window.requestAnimationFrame(function () {
      boot.classList.add("is-on");
    });

    window.setTimeout(function () {
      boot.classList.add("is-scanning");
    }, 250);

    window.setTimeout(function () {
      boot.classList.remove("is-scanning");
      boot.classList.add("is-reading");

      const bootName = boot.querySelector(".boot__name");
      const bootRole = boot.querySelector(".boot__role");
      scrambleText(bootName, (content.boot && content.boot.name) || "AHMAD ALHADIDII", 380);
      scrambleText(
        bootRole,
        (content.boot && content.boot.role) || "ARCHITECTURE / RESEARCH / COMPUTATIONAL DESIGN",
        460
      );

      const counterStart = performance.now();
      function count(now) {
        const ratio = Math.min((now - counterStart) / 1100, 1);
        if (progress) {
          progress.textContent = String(Math.round(ratio * 100)).padStart(3, "0");
        }
        if (ratio < 1) {
          window.requestAnimationFrame(count);
        }
      }
      window.requestAnimationFrame(count);
    }, 600);

    window.setTimeout(function () {
      document.body.classList.add("is-revealing");
      boot.classList.add("is-docking");

      const contentBlock = screen.querySelector(".boot__content");
      if (contentBlock) {
        contentBlock.style.opacity = "0";
      }

      if (target && typeof screen.animate === "function") {
        const from = screen.getBoundingClientRect();
        const to = target.getBoundingClientRect();
        screen.animate([
          {
            left: from.left + "px",
            top: from.top + "px",
            width: from.width + "px",
            height: from.height + "px",
            transform: "none",
            opacity: 1,
            backgroundColor: "#080808"
          },
          {
            left: to.left + "px",
            top: to.top + "px",
            width: to.width + "px",
            height: to.height + "px",
            transform: "none",
            opacity: 0,
            backgroundColor: "#fafafa"
          }
        ], {
          duration: 600,
          easing: "cubic-bezier(0.65, 0, 0.35, 1)",
          fill: "forwards"
        });
      } else {
        screen.style.opacity = "0";
      }
    }, 1700);

    window.setTimeout(finish, 2300);
    window.setTimeout(finish, 2450);
  }

  function init() {
    updateDocumentMeta();
    renderNavigation();
    renderIdentity();
    renderProjects();
    renderMethod();
    renderCV();
    renderContact();
    bindNavScramble();
    observeSections();
    startClock();
    preventPlaceholderJumps();
    runBoot();
  }

  init();
})();

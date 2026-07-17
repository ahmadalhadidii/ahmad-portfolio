(function () {
  "use strict";

  const root = document.documentElement;
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const scrambleCharacters = "[]{}<>/\\_+-=01";
  const animatedScrambles = new WeakSet();
  const dynamicScrambles = new WeakMap();
  const runningHeaderCopy = {
    index: "PORTFOLIO FIELD / ARCHITECTURE OF ELSEWHERE / 2026",
    profile: "SUBJECT FILE / AHMAD ALHADIDII / PROFILE",
    cv: "CURRICULUM VITAE / INDEXED RECORD / 2021–2026",
    work: "SELECTED WORK / PROJECT ARCHIVE / 01–04",
    visual: "VISUALS / IMAGE / THOUGHT / FIELD",
    contact: "CONTACT RECORD / AS-SALT, JORDAN / 2026",
    manmatic: "MANMATIC / HUMAN–MACHINE COLLABORATION / ACTIVE FIELD"
  };

  let imageObserver = null;
  let scrambleObserver = null;
  let scrollFrame = 0;
  let readingGroups = [];
  let readingObserver = null;
  let activeSectionName = "";
  let runningHeaderElement = null;
  let runningHeaderValue = "";
  let sectionObserver = null;
  let sectionObserverFallback = false;
  let manmaticObserver = null;
  let manmaticTarget = null;
  let manmaticActive = false;
  let manmaticDesiredActive = false;
  let manmaticTransitionElement = null;
  let manmaticTransitionTimer = 0;
  let manmaticCommitTimer = 0;
  let manmaticGlitchTimer = 0;
  let manmaticTransitionToken = 0;
  let projectObserver = null;
  let projectObserverFallback = false;
  let projectRows = [];
  let scrollActiveProject = null;
  let showreelController = null;
  let finishMonitorBoot = null;
  let motionListenerBound = false;
  let revealObserver = null;
  let headingObserver = null;
  let portraitObserver = null;
  let pointerFrame = 0;
  let pointerStates = [];
  let visualSliderController = null;
  const documentScrollLocks = new Set();
  let savedRootOverflow = "";
  let savedBodyOverflow = "";
  let savedRootOverscroll = "";

  function clamp(value, minimum, maximum) {
    return Math.min(maximum, Math.max(minimum, value));
  }

  function elementsWithin(scope, selector) {
    const container = scope || document;
    const elements = Array.from(container.querySelectorAll(selector));
    if (container.nodeType === 1 && container.matches(selector)) {
      elements.unshift(container);
    }
    return elements;
  }

  function element(tagName, className, text) {
    const node = document.createElement(tagName);
    if (className) node.className = className;
    if (text !== undefined && text !== null) node.textContent = text;
    return node;
  }

  function appendEmphasizedText(node, text, emphasis) {
    const value = String(text || "");
    const phrase = String(emphasis || "").trim();
    const index = phrase ? value.indexOf(phrase) : -1;
    if (index < 0) {
      node.textContent = value;
      return node;
    }
    node.append(
      document.createTextNode(value.slice(0, index)),
      element("strong", "", phrase),
      document.createTextNode(value.slice(index + phrase.length))
    );
    return node;
  }

  function initProtectedMedia(scope) {
    const selector = [
      ".project-row__media img",
      ".project-hero__media img",
      ".visual-slide__media img",
      ".visual-record__media img",
      ".showreel img"
    ].join(",");
    elementsWithin(scope || document, selector).forEach(function (image) {
      image.draggable = false;
      if (image.dataset.protectedMedia === "true") return;
      image.dataset.protectedMedia = "true";
      image.addEventListener("dragstart", function (event) { event.preventDefault(); });
      image.addEventListener("contextmenu", function (event) { event.preventDefault(); });
    });
  }

  function setDocumentScrollLock(owner, locked) {
    if (!owner) return;
    if (locked) {
      if (!documentScrollLocks.size) {
        savedRootOverflow = root.style.overflow;
        savedBodyOverflow = document.body.style.overflow;
        savedRootOverscroll = root.style.overscrollBehavior;
      }
      documentScrollLocks.add(owner);
      root.style.overflow = "hidden";
      root.style.overscrollBehavior = "none";
      document.body.style.overflow = "hidden";
      return;
    }

    documentScrollLocks.delete(owner);
    if (documentScrollLocks.size) return;
    root.style.overflow = savedRootOverflow;
    root.style.overscrollBehavior = savedRootOverscroll;
    document.body.style.overflow = savedBodyOverflow;
  }

  function applyImageSource(image, media) {
    if (!image || !media) return;
    const source = media.src || media.image;
    if (source) image.src = source;
    if (media.srcset) image.srcset = media.srcset;
    else image.removeAttribute("srcset");
    if (media.width) image.width = media.width;
    if (media.height) image.height = media.height;
    if (typeof media.alt === "string") image.alt = media.alt;
    if (media.objectPosition) image.style.objectPosition = media.objectPosition;
    else image.style.removeProperty("object-position");
    const fit = media.fit === "cover" ? "cover" : "contain";
    image.style.objectFit = fit;
  }

  function applyMediaClasses(figure, media) {
    if (!figure || !media) return;
    Array.from(figure.classList).forEach(function (className) {
      if (/^media--/.test(className) || /^orientation--/.test(className)) {
        figure.classList.remove(className);
      }
    });
    const fit = media.fit === "cover" ? "cover" : "contain";
    const orientation = media.orientation || "landscape";
    figure.classList.add(`media--${fit}`, `orientation--${orientation}`);
    String(media.mediaClass || "")
      .split(/\s+/)
      .filter(Boolean)
      .forEach(function (className) {
        if (/^[a-z0-9_-]+$/i.test(className)) figure.classList.add(className);
      });
    figure.dataset.mediaFit = fit;
    figure.dataset.orientation = orientation;
    if (media.width && media.height) {
      figure.style.setProperty("--media-ratio", `${media.width} / ${media.height}`);
    }
  }

  function hydrateContentMedia() {
    const content = window.siteContent;
    if (!content) return;

    const portrait = content.person && content.person.portrait;
    const portraitFigure = document.querySelector("[data-pixel-portrait]");
    const portraitImage = portraitFigure && portraitFigure.querySelector("[data-pixel-image]");
    if (portrait && portraitImage) {
      applyImageSource(portraitImage, portrait);
      portraitFigure.dataset.portraitStatus = "ready";
      const caption = portraitFigure.querySelector("figcaption");
      if (caption) {
        const label = caption.querySelector("span:first-child");
        const name = caption.querySelector("strong");
        const note = caption.querySelector("span:last-child");
        if (label && portrait.label) label.textContent = portrait.label;
        if (name && portrait.title) name.textContent = portrait.title;
        if (note && portrait.caption) note.textContent = portrait.caption;
      }
    }

    const projects = Array.isArray(content.projects) ? content.projects : [];
    document.querySelectorAll("[data-project-id]").forEach(function (row, index) {
      const project = projects.find(function (item) {
        return item && item.id === row.dataset.projectId;
      });
      const media = project && (project.preview || project.hero);
      const figure = row.querySelector("[data-project-media]");
      if (!media || !figure) return;
      applyMediaClasses(figure, media);
      const image = figure.querySelector("img");
      applyImageSource(image, media);
      if (image) {
        image.sizes = "(max-width: 560px) calc(100vw - 36px), (max-width: 960px) calc(100vw - 48px), 48vw";
      }
      const caption = figure.querySelector("figcaption");
      if (caption) {
        const parts = caption.querySelectorAll("span");
        if (parts[0]) parts[0].textContent = `FIG. ${String(index + 1).padStart(2, "0")}`;
        if (parts[1] && media.caption) parts[1].textContent = media.caption;
      }
    });
  }

  function finalScrambleText(element) {
    if (!element) return "";
    if (!element.hasAttribute("data-scramble-text")) {
      element.dataset.scrambleText = element.textContent || "";
    }
    return element.dataset.scrambleText || "";
  }

  function prepareScrambleAccessibility(element, finalText) {
    const accessibleOwner = element.closest("a, button, h1, h2, h3, h4");
    if (accessibleOwner && accessibleOwner !== element) {
      if (!accessibleOwner.hasAttribute("aria-label")) {
        const ownerText = (accessibleOwner.textContent || "").trim().replace(/\s+/g, " ");
        const stableText = String(finalText || "").trim().replace(/\s+/g, " ");
        if (ownerText === stableText) {
          accessibleOwner.setAttribute("aria-label", finalText);
        } else {
          return;
        }
      }
      element.setAttribute("aria-hidden", "true");
    } else if (!element.hasAttribute("aria-hidden")) {
      element.setAttribute("aria-label", finalText);
    }
  }

  function settleScramble(element) {
    if (!element) return;
    const finalText = finalScrambleText(element);
    prepareScrambleAccessibility(element, finalText);
    element.textContent = finalText;
  }

  function scrambleElement(element, duration) {
    if (!element || animatedScrambles.has(element)) return;

    const finalText = finalScrambleText(element);
    prepareScrambleAccessibility(element, finalText);
    animatedScrambles.add(element);

    if (reducedMotion.matches || !finalText) {
      element.textContent = finalText;
      return;
    }

    const totalDuration = duration || 620;
    const startedAt = performance.now();

    function update(now) {
      if (reducedMotion.matches) {
        element.textContent = finalText;
        return;
      }

      const progress = clamp((now - startedAt) / totalDuration, 0, 1);
      const resolved = Math.floor(progress * finalText.length * 1.16);
      let output = "";

      for (let index = 0; index < finalText.length; index += 1) {
        const character = finalText[index];
        if (character === " " || index < resolved || progress === 1) {
          output += character;
        } else {
          output += scrambleCharacters[
            Math.floor(Math.random() * scrambleCharacters.length)
          ];
        }
      }

      element.textContent = output;
      if (progress < 1) {
        window.requestAnimationFrame(update);
      } else {
        element.textContent = finalText;
      }
    }

    window.requestAnimationFrame(update);
  }

  function resolveDynamicText(element, value, duration) {
    if (!element || typeof value !== "string") return;
    const owner = element.closest(".running-header");
    if (owner && runningHeaderValue === value && element.textContent === value) return;

    const token = {};
    dynamicScrambles.set(element, token);
    if (owner) {
      runningHeaderValue = value;
      owner.classList.add("is-updating");
    }

    if (reducedMotion.matches || !element.textContent) {
      element.textContent = value;
      if (owner) owner.classList.remove("is-updating");
      return;
    }

    const previous = element.textContent;
    const totalDuration = duration || 360;
    const startedAt = performance.now();

    window.setTimeout(function () {
      if (owner && dynamicScrambles.get(element) === token) {
        owner.classList.remove("is-updating");
      }
    }, 120);

    function update(now) {
      if (dynamicScrambles.get(element) !== token) return;
      if (reducedMotion.matches) {
        element.textContent = value;
        if (owner) owner.classList.remove("is-updating");
        return;
      }

      const progress = clamp((now - startedAt) / totalDuration, 0, 1);
      const length = Math.max(previous.length, value.length);
      const resolved = Math.floor(progress * length * 1.12);
      let output = "";

      for (let index = 0; index < length; index += 1) {
        const targetCharacter = value[index] || "";
        if (targetCharacter === " " || index < resolved || progress === 1) {
          output += targetCharacter;
        } else {
          output += scrambleCharacters[
            Math.floor(Math.random() * scrambleCharacters.length)
          ];
        }
      }

      element.textContent = output;
      if (progress < 1) {
        window.requestAnimationFrame(update);
      } else {
        element.textContent = value;
        if (owner) owner.classList.remove("is-updating");
      }
    }

    window.requestAnimationFrame(update);
  }

  function initScrambleText(scope) {
    const elements = elementsWithin(scope || document, "[data-scramble]").filter(
      function (element) {
        return !element.hasAttribute("data-heading-scramble");
      }
    );
    if (!elements.length) return;

    if (reducedMotion.matches) {
      elements.forEach(settleScramble);
      return;
    }

    if (!("IntersectionObserver" in window)) {
      elements.forEach(function (element) {
        scrambleElement(
          element,
          element.hasAttribute("data-scramble-entry") ? 820 : 560
        );
      });
      return;
    }

    if (!scrambleObserver) {
      scrambleObserver = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (!entry.isIntersecting) return;
            scrambleElement(
              entry.target,
              entry.target.hasAttribute("data-scramble-entry") ? 820 : 560
            );
            scrambleObserver.unobserve(entry.target);
          });
        },
        { threshold: 0.28, rootMargin: "0px 0px -8% 0px" }
      );
    }

    elements.forEach(function (element) {
      if (!animatedScrambles.has(element)) scrambleObserver.observe(element);
    });
  }

  function headingTextElements(container) {
    let selector = "[data-pointer-scan], [data-scramble]";
    if (container.matches(".project-row")) {
      selector = ".project-row__copy h3[data-pointer-scan], .project-row__copy h3 [data-pointer-scan], .project-row__copy h3[data-scramble], .project-row__copy h3 [data-scramble]";
    } else if (container.matches(".section-heading")) {
      selector = "h2 [data-pointer-scan], h2[data-pointer-scan], h2 [data-scramble], h2[data-scramble]";
    } else if (container.matches(".project-header")) {
      selector = "h1 [data-pointer-scan], h1[data-pointer-scan], h1 [data-scramble], h1[data-scramble]";
    }

    return Array.from(new Set(Array.from(container.querySelectorAll(selector))));
  }

  function activateHeading(container) {
    if (!container || container.classList.contains("is-heading-visible")) return;
    container.classList.add("is-heading-visible", "is-heading-scanning");

    const textElements = headingTextElements(container);
    const delay = container.matches(".project-row") ? 150 : 110;
    window.setTimeout(function () {
      textElements.forEach(function (textElement) {
        scrambleElement(
          textElement,
          container.matches(".opening__name") ? 820 : container.matches(".project-row") ? 460 : 620
        );
      });
    }, reducedMotion.matches ? 0 : delay);

    window.setTimeout(function () {
      container.classList.remove("is-heading-scanning");
      container.classList.add("is-heading-settled");
    }, reducedMotion.matches ? 0 : 880);
  }

  function initHeadingMotion(scope) {
    const selectors = [
      ".opening__name",
      ".manifesto__title",
      ".section-heading",
      ".contact__marker",
      ".project-row",
      ".project-header",
      ".closing-identity"
    ];
    const containers = elementsWithin(scope || document, selectors.join(","));
    if (!containers.length) return;

    if (!headingObserver && "IntersectionObserver" in window) {
      headingObserver = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (!entry.isIntersecting) return;
            const isManmaticHeading = Boolean(entry.target.closest("[data-manmatic-system]"));
            if (isManmaticHeading && !manmaticActive) return;
            activateHeading(entry.target);
            headingObserver.unobserve(entry.target);
          });
        },
        { threshold: 0.24, rootMargin: "0px 0px -8% 0px" }
      );
    }

    containers.forEach(function (container) {
      if (container.dataset.headingPrepared === "true") return;
      container.dataset.headingPrepared = "true";
      container.classList.add("heading-motion");

      headingTextElements(container).forEach(function (textElement) {
        textElement.classList.add("heading-motion__text");
        textElement.setAttribute("data-heading-scramble", "");
        textElement.setAttribute("data-scramble", "");
      });

      const isManmaticHeading = Boolean(container.closest("[data-manmatic-system]"));
      const bounds = container.getBoundingClientRect();
      if (
        reducedMotion.matches ||
        !headingObserver ||
        (!isManmaticHeading && bounds.top < window.innerHeight * 0.94 && bounds.bottom > 0)
      ) {
        if (reducedMotion.matches) {
          activateHeading(container);
        } else {
          window.requestAnimationFrame(function () {
            activateHeading(container);
          });
        }
      } else {
        headingObserver.observe(container);
      }
    });
  }

  function initMonitorBoot() {
    const loader = document.getElementById("loader");
    if (!loader || !root.classList.contains("loader-pending")) {
      if (loader) {
        loader.hidden = true;
        loader.setAttribute("aria-hidden", "true");
      }
      root.classList.remove("loader-pending");
      root.classList.add("loader-complete");
      return Promise.resolve();
    }

    const progressPrimary = document.getElementById("loader-progress");
    const progressSecondary = document.getElementById("loader-progress-secondary");
    const progressBar = document.getElementById("loader-progress-bar");
    const state = document.getElementById("loader-state");
    const phase = document.getElementById("loader-phase");
    const frame = document.getElementById("loader-frame");
    const signal = document.getElementById("loader-signal");
    const activeBinary = document.getElementById("loader-active-binary");
    const announcement = document.getElementById("loader-announcement");
    const loaderName = document.getElementById("loader-name");
    const preview = loader.querySelector("[data-loader-preview]");
    const projectLoaderData = window.__portfolioDetailLoaderData || window.__portfolioProjectLoaderData || null;
    const isProjectPage = loader.classList.contains("loader--project");
    const isProjectLoader = isProjectPage && projectLoaderData;

    if (isProjectLoader) {
      const isDarkLoader = projectLoaderData.theme === "manmatic";
      loader.classList.toggle("loader--project-dark", isDarkLoader);
      loader.classList.toggle("loader--project-light", !isDarkLoader);
      if (loaderName) loaderName.textContent = projectLoaderData.title;
      const kicker = loader.querySelector("[data-project-loader-kicker]");
      const caption = loader.querySelector("[data-project-loader-caption]");
      const type = loader.querySelector("[data-project-loader-type]");
      const statusType = loader.querySelector("[data-project-loader-status-type]");
      const subtitle = loader.querySelector("[data-project-loader-subtitle]");
      const year = loader.querySelector("[data-project-loader-year]");
      if (kicker) {
        kicker.textContent = projectLoaderData.kicker || `PROJECT FILE ${projectLoaderData.number || ""}`.trim();
      }
      if (caption) caption.textContent = `${projectLoaderData.title} / ${projectLoaderData.year}`;
      if (type) type.textContent = projectLoaderData.type;
      if (statusType) statusType.textContent = projectLoaderData.type;
      if (subtitle) subtitle.textContent = projectLoaderData.subtitle || projectLoaderData.type;
      if (year) {
        year.textContent = [projectLoaderData.location, projectLoaderData.year]
          .filter(Boolean)
          .join(" / ");
      }
      if (preview) {
        const markImageMissing = function () {
          loader.classList.add("is-image-missing");
          preview.removeAttribute("srcset");
          preview.removeAttribute("src");
        };
        preview.addEventListener("error", markImageMissing, { once: true });
        if (projectLoaderData.hasImage === false || !projectLoaderData.image) {
          markImageMissing();
        } else {
          preview.src = projectLoaderData.image;
        }
        if (projectLoaderData.srcset) preview.srcset = projectLoaderData.srcset;
        else preview.removeAttribute("srcset");
        if (projectLoaderData.objectPosition) {
          preview.style.objectPosition = projectLoaderData.objectPosition;
        }
      }
    }
    const startedAt = performance.now();
    const minimumDuration = isProjectPage
      ? reducedMotion.matches ? 70 : 520
      : reducedMotion.matches ? 180 : 1280;
    const maximumDuration = isProjectPage
      ? reducedMotion.matches ? 150 : 820
      : reducedMotion.matches ? 340 : 2100;
    const exitDuration = isProjectPage
      ? reducedMotion.matches ? 20 : 200
      : reducedMotion.matches ? 30 : 380;
    const timers = new Set();
    let frameRequest = 0;
    let assetsReady = false;
    let exitStarted = false;
    let settled = false;
    let resolveBoot;
    let currentProgress = 0;
    let signalStage = 0;
    const blackFlashPoints = [35, 82];
    const completedBlackFlashes = new Set();

    function schedule(callback, delay) {
      const timer = window.setTimeout(function () {
        timers.delete(timer);
        callback();
      }, delay);
      timers.add(timer);
      return timer;
    }

    function clearScheduled() {
      timers.forEach(function (timer) {
        window.clearTimeout(timer);
      });
      timers.clear();
    }

    function waitForPreview() {
      if (!preview || (preview.complete && preview.naturalWidth > 0)) {
        return Promise.resolve();
      }

      return new Promise(function (resolve) {
        let complete = false;
        function finish() {
          if (complete) return;
          complete = true;
          preview.removeEventListener("load", finish);
          preview.removeEventListener("error", finish);
          resolve();
        }
        preview.addEventListener("load", finish, { once: true });
        preview.addEventListener("error", finish, { once: true });
        schedule(finish, isProjectPage ? 720 : 1050);
        if (typeof preview.decode === "function") {
          preview.decode().then(finish, function () {});
        }
      });
    }

    function waitForFonts() {
      if (!document.fonts || !document.fonts.ready) return Promise.resolve();
      return Promise.race([
        document.fonts.ready.catch(function () {}),
        new Promise(function (resolve) {
          schedule(resolve, isProjectPage ? 720 : 1050);
        })
      ]);
    }

    function setProgress(value) {
      currentProgress = clamp(Math.round(value), currentProgress, 100);
      const formatted = String(currentProgress).padStart(3, "0");
      const ratio = currentProgress / 100;
      loader.style.setProperty("--loader-ratio", ratio.toFixed(3));
      loader.style.setProperty("--project-reveal", `${((1 - ratio) * 100).toFixed(2)}%`);
      loader.style.setProperty("--project-band-inset", `${((1 - ratio) * 46).toFixed(2)}%`);
      loader.style.setProperty("--loader-progress", String(currentProgress));
      if (progressPrimary) progressPrimary.textContent = formatted;
      if (progressSecondary) progressSecondary.textContent = formatted;
      if (progressBar) progressBar.style.transform = `scaleX(${ratio.toFixed(3)})`;
      if (frame) {
        const frameValue = clamp(Math.ceil(Math.max(currentProgress, 1) / 17), 1, 6);
        frame.textContent = `${String(frameValue).padStart(2, "0")} / 06`;
      }
      if (signal) signal.textContent = (currentProgress * 17.311).toFixed(3).padStart(7, "0");
      if (activeBinary) {
        const binaryValue = currentProgress.toString(2).padStart(8, "0");
        activeBinary.textContent = `${binaryValue} / ${binaryValue.split("").reverse().join("")}`;
      }

      let stateText = "SYSTEM INITIALIZATION";
      let phaseText = "ARCHIVE ACCESS";
      if (currentProgress >= 12) {
        stateText = "DATA ASSEMBLY";
        phaseText = "SIGNAL SYNC";
      }
      if (currentProgress >= 35) {
        stateText = "IMAGE BUFFER";
        phaseText = "VISUAL FIELD";
      }
      if (currentProgress >= 68) {
        stateText = "VISUAL FIELD";
        phaseText = "FRAME ALIGNMENT";
      }
      if (currentProgress >= 92) {
        stateText = "SIGNAL SYNC";
        phaseText = "FIELD CHECK";
      }
      if (currentProgress >= 100) {
        stateText = "FIELD ACTIVE";
        phaseText = "SYSTEM READY";
      }
      if (state) state.textContent = stateText;
      if (phase) phase.textContent = phaseText;

      if (isProjectPage) {
        if (state) {
          state.textContent = currentProgress >= 100
            ? "PROJECT OPEN"
            : currentProgress >= 68
              ? "HERO ALIGNMENT"
              : currentProgress >= 35
                ? "IMAGE ASSEMBLY"
                : "FILE INDEXING";
        }
        if (phase) {
          phase.textContent = currentProgress >= 100
            ? "FILE READY"
            : currentProgress >= 68
              ? "OPENING PROJECT"
              : "FILE ACCESS";
        }
      }

      if (!isProjectLoader && !reducedMotion.matches) {
        blackFlashPoints.forEach(function (point) {
          if (currentProgress < point || completedBlackFlashes.has(point)) return;
          completedBlackFlashes.add(point);
          loader.classList.add("is-black-flash");
          schedule(function () {
            loader.classList.remove("is-black-flash");
          }, 90);
        });
      }

      const nextSignalStage = currentProgress >= 100
        ? 4
        : currentProgress >= 91
          ? 3
          : currentProgress >= 61
            ? 2
            : currentProgress >= 26
              ? 1
              : 0;
      if (nextSignalStage !== signalStage) {
        signalStage = nextSignalStage;
        const shouldGlitch = isProjectPage ? signalStage === 2 : signalStage > 0;
        if (!reducedMotion.matches && shouldGlitch) {
          loader.classList.remove("is-glitching");
          void loader.offsetWidth;
          loader.classList.add("is-glitching");
          schedule(function () {
            loader.classList.remove("is-glitching");
          }, 210);
        }
      }
    }

    function targetProgress(elapsed) {
      if (reducedMotion.matches) {
        return clamp((elapsed / minimumDuration) * 100, 0, 100);
      }
      if (isProjectPage) {
        if (elapsed < 140) return (elapsed / 140) * 18;
        if (elapsed < 330) return 18 + ((elapsed - 140) / 190) * 30;
        if (elapsed < 570) return 48 + ((elapsed - 330) / 240) * 30;
        if (!assetsReady) return 78 + clamp((elapsed - 570) / 430, 0, 1) * 14;
        return 78 + clamp((elapsed - 570) / 180, 0, 1) * 22;
      }
      if (elapsed < 280) return (elapsed / 280) * 12;
      if (elapsed < 700) return 12 + ((elapsed - 280) / 420) * 19;
      if (elapsed < 1120) return 31 + ((elapsed - 700) / 420) * 16;
      if (elapsed < 1480) return 47 + ((elapsed - 1120) / 360) * 21;
      if (elapsed < 1780) return 68 + ((elapsed - 1480) / 300) * 16;
      if (!assetsReady) return 84 + clamp((elapsed - 1780) / 900, 0, 1) * 10;
      return 84 + clamp((elapsed - 1780) / 300, 0, 1) * 16;
    }

    function settle() {
      if (settled) return;
      settled = true;
      if (frameRequest) window.cancelAnimationFrame(frameRequest);
      clearScheduled();
      if (window.__portfolioLoaderFallback) {
        window.clearTimeout(window.__portfolioLoaderFallback);
        window.__portfolioLoaderFallback = 0;
      }
      loader.hidden = true;
      loader.setAttribute("aria-hidden", "true");
      const binaryLayer = loader.querySelector(".loader__binary");
      if (binaryLayer) binaryLayer.remove();
      finishMonitorBoot = null;
      document.dispatchEvent(new CustomEvent("portfolio:ready"));
      if (resolveBoot) resolveBoot();
    }

    function beginExit() {
      if (exitStarted || settled) return;
      exitStarted = true;
      setProgress(100);
      if (announcement) {
        announcement.textContent = isProjectLoader
          ? `${projectLoaderData.title} project file open.`
          : "Portfolio field active.";
      }
      loader.classList.add("is-ready");
      schedule(function () {
        loader.classList.add("is-complete");
        loader.setAttribute("aria-hidden", "true");
        root.classList.remove("loader-pending");
        root.classList.add("loader-complete");
        schedule(settle, exitDuration);
      }, reducedMotion.matches ? 20 : 100);
    }

    function update(now) {
      if (settled || exitStarted) return;
      const elapsed = now - startedAt;
      setProgress(targetProgress(elapsed));
      if (
        currentProgress >= 100 &&
        elapsed >= minimumDuration &&
        (assetsReady || elapsed >= maximumDuration)
      ) {
        beginExit();
        return;
      }
      if (elapsed >= maximumDuration) {
        beginExit();
        return;
      }
      frameRequest = window.requestAnimationFrame(update);
    }

    finishMonitorBoot = beginExit;
    scrambleElement(loaderName, reducedMotion.matches ? 1 : isProjectLoader ? 260 : 640);
    Promise.all([waitForPreview(), waitForFonts()]).then(function () {
      assetsReady = true;
    });

    return new Promise(function (resolve) {
      resolveBoot = resolve;
      setProgress(0);
      frameRequest = window.requestAnimationFrame(update);
      schedule(beginExit, maximumDuration + 40);
    });
  }

  function initFallbackSlideshow(showreel, onFrameChange) {
    const slides = showreel
      ? Array.from(showreel.querySelectorAll("[data-showreel-slide]"))
      : [];
    const requestedDelay = showreel
      ? Number.parseInt(showreel.dataset.showreelDuration || "", 10)
      : NaN;
    const delay = clamp(Number.isFinite(requestedDelay) ? requestedDelay : 3200, 2500, 4000);
    let index = Math.max(
      0,
      slides.findIndex(function (slide) {
        return slide.classList.contains("is-active");
      })
    );
    let timer = 0;
    let transitionTimer = 0;
    let running = false;

    function setFrame(nextIndex, animate) {
      if (!slides.length) return;
      const resolvedIndex = (nextIndex + slides.length) % slides.length;
      if (animate && resolvedIndex !== index && !reducedMotion.matches) {
        if (transitionTimer) window.clearTimeout(transitionTimer);
        showreel.classList.remove("is-switching");
        void showreel.offsetWidth;
        showreel.classList.add("is-switching");
        transitionTimer = window.setTimeout(function () {
          showreel.classList.remove("is-switching");
          transitionTimer = 0;
        }, 230);
      }
      index = resolvedIndex;

      slides.forEach(function (slide, slideIndex) {
        const active = slideIndex === index;
        slide.classList.toggle("is-active", active);
        slide.setAttribute("aria-hidden", active ? "false" : "true");
      });

      showreel.dataset.activeFrame = String(index + 1).padStart(2, "0");
      if (typeof onFrameChange === "function") {
        onFrameChange(index, slides[index], slides.length);
      }
    }

    function clearTimer() {
      if (!timer) return;
      window.clearTimeout(timer);
      timer = 0;
    }

    function schedule() {
      clearTimer();
      if (!running || reducedMotion.matches || slides.length < 2) return;
      timer = window.setTimeout(function () {
        setFrame(index + 1, true);
        schedule();
      }, delay);
    }

    function play() {
      if (reducedMotion.matches || slides.length < 2) {
        pause();
        return;
      }
      running = true;
      showreel.dataset.playing = "true";
      schedule();
    }

    function pause() {
      running = false;
      if (showreel) showreel.dataset.playing = "false";
      clearTimer();
    }

    function reset() {
      pause();
      setFrame(0, false);
    }

    slides.forEach(function (slide) {
      slide.querySelectorAll("img").forEach(function (image) {
        image.addEventListener(
          "error",
          function () {
            slide.classList.add("is-media-missing");
          },
          { once: true }
        );
        if (image.complete && image.naturalWidth === 0) {
          slide.classList.add("is-media-missing");
        }
      });
    });

    setFrame(index, false);

    return {
      play: play,
      pause: pause,
      reset: reset,
      setFrame: setFrame,
      isPlaying: function () {
        return running;
      },
      frame: function () {
        return index;
      },
      count: function () {
        return slides.length;
      }
    };
  }

  function initShowreel() {
    const monitor =
      document.querySelector("[data-broadcast-monitor]") ||
      document.getElementById("broadcast-monitor") ||
      document.querySelector(".broadcast-monitor");
    const showreel =
      document.querySelector("[data-showreel-fallback]") ||
      document.getElementById("showreel") ||
      (monitor && monitor.querySelector(".showreel"));

    if (!monitor || !showreel || showreel.dataset.showreelInitialized === "true") {
      return null;
    }

    showreel.dataset.showreelInitialized = "true";
    const frameReadout = document.getElementById("showreel-frame");
    const statusReadout = document.getElementById("showreel-status");
    const signalReadout = document.getElementById("showreel-signal");
    const toggle =
      document.querySelector("[data-showreel-toggle]") ||
      document.getElementById("showreel-toggle");
    const video =
      monitor.querySelector("[data-showreel-video]") ||
      monitor.querySelector("video.showreel__video") ||
      monitor.querySelector("video");
    let mode = "fallback";
    let userPaused = false;
    let pageSuspended = document.hidden;
    let monitorSuspended = false;
    let monitorVisibilityObserver = null;
    let videoAttempt = 0;

    const fallback = initFallbackSlideshow(
      showreel,
      function (index, slide) {
        const frameValue =
          (slide && slide.dataset.frame) || String(index + 1).padStart(2, "0");
        if (frameReadout) frameReadout.textContent = frameValue;
        if (signalReadout) {
          signalReadout.textContent = ((index + 1) * 13.7).toFixed(1).padStart(5, "0");
        }
      }
    );

    function isSuspended() {
      return pageSuspended || monitorSuspended;
    }

    function updateSuspendedClass() {
      monitor.classList.toggle("is-suspended", isSuspended());
    }

    function isPlaying() {
      if (reducedMotion.matches || isSuspended()) return false;
      if (mode === "video" && video) return !video.paused && !video.ended;
      return fallback.isPlaying();
    }

    function updateControls() {
      const playing = isPlaying();
      if (statusReadout) {
        statusReadout.textContent = reducedMotion.matches
          ? "STATIC / REDUCED MOTION"
          : playing
            ? "PLAYING / MUTED"
            : "PAUSED / MUTED";
      }

      if (!toggle) return;
      if (reducedMotion.matches) {
        toggle.disabled = true;
        toggle.setAttribute("aria-pressed", "true");
        toggle.setAttribute(
          "aria-label",
          "Architectural showreel is static because reduced motion is enabled"
        );
        toggle.textContent = "STATIC FRAME";
        return;
      }

      toggle.disabled = false;
      toggle.setAttribute("aria-pressed", playing ? "false" : "true");
      toggle.setAttribute(
        "aria-label",
        playing
          ? "Pause the architectural showreel"
          : "Play the architectural showreel"
      );
      toggle.textContent = playing ? "PAUSE SIGNAL" : "PLAY SIGNAL";
    }

    function activateFallback() {
      videoAttempt += 1;
      mode = "fallback";
      monitor.classList.remove("is-video-active");
      monitor.classList.add("is-fallback-active");
      if (video && !video.paused) video.pause();
      if (!userPaused && !isSuspended() && !reducedMotion.matches) {
        fallback.play();
      } else {
        fallback.pause();
      }
      updateControls();
    }

    function activateVideo() {
      if (!video || reducedMotion.matches || userPaused || isSuspended()) return;
      const attempt = ++videoAttempt;
      video.muted = true;
      video.defaultMuted = true;
      video.loop = true;
      video.playsInline = true;
      video.controls = false;
      video.setAttribute("muted", "");
      video.setAttribute("playsinline", "");
      video.setAttribute("aria-hidden", "true");
      video.tabIndex = -1;

      let playback;
      try {
        playback = video.play();
      } catch (error) {
        activateFallback();
        return;
      }

      Promise.resolve(playback).then(
        function () {
          if (attempt !== videoAttempt || video.paused) return;
          mode = "video";
          fallback.pause();
          monitor.classList.add("is-video-active");
          monitor.classList.remove("is-fallback-active");
          updateControls();
        },
        function () {
          if (attempt === videoAttempt) activateFallback();
        }
      );
    }

    function pause(userAction) {
      if (userAction) userPaused = true;
      videoAttempt += 1;
      fallback.pause();
      if (video && !video.paused) video.pause();
      updateControls();
    }

    function play(userAction) {
      if (userAction) userPaused = false;
      if (reducedMotion.matches || isSuspended()) {
        updateControls();
        return;
      }

      if (mode === "video" && video) {
        activateVideo();
      } else {
        fallback.play();
        updateControls();
        if (video && video.readyState >= 2 && !video.error) activateVideo();
      }
    }

    function handleMotionChange() {
      if (reducedMotion.matches) {
        pause(false);
        fallback.reset();
        if (video) {
          try {
            video.currentTime = 0;
          } catch (error) {
            // Some streaming media does not expose a seekable range yet.
          }
        }
      } else if (!userPaused && !isSuspended()) {
        play(false);
      }
      updateControls();
    }

    if (toggle) {
      toggle.addEventListener("click", function () {
        if (isPlaying()) {
          pause(true);
        } else {
          play(true);
        }
      });
    }

    if (video) {
      video.addEventListener("canplay", activateVideo);
      video.addEventListener("loadeddata", activateVideo);
      video.addEventListener("error", activateFallback);
      video.addEventListener("abort", activateFallback);
      video.addEventListener("pause", updateControls);
      video.addEventListener("play", updateControls);
      video.addEventListener("timeupdate", function () {
        if (
          mode !== "video" ||
          !frameReadout ||
          !Number.isFinite(video.duration) ||
          video.duration <= 0
        ) {
          return;
        }
        const count = Math.max(fallback.count(), 1);
        const frame = clamp(
          Math.floor((video.currentTime / video.duration) * count) + 1,
          1,
          count
        );
        frameReadout.textContent = String(frame).padStart(2, "0");
      });
    }

    document.addEventListener("visibilitychange", function () {
      pageSuspended = document.hidden;
      updateSuspendedClass();
      if (pageSuspended) {
        pause(false);
      } else if (!userPaused && !reducedMotion.matches && !monitorSuspended) {
        play(false);
      }
    });

    if ("IntersectionObserver" in window) {
      monitorVisibilityObserver = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (entry.target !== monitor) return;
            monitorSuspended = !entry.isIntersecting;
            updateSuspendedClass();
            if (monitorSuspended) {
              pause(false);
            } else if (!userPaused && !pageSuspended && !reducedMotion.matches) {
              play(false);
            }
          });
        },
        { threshold: 0, rootMargin: "220px 0px 220px 0px" }
      );
      monitorVisibilityObserver.observe(monitor);
      window.addEventListener(
        "pagehide",
        function () {
          if (monitorVisibilityObserver) monitorVisibilityObserver.disconnect();
        },
        { once: true }
      );
    }

    activateFallback();
    updateSuspendedClass();
    if (video && video.error) {
      activateFallback();
    } else if (video && video.readyState >= 2) {
      activateVideo();
    }
    handleMotionChange();

    return {
      pause: function () {
        pause(true);
      },
      play: function () {
        play(true);
      },
      handleMotionChange: handleMotionChange,
      isPlaying: isPlaying
    };
  }

  function updatePointerScanning() {
    pointerFrame = 0;
    let needsAnotherFrame = false;

    pointerStates.forEach(function (state) {
      const deltaX = state.targetX - state.currentX;
      const deltaY = state.targetY - state.currentY;
      state.currentX += deltaX * 0.18;
      state.currentY += deltaY * 0.18;
      state.element.style.setProperty("--pointer-x", `${state.currentX.toFixed(2)}px`);
      state.element.style.setProperty("--pointer-y", `${state.currentY.toFixed(2)}px`);
      if (Math.abs(deltaX) > 0.2 || Math.abs(deltaY) > 0.2) {
        needsAnotherFrame = true;
      }
    });

    if (needsAnotherFrame && !reducedMotion.matches) {
      pointerFrame = window.requestAnimationFrame(updatePointerScanning);
    }
  }

  function requestPointerScanning() {
    if (!pointerFrame && !reducedMotion.matches) {
      pointerFrame = window.requestAnimationFrame(updatePointerScanning);
    }
  }

  function initPointerScanning(scope) {
    const elements = elementsWithin(scope || document, "[data-pointer-scan]");
    elements.forEach(function (element) {
      if (element.dataset.pointerPrepared === "true") return;
      element.dataset.pointerPrepared = "true";
      const bounds = element.getBoundingClientRect();
      const state = {
        element: element,
        currentX: Math.max(bounds.width / 2, 0),
        currentY: Math.max(bounds.height / 2, 0),
        targetX: Math.max(bounds.width / 2, 0),
        targetY: Math.max(bounds.height / 2, 0),
        tapTimer: 0
      };
      pointerStates.push(state);

      function updateTarget(event) {
        if (reducedMotion.matches) return;
        const rect = element.getBoundingClientRect();
        state.targetX = clamp(event.clientX - rect.left, 0, rect.width);
        state.targetY = clamp(event.clientY - rect.top, 0, rect.height);
        requestPointerScanning();
      }

      element.addEventListener("pointerenter", function (event) {
        if (event.pointerType === "touch") return;
        element.classList.add("is-pointer-active");
        updateTarget(event);
      });
      element.addEventListener("pointermove", function (event) {
        if (event.pointerType === "touch") return;
        updateTarget(event);
      });
      element.addEventListener("pointerleave", function () {
        element.classList.remove("is-pointer-active");
      });
      element.addEventListener("pointerdown", function (event) {
        if (event.pointerType !== "touch" || reducedMotion.matches) return;
        updateTarget(event);
        element.classList.add("is-pointer-tapped");
        if (state.tapTimer) window.clearTimeout(state.tapTimer);
        state.tapTimer = window.setTimeout(function () {
          element.classList.remove("is-pointer-tapped");
          state.tapTimer = 0;
        }, 460);
      });
    });
    requestPointerScanning();
  }

  function initSectionReveals(scope) {
    const container = scope || document;
    const selectors = [
      ".profile__layout",
      ".cv-group",
      ".support-group",
      ".contact__intro",
      ".contact__band"
    ];
    const elements = elementsWithin(container, selectors.join(","));
    if (!elements.length) return;

    elements.forEach(function (element, index) {
      if (element.dataset.sectionRevealPrepared === "true") return;
      element.dataset.sectionRevealPrepared = "true";
      element.classList.add("reveal-item", "is-reveal-ready");
      element.classList.add(index % 2 === 0 ? "reveal-from-left" : "reveal-from-right");
      element.classList.add("is-revealed");
    });
  }

  function assemblePortrait(figure) {
    if (!figure || figure.classList.contains("is-assembled")) return;
    figure.classList.add("is-assembling");
    window.requestAnimationFrame(function () {
      figure.classList.add("is-assembled");
    });
    window.setTimeout(function () {
      figure.classList.remove("is-assembling");
      figure.classList.add("is-assembly-complete");
    }, reducedMotion.matches ? 0 : 1180);
  }

  function initPixelPortrait(scope) {
    const figures = elementsWithin(scope || document, "[data-pixel-portrait]");
    if (!figures.length) return;

    if (!portraitObserver && "IntersectionObserver" in window) {
      portraitObserver = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (!entry.isIntersecting) return;
            assemblePortrait(entry.target);
            portraitObserver.unobserve(entry.target);
          });
        },
        { threshold: 0.24, rootMargin: "0px 0px -6% 0px" }
      );
    }

    figures.forEach(function (figure) {
      if (figure.dataset.pixelPrepared === "true") return;
      figure.dataset.pixelPrepared = "true";
      const grid = figure.querySelector("[data-pixel-grid]");
      if (grid) {
        grid.textContent = "";
        for (let index = 0; index < 48; index += 1) {
          const cell = element("span", "pixel-portrait__cell");
          const sequence = (index * 29) % 48;
          cell.style.setProperty("--pixel-delay", `${sequence * 13}ms`);
          cell.style.setProperty("--pixel-tone", String(196 + ((index * 17) % 48)));
          grid.appendChild(cell);
        }
      }

      const bounds = figure.getBoundingClientRect();
      if (
        reducedMotion.matches ||
        !portraitObserver ||
        (bounds.top < window.innerHeight * 0.92 && bounds.bottom > 0)
      ) {
        assemblePortrait(figure);
      } else {
        portraitObserver.observe(figure);
      }
    });
  }

  function initVisuals() {
    const slider = document.querySelector("[data-visual-slider]");
    const content = window.siteContent;
    const studies = content && Array.isArray(content.visuals)
      ? content.visuals.filter(function (study) {
          return study && typeof study.title === "string" && Boolean(study.src || study.image);
        })
      : [];
    if (!slider || !studies.length || slider.dataset.visualInitialized === "true") {
      return null;
    }

    const track = slider.querySelector("[data-visual-track]");
    const viewport = slider.querySelector("[data-visual-viewport]");
    const previous = slider.querySelector("[data-visual-prev]");
    const next = slider.querySelector("[data-visual-next]");
    const current = slider.querySelector("[data-visual-current]");
    const total = slider.querySelector("[data-visual-total]");
    const progress = slider.querySelector("[data-visual-progress]");
    if (!track || !viewport || !previous || !next) return null;

    slider.dataset.visualInitialized = "true";
    track.textContent = "";
    let index = 0;
    let signalTimer = 0;
    let pointerId = null;
    let startX = 0;
    let startY = 0;
    let lastX = 0;
    let startedAt = 0;
    let gestureDirection = "";
    let resizeTimer = 0;

    function addMetadata(list, label, value) {
      if (!value) return;
      const row = element("div");
      row.append(element("dt", "", label), element("dd", "", value));
      list.appendChild(row);
    }

    const slides = studies.map(function (study, slideIndex) {
      const slide = element("article", "visual-slide");
      if (study.accent) slide.style.setProperty("--visual-accent", study.accent);
      slide.setAttribute("role", "group");
      slide.setAttribute("aria-roledescription", "slide");
      slide.setAttribute(
        "aria-label",
        `${slideIndex + 1} of ${studies.length}: ${study.title}`
      );

      const copy = element("div", "visual-slide__copy");
      copy.appendChild(
        element(
          "p",
          "visual-slide__index",
          `VISUAL ${study.index || String(slideIndex + 1).padStart(2, "0")} / ${study.category || "VISUAL WORK"}`
        )
      );
      const title = element("h3", "pointer-scan", study.title);
      title.setAttribute("data-pointer-scan", "");
      title.setAttribute("data-pointer-text", study.title);
      const description = appendEmphasizedText(
        element("p"),
        study.description || study.text || "",
        study.emphasis
      );
      copy.append(title, description);
      const metadata = element("dl");
      addMetadata(metadata, "RELATED FIELD", study.relatedProject || study.project);
      addMetadata(metadata, "YEAR", study.year);
      addMetadata(metadata, "CATEGORY", study.category);
      addMetadata(metadata, "AI ROLE", study.aiRole || "PENDING VERIFICATION");
      copy.appendChild(metadata);
      const openButton = element("a", "visual-slide__open", "OPEN VISUAL ");
      openButton.href = `/visuals/${encodeURIComponent(study.slug || study.id || String(slideIndex + 1))}/`;
      openButton.setAttribute("aria-label", `Open visual: ${study.title}`);
      const openIcon = element("span", "", "↗");
      openIcon.setAttribute("aria-hidden", "true");
      openButton.appendChild(openIcon);
      copy.appendChild(openButton);

      const figure = element("figure", "visual-slide__media");
      applyMediaClasses(figure, study);
      const imageFrame = element("div", "visual-slide__image-frame image-reveal");
      imageFrame.setAttribute("data-image-reveal", "");
      imageFrame.dataset.revealVariant = study.reveal || ["horizontal", "split", "vertical"][slideIndex % 3];
      const image = element("img");
      applyImageSource(image, study);
      image.sizes = "(max-width: 700px) calc(100vw - 36px), (max-width: 960px) calc(100vw - 48px), min(930px, 62vw)";
      image.loading = "lazy";
      image.decoding = "async";
      image.draggable = false;
      image.addEventListener(
        "error",
        function () {
          figure.classList.add("is-media-missing");
        },
        { once: true }
      );
      const scan = element("span", "visual-slide__scan");
      scan.setAttribute("aria-hidden", "true");
      if (study.mobileSrc) {
        const picture = element("picture", "responsive-picture");
        const mobileSource = element("source");
        mobileSource.media = "(max-width: 767px)";
        mobileSource.srcset = study.mobileSrc;
        picture.append(mobileSource, image);
        imageFrame.append(picture, scan);
      } else {
        imageFrame.append(image, scan);
      }
      figure.append(
        imageFrame,
        element("figcaption", "", study.caption || "LOCAL ARCHIVE VISUAL")
      );
      slide.append(copy, figure);
      track.appendChild(slide);
      return slide;
    });

    function syncViewportHeight() {
      const activeSlide = slides[index];
      if (!activeSlide) return;
      const height = Math.ceil(activeSlide.getBoundingClientRect().height);
      if (height > 0) viewport.style.height = `${height}px`;
    }

    function normalizeIndex(value) {
      return (value + slides.length) % slides.length;
    }

    function signalSwitch() {
      if (reducedMotion.matches) return;
      if (signalTimer) window.clearTimeout(signalTimer);
      slider.classList.remove("is-switching");
      void slider.offsetWidth;
      slider.classList.add("is-switching");
      signalTimer = window.setTimeout(function () {
        slider.classList.remove("is-switching");
        signalTimer = 0;
      }, 240);
    }

    function setIndex(nextIndex, announce) {
      const resolved = normalizeIndex(nextIndex);
      if (resolved !== index) signalSwitch();
      index = resolved;
      slider.style.setProperty("--slider-index", String(index));
      slider.style.setProperty("--slider-offset", `${index * -100}%`);
      slider.style.setProperty("--slider-drag", "0px");
      slider.style.setProperty(
        "--visual-progress",
        String(((index + 1) / slides.length).toFixed(4))
      );
      slides.forEach(function (slide, slideIndex) {
        const active = slideIndex === index;
        slide.classList.toggle("is-active", active);
        slide.setAttribute("aria-hidden", active ? "false" : "true");
        const imageFrame = slide.querySelector("[data-image-reveal]");
        if (active && imageFrame) imageFrame.classList.add("is-visible");
      });
      if (current) current.textContent = String(index + 1).padStart(2, "0");
      if (total) total.textContent = String(slides.length).padStart(2, "0");
      if (progress) {
        progress.style.transform = `scaleX(${((index + 1) / slides.length).toFixed(4)})`;
      }
      if (announce) slider.dataset.visualActive = String(index + 1).padStart(2, "0");
      window.requestAnimationFrame(syncViewportHeight);
    }

    function resetGesture() {
      pointerId = null;
      gestureDirection = "";
      slider.classList.remove("is-dragging");
      slider.style.setProperty("--slider-drag", "0px");
    }

    function finishGesture(event) {
      if (pointerId === null || (event && event.pointerId !== pointerId)) return;
      const distance = lastX - startX;
      const elapsed = Math.max(performance.now() - startedAt, 1);
      const velocity = distance / elapsed;
      if (gestureDirection === "horizontal" && (Math.abs(distance) > 44 || Math.abs(velocity) > 0.45)) {
        setIndex(index + (distance < 0 ? 1 : -1), true);
      } else {
        setIndex(index, false);
      }
      resetGesture();
    }

    previous.addEventListener("click", function () {
      setIndex(index - 1, true);
    });
    next.addEventListener("click", function () {
      setIndex(index + 1, true);
    });
    slider.addEventListener("keydown", function (event) {
      if (event.key === "ArrowLeft") {
        event.preventDefault();
        setIndex(index - 1, true);
      } else if (event.key === "ArrowRight") {
        event.preventDefault();
        setIndex(index + 1, true);
      }
    });
    viewport.addEventListener("dragstart", function (event) {
      if (event.target.closest("img")) event.preventDefault();
    });
    viewport.addEventListener("pointerdown", function (event) {
      if (event.button !== undefined && event.button !== 0) return;
      if (event.target.closest("a, button, input, select, textarea")) return;
      pointerId = event.pointerId;
      startX = event.clientX;
      startY = event.clientY;
      lastX = event.clientX;
      startedAt = performance.now();
      gestureDirection = "";
      slider.classList.add("is-dragging");
      if (typeof viewport.setPointerCapture === "function") {
        try {
          viewport.setPointerCapture(pointerId);
        } catch (error) {
          // Pointer capture can be rejected if the pointer ended immediately.
        }
      }
    });
    viewport.addEventListener("pointermove", function (event) {
      if (pointerId === null || event.pointerId !== pointerId) return;
      const deltaX = event.clientX - startX;
      const deltaY = event.clientY - startY;
      lastX = event.clientX;
      if (!gestureDirection && Math.max(Math.abs(deltaX), Math.abs(deltaY)) > 7) {
        gestureDirection = Math.abs(deltaX) > Math.abs(deltaY) * 1.08
          ? "horizontal"
          : "vertical";
      }
      if (gestureDirection !== "horizontal") return;
      if (event.cancelable) event.preventDefault();
      const resistance = Math.abs(deltaX) > viewport.clientWidth ? 0.35 : 1;
      slider.style.setProperty("--slider-drag", `${(deltaX * resistance).toFixed(1)}px`);
    });
    viewport.addEventListener("pointerup", finishGesture);
    viewport.addEventListener("pointercancel", finishGesture);
    window.addEventListener("resize", function () {
      if (resizeTimer) window.clearTimeout(resizeTimer);
      resizeTimer = window.setTimeout(function () {
        resetGesture();
        setIndex(index, false);
        resizeTimer = 0;
      }, 120);
    });

    if ("ResizeObserver" in window) {
      const viewportObserver = new ResizeObserver(function (entries) {
        if (entries.some(function (entry) { return entry.target === slides[index]; })) {
          syncViewportHeight();
        }
      });
      slides.forEach(function (slide) { viewportObserver.observe(slide); });
    }

    if (document.fonts && document.fonts.ready) {
      document.fonts.ready.then(syncViewportHeight);
    }

    setIndex(0, false);
    return {
      next: function () { setIndex(index + 1, true); },
      previous: function () { setIndex(index - 1, true); },
      reset: function () { setIndex(0, false); },
      index: function () { return index; }
    };
  }

  function prepareReadingText(scope) {
    const elements = elementsWithin(scope || document, "[data-reading-text]");
    elements.forEach(function (element) {
      if (element.dataset.readingPrepared === "true") return;

      const originalText = (element.textContent || "").trim().replace(/\s+/g, " ");
      const words = originalText.split(/\s+/);
      if (!words.length || !words[0]) return;
      const visualText = document.createElement("span");
      visualText.className = "reading-visual";
      visualText.setAttribute("aria-hidden", "true");
      const wordElements = words.map(function (word, index) {
        const span = document.createElement("span");
        span.className = "reading-word";
        span.textContent = word;
        if (/[-\u2010-\u2015]/.test(word)) span.style.whiteSpace = "nowrap";
        visualText.appendChild(span);
        if (index < words.length - 1) {
          visualText.appendChild(document.createTextNode(" "));
        }
        return span;
      });

      element.replaceChildren(visualText);
      element.setAttribute("aria-label", originalText);
      element.classList.add("is-reading-active");
      element.dataset.readingOriginal = originalText;
      element.dataset.readingPrepared = "true";
      const stage = element.closest("[data-reading-stage]");
      readingGroups.push({
        element: element,
        words: wordElements,
        visual: visualText,
        stage: stage,
        observedTarget: stage || element,
        observed: false,
        active: true
      });
    });
  }

  function ensureReadingObserver() {
    if (!("IntersectionObserver" in window)) return;
    if (!readingObserver) {
      readingObserver = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            readingGroups.forEach(function (group) {
              if (group.observedTarget !== entry.target) return;
              group.active = entry.isIntersecting;
            });
            if (entry.isIntersecting) requestScrollEffects();
          });
        },
        { threshold: 0, rootMargin: "110% 0px 110% 0px" }
      );
    }

    readingGroups.forEach(function (group) {
      if (group.observed) return;
      group.observed = true;
      readingObserver.observe(group.observedTarget);
    });
  }

  function setReadingWordProgress(word, progress) {
    const normalized = clamp(progress, 0, 1);
    word.style.setProperty("--reading-progress", String(normalized.toFixed(3)));
    word.style.setProperty("--reading-offset", `${((1 - normalized) * 1.5).toFixed(2)}px`);
    word.classList.toggle("is-reading-current", normalized > 0.025 && normalized < 0.975);
    word.classList.toggle("is-reading-complete", normalized >= 0.975);
  }

  function updateReadingProgress() {
    if (!readingGroups.length) return;

    if (reducedMotion.matches) {
      readingGroups.forEach(function (group) {
        group.words.forEach(function (word) {
          setReadingWordProgress(word, 1);
        });
      });
      return;
    }

    const viewportHeight = Math.max(window.innerHeight, 1);
    const startLine = viewportHeight * 0.68;
    const endLine = viewportHeight * 0.18;
    const distance = Math.max(startLine - endLine, 1);

    readingGroups.forEach(function (group) {
      if (!group.active) return;
      const groupBounds = group.element.getBoundingClientRect();
      let groupProgress;

      if (group.stage) {
        const stageBounds = group.stage.getBoundingClientRect();
        const scrollDistance = Math.max(
          stageBounds.height - viewportHeight * 0.35,
          viewportHeight * 0.48
        );
        groupProgress = clamp(
          (viewportHeight * 0.58 - stageBounds.top) / scrollDistance,
          0,
          1
        );
      } else {
        groupProgress = groupBounds.bottom <= 0
          ? 1
          : groupBounds.top >= viewportHeight
            ? 0
            : clamp((startLine - groupBounds.top) / distance, 0, 1);
      }

      group.element.style.setProperty("--reading-section-progress", groupProgress.toFixed(4));
      group.element.dataset.readingState = groupProgress >= 0.999
        ? "complete"
        : groupProgress <= 0.001
          ? "upcoming"
          : "reading";

      const count = Math.max(group.words.length, 1);
      const transitionWindow = clamp(4 / count, 0.075, 0.16);
      const sequenceRange = 1 - transitionWindow;
      group.words.forEach(function (word, index) {
        const wordStart = count === 1
          ? 0
          : (index / (count - 1)) * sequenceRange;
        const localProgress = (groupProgress - wordStart) / transitionWindow;
        setReadingWordProgress(word, localProgress);
      });
    });
  }

  function initReadingProgress(scope) {
    prepareReadingText(scope || document);
    ensureReadingObserver();
    updateReadingProgress();
  }

  function ensureImageObserver() {
    if (imageObserver || !("IntersectionObserver" in window)) return;
    imageObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;
          entry.target.classList.add("is-visible");
          imageObserver.unobserve(entry.target);
        });
      },
      { threshold: 0.1, rootMargin: "0px 0px -5% 0px" }
    );
  }

  function initImageReveals(scope) {
    const elements = elementsWithin(scope || document, "[data-image-reveal]");
    if (!elements.length) return;

    ensureImageObserver();
    const variants = ["horizontal", "vertical", "split"];
    elements.forEach(function (element, index) {
      if (element.dataset.revealPrepared === "true") {
        if (reducedMotion.matches) element.classList.add("is-visible");
        return;
      }

      element.dataset.revealPrepared = "true";
      if (!element.dataset.revealVariant) {
        element.dataset.revealVariant = variants[index % variants.length];
      }
      element.querySelectorAll("img").forEach(function (image) {
        image.addEventListener(
          "error",
          function () {
            element.classList.add("is-media-missing");
          },
          { once: true }
        );
      });

      const bounds = element.getBoundingClientRect();
      if (
        reducedMotion.matches ||
        bounds.top < window.innerHeight * 1.03 ||
        !imageObserver
      ) {
        element.classList.add("is-visible");
      } else {
        imageObserver.observe(element);
      }
    });
  }

  function setActiveNavigation(sectionName) {
    const navigationSection = sectionName;
    document.querySelectorAll("[data-section-link]").forEach(function (link) {
      const active = link.dataset.sectionLink === navigationSection;
      link.classList.toggle("is-active", active);
      if (active) {
        link.setAttribute("aria-current", "location");
      } else {
        link.removeAttribute("aria-current");
      }
    });
  }

  function updateRunningHeader() {
    if (!runningHeaderElement) return;
    const key = manmaticActive ? "manmatic" : activeSectionName || "index";
    const value = runningHeaderCopy[key] || runningHeaderCopy.index;
    resolveDynamicText(runningHeaderElement, value, 340);
  }

  function initRunningHeader() {
    runningHeaderElement =
      document.getElementById("running-header-text") ||
      document.querySelector("[data-running-header]");
    if (!runningHeaderElement) return;
    runningHeaderValue = runningHeaderElement.textContent || "";
  }

  function setActiveSection(sectionName) {
    if (!sectionName) return;
    const changed = activeSectionName !== sectionName;
    activeSectionName = sectionName;
    document.body.dataset.activeSection = sectionName;
    setActiveNavigation(sectionName);

    document.querySelectorAll("[data-nav-section]").forEach(function (section) {
      section.classList.toggle(
        "is-section-active",
        section.dataset.navSection === sectionName
      );
    });

    if (changed) updateRunningHeader();
  }

  function activeSectionFromGeometry() {
    const sections = Array.from(document.querySelectorAll("[data-nav-section]"));
    if (!sections.length) return "";
    const line = window.innerHeight * 0.5;
    let selected = sections[0];
    let distance = Infinity;

    sections.forEach(function (section) {
      const bounds = section.getBoundingClientRect();
      if (bounds.top <= line && bounds.bottom >= line) {
        selected = section;
        distance = -1;
        return;
      }
      if (distance < 0) return;
      const nextDistance = Math.min(
        Math.abs(bounds.top - line),
        Math.abs(bounds.bottom - line)
      );
      if (nextDistance < distance) {
        distance = nextDistance;
        selected = section;
      }
    });

    return selected.dataset.navSection || "";
  }

  function updateActiveSectionFromGeometry() {
    const sectionName = activeSectionFromGeometry();
    if (sectionName) setActiveSection(sectionName);
  }

  function initSectionObserver() {
    const sections = Array.from(document.querySelectorAll("[data-nav-section]"));
    if (!sections.length) return;

    updateActiveSectionFromGeometry();
    if (!("IntersectionObserver" in window)) {
      sectionObserverFallback = true;
      return;
    }

    sectionObserver = new IntersectionObserver(
      function () {
        updateActiveSectionFromGeometry();
      },
      { threshold: 0, rootMargin: "-44% 0px -44% 0px" }
    );
    sections.forEach(function (section) {
      sectionObserver.observe(section);
    });
  }

  function setSiteTheme(theme) {
    const nextTheme = theme === "manmatic" ? "manmatic" : "light";
    const changed = root.dataset.siteTheme !== nextTheme;
    root.dataset.siteTheme = nextTheme;
    if (changed) {
      document.body.dispatchEvent(
        new CustomEvent("portfolio:themechange", {
          detail: { theme: nextTheme }
        })
      );
    }
    const themeMeta = document.querySelector('meta[name="theme-color"]');
    if (themeMeta) {
      themeMeta.setAttribute(
        "content",
        nextTheme === "manmatic" ? "#0a0a0a" : "#ffffff"
      );
    }
  }

  function applyThemeBehindTransition(active) {
    root.classList.add("theme-swap-instant");
    setSiteTheme(active ? "manmatic" : "light");
    void root.offsetWidth;
    window.requestAnimationFrame(function () {
      root.classList.remove("theme-swap-instant");
    });
  }

  function commitManmaticState(active, token) {
    if (token !== manmaticTransitionToken) return;
    manmaticActive = active;
    applyThemeBehindTransition(active);
    if (manmaticTarget) manmaticTarget.classList.toggle("is-field-active", active);

    if (manmaticGlitchTimer) {
      window.clearTimeout(manmaticGlitchTimer);
      manmaticGlitchTimer = 0;
    }
    if (active && manmaticTarget) {
      activateHeading(manmaticTarget);
      if (!reducedMotion.matches) {
        manmaticTarget.classList.add("is-screen-glitching");
        manmaticGlitchTimer = window.setTimeout(function () {
          if (manmaticTarget) manmaticTarget.classList.remove("is-screen-glitching");
          manmaticGlitchTimer = 0;
        }, 300);
      }
    } else if (manmaticTarget) {
      manmaticTarget.classList.remove("is-screen-glitching");
    }
    updateReadingProgress();
    updateRunningHeader();
  }

  function clearManmaticTransition(token) {
    if (token !== manmaticTransitionToken || !manmaticTransitionElement) return;
    manmaticTransitionElement.className = "manmatic-transition";
    if (manmaticTarget) manmaticTarget.classList.remove("is-field-transitioning");
    root.classList.remove("is-system-switching");
    delete root.dataset.systemSwitch;
  }

  function runManmaticTransition(active) {
    manmaticTransitionToken += 1;
    const token = manmaticTransitionToken;
    if (manmaticTransitionTimer) {
      window.clearTimeout(manmaticTransitionTimer);
      manmaticTransitionTimer = 0;
    }
    if (manmaticCommitTimer) {
      window.clearTimeout(manmaticCommitTimer);
      manmaticCommitTimer = 0;
    }

    if (reducedMotion.matches || !manmaticTransitionElement) {
      commitManmaticState(active, token);
      clearManmaticTransition(token);
      return;
    }

    if (manmaticTarget) manmaticTarget.classList.add("is-field-transitioning");
    root.classList.add("is-system-switching");
    root.dataset.systemSwitch = active ? "enter" : "exit";
    manmaticTransitionElement.className = active
      ? "manmatic-transition is-active is-entering"
      : "manmatic-transition is-active is-exiting";
    window.requestAnimationFrame(function () {
      if (token !== manmaticTransitionToken) return;
      manmaticTransitionElement.classList.add("is-running");
    });
    manmaticCommitTimer = window.setTimeout(function () {
      commitManmaticState(active, token);
      manmaticCommitTimer = 0;
    }, active ? 150 : 140);
    manmaticTransitionTimer = window.setTimeout(function () {
      clearManmaticTransition(token);
      manmaticTransitionTimer = 0;
    }, 330);
  }

  function setManmaticActive(active) {
    if (manmaticDesiredActive === active) return;
    manmaticDesiredActive = active;
    runManmaticTransition(active);
  }

  function updateManmaticTheme() {
    if (!manmaticTarget || !document.body.classList.contains("home-page")) return;
    const bounds = manmaticTarget.getBoundingClientRect();
    const viewportHeight = Math.max(window.innerHeight, 1);
    const visiblePixels = Math.max(
      0,
      Math.min(bounds.bottom, viewportHeight) - Math.max(bounds.top, 0)
    );
    const visibilityRatio = visiblePixels / Math.max(
      1,
      Math.min(bounds.height, viewportHeight)
    );
    const enterZone = visibilityRatio >= 0.03 &&
      bounds.top <= viewportHeight * 0.88 && bounds.bottom > viewportHeight * 0.5;
    const holdZone = visibilityRatio > 0.01 &&
      bounds.top <= viewportHeight * 0.94 && bounds.bottom > viewportHeight * 0.5;
    const shouldActivate = manmaticDesiredActive ? holdZone : enterZone;
    setManmaticActive(shouldActivate);
  }

  function initManmaticTheme() {
    if (!document.body.classList.contains("home-page")) return;
    manmaticTarget = document.querySelector("[data-manmatic-system]");
    manmaticTransitionElement = document.querySelector("[data-manmatic-transition]");
    if (!manmaticTarget) {
      setSiteTheme("light");
      return;
    }

    updateManmaticTheme();
    if (!("IntersectionObserver" in window)) return;

    manmaticObserver = new IntersectionObserver(
      function () {
        requestScrollEffects();
      },
      { threshold: [0, 0.15, 0.4, 0.75, 1] }
    );
    manmaticObserver.observe(manmaticTarget);
  }

  function projectAtReadingLine() {
    if (!projectRows.length) return null;
    const line = window.innerHeight * 0.5;
    let selected = projectRows[0];
    let distance = Infinity;

    projectRows.forEach(function (row) {
      const bounds = row.getBoundingClientRect();
      if (bounds.top <= line && bounds.bottom >= line) {
        selected = row;
        distance = -1;
        return;
      }
      if (distance < 0) return;
      const nextDistance = Math.min(
        Math.abs(bounds.top - line),
        Math.abs(bounds.bottom - line)
      );
      if (nextDistance < distance) {
        distance = nextDistance;
        selected = row;
      }
    });

    return selected;
  }

  function renderActiveProject(row) {
    if (!row) return;
    projectRows.forEach(function (project) {
      project.classList.toggle("is-active", project === row);
    });
    document.body.dataset.activeProject = row.dataset.projectIndex || "";

    const activeFile = document.getElementById("work-active-file");
    if (activeFile) {
      const index = row.dataset.projectIndex || "01";
      activeFile.textContent = String(index).padStart(2, "0") + " / " +
        String(projectRows.length).padStart(2, "0");
    }
  }

  function updateActiveProjectFromGeometry() {
    scrollActiveProject = projectAtReadingLine();
    renderActiveProject(scrollActiveProject);
  }

  function initProjectInteractions() {
    projectRows = Array.from(
      document.querySelectorAll(".project-row[data-project-index]:not([hidden]), .project-row[data-project-id]:not([hidden])")
    );
    if (!projectRows.length) return;

    const finePointer = window.matchMedia("(hover: hover) and (pointer: fine)").matches;
    projectRows.forEach(function (row) {
      if (finePointer) {
        row.addEventListener("pointerenter", function () {
          renderActiveProject(row);
        });
        row.addEventListener("pointerleave", function () {
          renderActiveProject(scrollActiveProject || projectAtReadingLine());
        });
      }
      row.addEventListener("focusin", function () {
        renderActiveProject(row);
      });
      row.addEventListener("focusout", function (event) {
        if (event.relatedTarget && row.contains(event.relatedTarget)) return;
        renderActiveProject(scrollActiveProject || projectAtReadingLine());
      });
    });

    updateActiveProjectFromGeometry();
    if (!("IntersectionObserver" in window)) {
      projectObserverFallback = true;
      return;
    }

    projectObserver = new IntersectionObserver(
      function () {
        updateActiveProjectFromGeometry();
      },
      { threshold: 0, rootMargin: "-38% 0px -38% 0px" }
    );
    projectRows.forEach(function (row) {
      projectObserver.observe(row);
    });
  }

  function initMobileNavigation() {
    const toggle = document.getElementById("nav-toggle");
    const navigation = document.getElementById("primary-navigation");
    if (!toggle || !navigation) return;
    const links = Array.from(navigation.querySelectorAll("a"));
    const backdrop = document.querySelector("[data-nav-dismiss]");
    const brand = document.querySelector(".site-header__name");
    const navigationHome = toggle.parentNode;
    const navigationMarker = document.createComment("mobile-navigation-portal");
    navigationHome.insertBefore(navigationMarker, toggle);
    const focusableMenuItems = [toggle].concat(links);
    const backgroundRegions = Array.from(
      document.querySelectorAll("main, .closing-identity, .site-footer, .skip-link, .site-header__name")
    );
    let lastTouchToggle = -Infinity;

    function placeNavigation() {
      if (window.innerWidth <= 960) {
        if (backdrop && backdrop.parentNode !== document.body) document.body.appendChild(backdrop);
        if (navigation.parentNode !== document.body) document.body.appendChild(navigation);
        if (toggle.parentNode !== document.body) document.body.appendChild(toggle);
        return;
      }

      if (toggle.parentNode !== navigationHome) {
        navigationHome.insertBefore(toggle, navigationMarker.nextSibling);
      }
      if (backdrop && backdrop.parentNode !== navigationHome) {
        navigationHome.insertBefore(backdrop, toggle.nextSibling);
      }
      if (navigation.parentNode !== navigationHome) {
        navigationHome.insertBefore(navigation, backdrop ? backdrop.nextSibling : toggle.nextSibling);
      }
    }

    function setBackgroundInert(inert) {
      backgroundRegions.forEach(function (region) {
        if ("inert" in region) region.inert = inert;
      });
    }

    function focusFragment(link) {
      if (!link || !link.hash) return;
      const target = document.querySelector(link.hash);
      if (!target) return;
      if (!target.hasAttribute("tabindex")) target.setAttribute("tabindex", "-1");
      window.requestAnimationFrame(function () {
        try {
          target.focus({ preventScroll: true });
        } catch (error) {
          target.focus();
        }
      });
    }

    function closeMenu(restoreFocus) {
      const wasOpen = toggle.getAttribute("aria-expanded") === "true";
      toggle.setAttribute("aria-expanded", "false");
      toggle.setAttribute("aria-label", "Open navigation");
      navigation.classList.remove("is-open");
      if (backdrop) backdrop.classList.remove("is-open");
      document.body.classList.remove("is-menu-open", "menu-open");
      root.classList.remove("is-menu-open");
      navigation.setAttribute("aria-hidden", window.innerWidth <= 960 ? "true" : "false");
      setBackgroundInert(false);
      if (wasOpen) setDocumentScrollLock("mobile-navigation", false);
      if (restoreFocus) {
        try {
          toggle.focus({ preventScroll: true });
        } catch (error) {
          toggle.focus();
        }
      }
    }

    function openMenu() {
      setDocumentScrollLock("mobile-navigation", true);
      toggle.setAttribute("aria-expanded", "true");
      toggle.setAttribute("aria-label", "Close navigation");
      navigation.classList.add("is-open");
      if (backdrop) backdrop.classList.add("is-open");
      document.body.classList.add("is-menu-open", "menu-open");
      root.classList.add("is-menu-open");
      navigation.setAttribute("aria-hidden", "false");
      setBackgroundInert(true);
      if (links[0]) links[0].focus();
    }

    function toggleMenu() {
      if (toggle.getAttribute("aria-expanded") === "true") {
        closeMenu(false);
      } else {
        openMenu();
      }
    }

    if ("PointerEvent" in window) {
      toggle.addEventListener("pointerup", function (event) {
        if (event.pointerType !== "touch" && event.pointerType !== "pen") return;
        event.preventDefault();
        lastTouchToggle = performance.now();
        toggleMenu();
      });
    } else {
      toggle.addEventListener("touchend", function (event) {
        event.preventDefault();
        lastTouchToggle = performance.now();
        toggleMenu();
      }, { passive: false });
    }

    toggle.addEventListener("click", function () {
      if (performance.now() - lastTouchToggle < 500) return;
      toggleMenu();
    });

    if (backdrop) {
      backdrop.addEventListener("click", function () {
        closeMenu(true);
      });
    }

    links.forEach(function (link) {
      link.addEventListener("click", function () {
        closeMenu(false);
        if (link.origin === window.location.origin && link.pathname === window.location.pathname) {
          focusFragment(link);
        }
      });
    });

    if (brand) {
      brand.addEventListener("click", function () {
        if (toggle.getAttribute("aria-expanded") === "true") closeMenu(false);
      });
    }

    document.addEventListener("keydown", function (event) {
      if (toggle.getAttribute("aria-expanded") !== "true") return;
      if (event.key === "Escape") {
        event.preventDefault();
        closeMenu(true);
        return;
      }
      if (event.key !== "Tab" || !focusableMenuItems.length) return;

      const first = focusableMenuItems[0];
      const last = focusableMenuItems[focusableMenuItems.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    });

    window.addEventListener("resize", function () {
      placeNavigation();
      if (window.innerWidth > 960) {
        closeMenu(false);
        navigation.removeAttribute("aria-hidden");
      } else if (toggle.getAttribute("aria-expanded") !== "true") {
        navigation.setAttribute("aria-hidden", "true");
      }
    });

    window.addEventListener("hashchange", function () {
      if (toggle.getAttribute("aria-expanded") === "true") closeMenu(false);
    });

    window.addEventListener("pageshow", function () {
      if (toggle.getAttribute("aria-expanded") === "true") closeMenu(false);
    });

    placeNavigation();
    toggle.setAttribute("aria-label", "Open navigation");
    if (window.innerWidth <= 960) navigation.setAttribute("aria-hidden", "true");
  }

  function updateHeaderState() {
    const header = document.getElementById("site-header");
    if (header) header.classList.toggle("is-scrolled", window.scrollY > 8);
  }

  function updateAmbientSuspension() {
    root.classList.toggle("is-page-hidden", document.hidden);
  }

  function initAmbientMotion() {
    updateAmbientSuspension();
    document.addEventListener("visibilitychange", updateAmbientSuspension);
  }

  function updateViewportReveals() {
    const viewportHeight = Math.max(window.innerHeight, 1);
    document
      .querySelectorAll(".reveal-item.is-reveal-ready:not(.is-revealed)")
      .forEach(function (element) {
        const bounds = element.getBoundingClientRect();
        if (bounds.top < viewportHeight * 1.04 && bounds.bottom > -viewportHeight * 0.08) {
          element.classList.add("is-revealed");
          if (revealObserver) revealObserver.unobserve(element);
        }
      });
    document
      .querySelectorAll("[data-image-reveal]:not(.is-visible)")
      .forEach(function (element) {
        const bounds = element.getBoundingClientRect();
        if (bounds.top < viewportHeight * 1.04 && bounds.bottom > -viewportHeight * 0.08) {
          element.classList.add("is-visible");
          if (imageObserver) imageObserver.unobserve(element);
        }
      });
  }

  function updateParallax() {
    const images = document.querySelectorAll("[data-parallax]");
    if (reducedMotion.matches || window.innerWidth <= 560) {
      images.forEach(function (image) {
        image.style.removeProperty("--parallax-y");
      });
      return;
    }

    images.forEach(function (image) {
      if (image.closest(".media--contain, .broadcast-monitor")) return;
      const frame = image.closest(".image-frame__crop, [data-parallax-frame]");
      if (!frame) return;
      const bounds = frame.getBoundingClientRect();
      if (bounds.bottom < 0 || bounds.top > window.innerHeight) return;
      const viewportCenter = window.innerHeight / 2;
      const imageCenter = bounds.top + bounds.height / 2;
      const progress =
        (imageCenter - viewportCenter) / (window.innerHeight + bounds.height);
      const offset = clamp(progress * -24, -10, 10);
      image.style.setProperty("--parallax-y", String(offset.toFixed(2)) + "px");
    });
  }

  function updateScrollEffects() {
    scrollFrame = 0;
    updateHeaderState();
    updateReadingProgress();
    updateParallax();
    updateManmaticTheme();
    updateViewportReveals();
    if (sectionObserverFallback) updateActiveSectionFromGeometry();
    if (projectObserverFallback) updateActiveProjectFromGeometry();
  }

  function requestScrollEffects() {
    if (!scrollFrame) {
      scrollFrame = window.requestAnimationFrame(updateScrollEffects);
    }
  }

  function initScrollEffects() {
    window.addEventListener("scroll", requestScrollEffects, { passive: true });
    window.addEventListener("resize", requestScrollEffects);
    window.addEventListener("orientationchange", requestScrollEffects);
    window.addEventListener("pageshow", requestScrollEffects);
    if (document.fonts && document.fonts.ready) {
      document.fonts.ready.then(requestScrollEffects);
    }
    requestScrollEffects();
  }

  function applyMotionPreference() {
    root.classList.toggle("reduced-motion", reducedMotion.matches);

    if (reducedMotion.matches) {
      if (finishMonitorBoot) finishMonitorBoot();

      if (
        manmaticTransitionElement &&
        manmaticTransitionElement.classList.contains("is-active")
      ) {
        manmaticTransitionToken += 1;
        if (manmaticTransitionTimer) {
          window.clearTimeout(manmaticTransitionTimer);
          manmaticTransitionTimer = 0;
        }
        if (manmaticCommitTimer) {
          window.clearTimeout(manmaticCommitTimer);
          manmaticCommitTimer = 0;
        }
        commitManmaticState(manmaticDesiredActive, manmaticTransitionToken);
        clearManmaticTransition(manmaticTransitionToken);
      }

      document.querySelectorAll("[data-scramble]").forEach(settleScramble);
      document.querySelectorAll("[data-image-reveal]").forEach(function (element) {
        element.classList.add("is-visible");
      });
      document.querySelectorAll(".heading-motion").forEach(activateHeading);
      document.querySelectorAll("[data-pixel-portrait]").forEach(assemblePortrait);
    }

    if (showreelController) showreelController.handleMotionChange();
    updateReadingProgress();
    updateParallax();
    requestScrollEffects();
  }

  function respectReducedMotion() {
    if (!motionListenerBound) {
      motionListenerBound = true;
      if (typeof reducedMotion.addEventListener === "function") {
        reducedMotion.addEventListener("change", applyMotionPreference);
      } else if (typeof reducedMotion.addListener === "function") {
        reducedMotion.addListener(applyMotionPreference);
      }
    }
    applyMotionPreference();
  }

  function refreshEnhancements(scope) {
    initProtectedMedia(scope || document);
    initReadingProgress(scope || document);
    initHeadingMotion(scope || document);
    initScrambleText(scope || document);
    initImageReveals(scope || document);
    initSectionReveals(scope || document);
    initPointerScanning(scope || document);
    initPixelPortrait(scope || document);
    requestScrollEffects();
  }

  function normalizeProjectArchiveOrder() {
    const archive = document.querySelector(".project-index");
    if (!archive) return;
    Array.from(archive.querySelectorAll(":scope > .project-row[data-project-order]"))
      .sort(function (a, b) { return Number(a.dataset.projectOrder) - Number(b.dataset.projectOrder); })
      .forEach(function (row) { archive.appendChild(row); });
  }

  function init() {
    respectReducedMotion();
    initAmbientMotion();
    initMobileNavigation();
    normalizeProjectArchiveOrder();
    hydrateContentMedia();
    initRunningHeader();
    visualSliderController = initVisuals();
    initProtectedMedia(document);
    initReadingProgress(document);
    initSectionObserver();
    initProjectInteractions();
    initScrollEffects();

    initMonitorBoot().then(function () {
      root.classList.add("motion-ready");
      initManmaticTheme();
      showreelController = initShowreel();
      initHeadingMotion(document);
      initScrambleText(document);
      initImageReveals(document);
      initSectionReveals(document);
      initPointerScanning(document);
      initPixelPortrait(document);
      requestScrollEffects();
    });
  }

  window.PortfolioEnhance = {
    refresh: refreshEnhancements,
    scramble: scrambleElement,
    scrambleTo: resolveDynamicText,
    setTheme: setSiteTheme,
    requestUpdate: requestScrollEffects
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }
})();

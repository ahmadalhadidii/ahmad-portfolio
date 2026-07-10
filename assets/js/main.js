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
    work: "SELECTED WORK / PROJECT ARCHIVE / 01–05",
    contact: "CONTACT RECORD / AS-SALT, JORDAN / 2026",
    manmatic: "MANMATIC / HUMAN–MACHINE INTEGRATION / ACTIVE FIELD"
  };

  let imageObserver = null;
  let scrambleObserver = null;
  let scrollFrame = 0;
  let readingGroups = [];
  let activeSectionName = "";
  let runningHeaderElement = null;
  let runningHeaderValue = "";
  let sectionObserver = null;
  let sectionObserverFallback = false;
  let manmaticObserver = null;
  let manmaticTarget = null;
  let manmaticActive = false;
  let projectObserver = null;
  let projectObserverFallback = false;
  let projectRows = [];
  let scrollActiveProject = null;
  let showreelController = null;
  let finishMonitorBoot = null;
  let motionListenerBound = false;

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
        accessibleOwner.setAttribute("aria-label", finalText);
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
    if (runningHeaderValue === value && element.textContent === value) return;

    const token = {};
    const owner = element.closest(".running-header");
    dynamicScrambles.set(element, token);
    runningHeaderValue = value;
    if (owner) owner.classList.add("is-updating");

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
    const elements = elementsWithin(scope || document, "[data-scramble]");
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

  function initMonitorBoot() {
    const loader = document.getElementById("loader");
    const shouldPlay =
      loader &&
      root.classList.contains("loader-pending") &&
      !reducedMotion.matches;

    if (!shouldPlay) {
      if (loader) {
        loader.hidden = true;
        loader.setAttribute("aria-hidden", "true");
      }
      root.classList.remove("loader-pending");
      root.classList.add("loader-skipped");
      return Promise.resolve();
    }

    const counter = document.getElementById("loader-count");
    const name = document.getElementById("loader-name");
    const startedAt = performance.now();
    let frameRequest = 0;
    let exitStarted = false;
    let settled = false;
    let resolveBoot;

    function settle() {
      if (settled) return;
      settled = true;
      if (frameRequest) window.cancelAnimationFrame(frameRequest);
      if (counter) counter.textContent = "06";
      loader.classList.add("is-complete");
      loader.hidden = true;
      loader.setAttribute("aria-hidden", "true");
      root.classList.remove("loader-pending");
      root.classList.add("loader-complete");
      finishMonitorBoot = null;
      if (resolveBoot) resolveBoot();
    }

    function beginExit() {
      if (exitStarted || settled) return;
      exitStarted = true;
      if (counter) counter.textContent = "06";
      loader.classList.add("is-complete");
      loader.setAttribute("aria-hidden", "true");
      root.classList.remove("loader-pending");
      root.classList.add("loader-complete");
      window.setTimeout(settle, 245);
    }

    function updateFrame(now) {
      if (settled || exitStarted) return;
      const progress = clamp((now - startedAt) / 720, 0, 1);
      const frame = clamp(Math.floor(progress * 6) + 1, 1, 6);
      if (counter) counter.textContent = String(frame).padStart(2, "0");
      frameRequest = window.requestAnimationFrame(updateFrame);
    }

    scrambleElement(name, 560);
    finishMonitorBoot = settle;

    return new Promise(function (resolve) {
      resolveBoot = resolve;
      frameRequest = window.requestAnimationFrame(updateFrame);
      window.setTimeout(beginExit, 760);
      window.setTimeout(settle, 1040);
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
    let running = false;

    function setFrame(nextIndex) {
      if (!slides.length) return;
      index = (nextIndex + slides.length) % slides.length;

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
        setFrame(index + 1);
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
      setFrame(0);
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

    setFrame(index);

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
    let videoAttempt = 0;

    const fallback = initFallbackSlideshow(
      showreel,
      function (index, slide) {
        const frameValue =
          (slide && slide.dataset.frame) || String(index + 1).padStart(2, "0");
        if (frameReadout) frameReadout.textContent = frameValue;
      }
    );

    function isPlaying() {
      if (reducedMotion.matches || pageSuspended) return false;
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
      if (!userPaused && !pageSuspended && !reducedMotion.matches) {
        fallback.play();
      } else {
        fallback.pause();
      }
      updateControls();
    }

    function activateVideo() {
      if (!video || reducedMotion.matches || userPaused || pageSuspended) return;
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
      if (reducedMotion.matches || pageSuspended) {
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
      } else if (!userPaused && !pageSuspended) {
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
      if (pageSuspended) {
        pause(false);
      } else if (!userPaused && !reducedMotion.matches) {
        play(false);
      }
    });

    activateFallback();
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

  function prepareReadingText(scope) {
    const elements = elementsWithin(scope || document, "[data-reading-text]");
    elements.forEach(function (element) {
      if (element.dataset.readingPrepared === "true") return;

      const words = (element.textContent || "").trim().split(/\s+/);
      if (!words.length || !words[0]) return;
      const fragment = document.createDocumentFragment();
      const wordElements = words.map(function (word, index) {
        const span = document.createElement("span");
        span.className = "reading-word";
        span.textContent = word;
        if (/[-\u2010-\u2015]/.test(word)) span.style.whiteSpace = "nowrap";
        fragment.appendChild(span);
        if (index < words.length - 1) {
          fragment.appendChild(document.createTextNode(" "));
        }
        return span;
      });

      element.textContent = "";
      element.appendChild(fragment);
      element.classList.add("is-reading-active");
      element.dataset.readingPrepared = "true";
      readingGroups.push({ element: element, words: wordElements });
    });
  }

  function setReadingWordProgress(word, progress) {
    const normalized = clamp(progress, 0, 1);
    const percentage = Math.round(normalized * 1000) / 10;
    word.style.setProperty("--reading-progress", String(normalized.toFixed(3)));
    word.style.color =
      "color-mix(in srgb, " +
      "var(--theme-reading-unread, var(--theme-light)) " +
      String(100 - percentage) +
      "%, var(--theme-text) " +
      String(percentage) +
      "%)";
  }

  function updateReadingProgress() {
    if (!readingGroups.length) return;

    if (reducedMotion.matches) {
      readingGroups.forEach(function (group) {
        group.words.forEach(function (word) {
          word.style.setProperty("--reading-progress", "1");
          word.style.color = "var(--theme-text)";
        });
      });
      return;
    }

    const viewportHeight = Math.max(window.innerHeight, 1);
    const start = viewportHeight * 0.86;
    const end = viewportHeight * 0.34;
    const distance = Math.max(start - end, 1);

    readingGroups.forEach(function (group) {
      const groupBounds = group.element.getBoundingClientRect();
      if (groupBounds.bottom < 0) {
        group.words.forEach(function (word) {
          setReadingWordProgress(word, 1);
        });
        return;
      }
      if (groupBounds.top > viewportHeight) return;

      const firstTop = group.words[0].getBoundingClientRect().top;
      const length = Math.max(group.words.length, 1);
      group.words.forEach(function (word, index) {
        const top = word.getBoundingClientRect().top;
        const lineProgress = (start - top) / distance;
        const stagger = (index / length) * 0.16;
        let progress = clamp(lineProgress * 1.16 - stagger, 0, 1);
        const firstLine = Math.abs(top - firstTop) < 2;
        if (firstLine && groupBounds.top < viewportHeight * 0.96) {
          progress = Math.max(progress, 0.16);
        }
        setReadingWordProgress(word, progress);
      });
    });
  }

  function initReadingProgress(scope) {
    prepareReadingText(scope || document);
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
    elements.forEach(function (element) {
      if (element.dataset.revealPrepared === "true") {
        if (reducedMotion.matches) element.classList.add("is-visible");
        return;
      }

      element.dataset.revealPrepared = "true";
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

  function updateRunningHeader() {
    if (!runningHeaderElement) return;
    const key = manmaticActive ? "manmatic" : activeSectionName || "index";
    const value = runningHeaderCopy[key] || runningHeaderCopy.index;
    resolveDynamicText(runningHeaderElement, value, 340);
  }

  function initRunningHeader() {
    runningHeaderElement =
      document.querySelector("[data-running-header]") ||
      document.getElementById("running-header-text");
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
    if (document.body.dataset.siteTheme !== nextTheme) {
      document.body.dataset.siteTheme = nextTheme;
      document.body.dispatchEvent(
        new CustomEvent("portfolio:themechange", {
          detail: { theme: nextTheme }
        })
      );
    }

    document.body.classList.toggle(
      "is-manmatic-active",
      nextTheme === "manmatic"
    );
    const themeMeta = document.querySelector('meta[name="theme-color"]');
    if (themeMeta) {
      themeMeta.setAttribute(
        "content",
        nextTheme === "manmatic" ? "#0a0a0a" : "#ffffff"
      );
    }
  }

  function setManmaticActive(active) {
    if (manmaticActive === active) return;
    manmaticActive = active;
    setSiteTheme(active ? "manmatic" : "light");
    updateRunningHeader();
  }

  function updateManmaticTheme() {
    if (!manmaticTarget || !document.body.classList.contains("home-page")) return;
    const bounds = manmaticTarget.getBoundingClientRect();
    const viewportHeight = Math.max(window.innerHeight, 1);
    const shouldActivate = manmaticActive
      ? bounds.top < viewportHeight * 0.66 &&
        bounds.bottom > viewportHeight * 0.34
      : bounds.top < viewportHeight * 0.56 &&
        bounds.bottom > viewportHeight * 0.44;
    setManmaticActive(shouldActivate);
  }

  function initManmaticTheme() {
    if (!document.body.classList.contains("home-page")) return;
    manmaticTarget = document.querySelector('[data-project-theme="manmatic"]');
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
      { threshold: 0, rootMargin: "-44% 0px -44% 0px" }
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
      document.querySelectorAll(".project-row[data-project-index], [data-project-id]")
    );
    if (!projectRows.length) return;

    projectRows.forEach(function (row) {
      row.addEventListener("pointerenter", function () {
        renderActiveProject(row);
      });
      row.addEventListener("pointerleave", function () {
        renderActiveProject(scrollActiveProject || projectAtReadingLine());
      });
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

    function closeMenu(restoreFocus) {
      toggle.setAttribute("aria-expanded", "false");
      navigation.classList.remove("is-open");
      document.body.classList.remove("menu-open");
      if (restoreFocus) toggle.focus();
    }

    function openMenu() {
      toggle.setAttribute("aria-expanded", "true");
      navigation.classList.add("is-open");
      document.body.classList.add("menu-open");
      if (links[0]) links[0].focus();
    }

    toggle.addEventListener("click", function () {
      if (toggle.getAttribute("aria-expanded") === "true") {
        closeMenu(false);
      } else {
        openMenu();
      }
    });

    links.forEach(function (link) {
      link.addEventListener("click", function () {
        closeMenu(false);
      });
    });

    document.addEventListener("keydown", function (event) {
      if (toggle.getAttribute("aria-expanded") !== "true") return;
      if (event.key === "Escape") {
        event.preventDefault();
        closeMenu(true);
        return;
      }
      if (event.key !== "Tab" || !links.length) return;

      const first = links[0];
      const last = links[links.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    });

    window.addEventListener("resize", function () {
      if (window.innerWidth > 820) closeMenu(false);
    });
  }

  function updateHeaderState() {
    const header = document.getElementById("site-header");
    if (header) header.classList.toggle("is-scrolled", window.scrollY > 8);
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
    window.addEventListener("pageshow", requestScrollEffects);
    if (document.fonts && document.fonts.ready) {
      document.fonts.ready.then(requestScrollEffects);
    }
    requestScrollEffects();
  }

  function applyMotionPreference() {
    root.classList.toggle("reduced-motion", reducedMotion.matches);

    if (reducedMotion.matches) {
      const loader = document.getElementById("loader");
      if (finishMonitorBoot) {
        finishMonitorBoot();
      } else if (loader) {
        loader.hidden = true;
        loader.setAttribute("aria-hidden", "true");
        root.classList.remove("loader-pending");
        root.classList.add("loader-skipped");
      }

      document.querySelectorAll("[data-scramble]").forEach(settleScramble);
      document.querySelectorAll("[data-image-reveal]").forEach(function (element) {
        element.classList.add("is-visible");
      });
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
    initReadingProgress(scope || document);
    initScrambleText(scope || document);
    initImageReveals(scope || document);
    requestScrollEffects();
  }

  function init() {
    respectReducedMotion();
    initMobileNavigation();
    initRunningHeader();
    initReadingProgress(document);
    initSectionObserver();
    initManmaticTheme();
    initProjectInteractions();
    initScrollEffects();

    initMonitorBoot().then(function () {
      root.classList.add("motion-ready");
      showreelController = initShowreel();
      initScrambleText(document);
      initImageReveals(document);
      requestScrollEffects();
    });
  }

  window.PortfolioEnhance = {
    refresh: refreshEnhancements,
    scramble: scrambleElement,
    setTheme: setSiteTheme,
    requestUpdate: requestScrollEffects
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }
})();

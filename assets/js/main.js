/* ============================================================
   MAIN.JS
   Reads siteContent from content.js, injects it into the DOM,
   and wires up all interactions: loader, scramble text, nav,
   scroll reveals, project modal, local time.
   ============================================================ */

(function () {
  "use strict";

  const REDUCED_MOTION = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const SCRAMBLE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789{}[]<>/\\|_-+=*&^%$#@!";

  /* ------------------------------------------------------------
     SCRAMBLE TEXT
     scrambleText(element, finalText, options)
     ------------------------------------------------------------ */
  function scrambleText(element, finalText, options) {
    options = options || {};
    const duration = options.duration || 700;
    const speed = options.speed || 32;
    const delay = options.delay || 0;
    const preserveSpaces = options.preserveSpaces !== false;
    const onComplete = options.onComplete || function () {};

    if (REDUCED_MOTION) {
      element.textContent = finalText;
      onComplete();
      return;
    }

    const chars = finalText.split("");
    const totalFrames = Math.max(Math.round(duration / speed), 1);
    let frame = 0;
    let timer = null;

    function renderFrame() {
      const progress = frame / totalFrames;
      const resolveCount = Math.floor(progress * chars.length);
      let out = "";
      for (let i = 0; i < chars.length; i++) {
        const ch = chars[i];
        if (preserveSpaces && (ch === " " || ch === "\n" || ch === "\t")) {
          out += ch;
          continue;
        }
        if (i < resolveCount) {
          out += ch;
        } else {
          out += SCRAMBLE_CHARS[Math.floor(Math.random() * SCRAMBLE_CHARS.length)];
        }
      }
      element.textContent = out;
      frame++;
      if (frame <= totalFrames) {
        timer = setTimeout(renderFrame, speed);
      } else {
        element.textContent = finalText;
        onComplete();
      }
    }

    setTimeout(renderFrame, delay);
  }

  /* ------------------------------------------------------------
     BINARY ARCHITECTURAL INTRO
     ------------------------------------------------------------ */
  function initBinaryLoader() {
    const loader = document.getElementById("binary-loader");

    function revealWithoutOverlay() {
      document.body.classList.remove("is-loading");
      document.body.classList.add("is-loaded");
      window.dispatchEvent(new Event("portfolioIntroComplete"));
    }

    if (!loader) {
      revealWithoutOverlay();
      return;
    }

    const canvas = document.getElementById("binary-canvas");
    const statusEl = document.getElementById("binary-loader-status");
    const progressEl = document.getElementById("binary-loader-progress");
    const nameEl = loader.querySelector(".binary-loader__name");
    const metaEl = loader.querySelector(".binary-loader__meta");
    const loaderStatuses = [
      "INITIALIZING FIELD STRUCTURE",
      "READING PROJECT INDEX",
      "ALIGNING SPATIAL SYSTEMS",
      "ASSEMBLING RESEARCH FIELD",
      "OPENING PORTFOLIO"
    ];

    let ctx = canvas ? canvas.getContext("2d") : null;
    let particles = [];
    let canvasWidth = 0;
    let canvasHeight = 0;
    let animationFrameId = null;
    let resizeTimer = null;
    let statusTimer = null;
    let completionTimer = null;
    let isExiting = false;
    let isComplete = false;
    const timelineTimers = [];
    const introStart = performance.now();
    const activeDuration = 2600;
    const exitDuration = 650;
    const progressDuration = 2200;

    function queueTimeline(callback, delay) {
      const timer = setTimeout(callback, delay);
      timelineTimers.push(timer);
      return timer;
    }

    function clearTimeline() {
      timelineTimers.forEach(function (timer) { clearTimeout(timer); });
      timelineTimers.length = 0;
      if (statusTimer !== null) {
        clearInterval(statusTimer);
        statusTimer = null;
      }
      if (resizeTimer !== null) {
        clearTimeout(resizeTimer);
        resizeTimer = null;
      }
    }

    function stopCanvas() {
      if (animationFrameId !== null) {
        cancelAnimationFrame(animationFrameId);
        animationFrameId = null;
      }
      window.removeEventListener("resize", handleResize);
    }

    function completeIntro() {
      if (isComplete) return;
      isComplete = true;
      clearTimeline();
      stopCanvas();
      loader.removeEventListener("transitionend", handleExitTransition);
      if (completionTimer !== null) clearTimeout(completionTimer);
      document.body.classList.remove("is-loading");
      document.body.classList.add("is-loaded");
      loader.remove();
      window.dispatchEvent(new Event("portfolioIntroComplete"));
    }

    function handleExitTransition(event) {
      if (event.target === loader && event.propertyName === "opacity") {
        completeIntro();
      }
    }

    function beginExit(fadeDuration) {
      if (isExiting) return;
      isExiting = true;
      clearTimeline();
      stopCanvas();
      if (progressEl) progressEl.textContent = "100";
      if (statusEl) statusEl.textContent = loaderStatuses[loaderStatuses.length - 1];
      loader.addEventListener("transitionend", handleExitTransition);
      loader.classList.add("is-exiting");
      completionTimer = setTimeout(completeIntro, fadeDuration + 100);
    }

    if (REDUCED_MOTION) {
      if (nameEl) {
        nameEl.classList.add("is-active");
        nameEl.textContent = nameEl.getAttribute("data-loader-scramble") || nameEl.textContent;
      }
      if (metaEl) {
        metaEl.classList.add("is-active");
        metaEl.textContent = metaEl.getAttribute("data-loader-scramble") || metaEl.textContent;
      }
      if (progressEl) progressEl.textContent = "100";
      if (statusEl) statusEl.textContent = loaderStatuses[loaderStatuses.length - 1];
      queueTimeline(function () { beginExit(0); }, 180);
      return;
    }

    if (!canvas || !ctx) {
      if (nameEl) nameEl.classList.add("is-active");
      if (metaEl) metaEl.classList.add("is-active");
      if (progressEl) progressEl.textContent = "100";
      if (statusEl) statusEl.textContent = loaderStatuses[loaderStatuses.length - 1];
      queueTimeline(function () { beginExit(exitDuration); }, 100);
      return;
    }

    const monoFont =
      getComputedStyle(document.documentElement).getPropertyValue("--font-mono").trim() ||
      "monospace";

    function particleCountForWidth(width) {
      if (width >= 1024) return 220;
      if (width >= 600) return 150;
      return 105;
    }

    function createParticles() {
      const count = particleCountForWidth(canvasWidth);
      const now = performance.now();
      particles = Array.from({ length: count }, function () {
        const direction = Math.random() < 0.5 ? "horizontal" : "vertical";
        const speed = (6 + Math.random() * 16) / 1000;
        const sign = Math.random() < 0.5 ? -1 : 1;
        return {
          x: Math.random() * canvasWidth,
          y: Math.random() * canvasHeight,
          vx: direction === "horizontal" ? speed * sign : 0,
          vy: direction === "vertical" ? speed * sign : 0,
          char: Math.random() < 0.5 ? "0" : "1",
          size: canvasWidth < 480 ? 9 + Math.random() * 5 : 10 + Math.random() * 7,
          opacity: 0.14 + Math.random() * 0.22,
          lifeOffset: Math.random() * Math.PI * 2,
          direction: direction,
          nextFlip: now + 350 + Math.random() * 950
        };
      });
    }

    function resizeCanvas() {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvasWidth = window.innerWidth;
      canvasHeight = window.innerHeight;
      canvas.width = Math.round(canvasWidth * dpr);
      canvas.height = Math.round(canvasHeight * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      createParticles();
    }

    function handleResize() {
      if (resizeTimer !== null) clearTimeout(resizeTimer);
      resizeTimer = setTimeout(function () {
        resizeTimer = null;
        resizeCanvas();
      }, 120);
    }

    let lastFrame = introStart;
    let lastProgress = -1;

    function renderBinaryField(now) {
      if (isExiting || isComplete) return;

      const elapsed = now - introStart;
      const frameDelta = Math.min(now - lastFrame, 64);
      lastFrame = now;
      const progressRatio = Math.min(elapsed / progressDuration, 1);
      const easedProgress = progressRatio * progressRatio * (3 - 2 * progressRatio);
      const progress = Math.min(100, Math.round(easedProgress * 100));

      if (progress !== lastProgress && progressEl) {
        lastProgress = progress;
        progressEl.textContent = String(progress).padStart(3, "0");
      }

      let fieldStrength = 1;
      if (elapsed < 1500) {
        fieldStrength = 0.82 + (elapsed / 1500) * 0.18;
      } else if (elapsed > 2000) {
        fieldStrength = Math.max(0.35, 1 - ((elapsed - 2000) / 600) * 0.65);
      }

      ctx.clearRect(0, 0, canvasWidth, canvasHeight);

      particles.forEach(function (particle) {
        particle.x += particle.vx * frameDelta;
        particle.y += particle.vy * frameDelta;

        if (particle.x < -20) particle.x = canvasWidth + 20;
        if (particle.x > canvasWidth + 20) particle.x = -20;
        if (particle.y < -20) particle.y = canvasHeight + 20;
        if (particle.y > canvasHeight + 20) particle.y = -20;

        if (now >= particle.nextFlip) {
          particle.char = particle.char === "0" ? "1" : "0";
          particle.nextFlip = now + 350 + Math.random() * 950;
        }

        const pulse = 0.7 + 0.3 * (0.5 + 0.5 * Math.sin(now * 0.0012 + particle.lifeOffset));
        const opacity = particle.opacity * pulse * fieldStrength;
        ctx.font = particle.size + "px " + monoFont;
        ctx.fillStyle = "rgba(17,17,17," + opacity.toFixed(3) + ")";
        ctx.fillText(particle.char, particle.x, particle.y);
      });

      animationFrameId = requestAnimationFrame(renderBinaryField);
    }

    resizeCanvas();
    window.addEventListener("resize", handleResize);
    animationFrameId = requestAnimationFrame(renderBinaryField);

    queueTimeline(function () {
      if (!nameEl) return;
      nameEl.classList.add("is-active");
      scrambleText(nameEl, nameEl.getAttribute("data-loader-scramble") || nameEl.textContent, {
        duration: 650,
        speed: 32
      });
    }, 200);

    queueTimeline(function () {
      if (!metaEl) return;
      metaEl.classList.add("is-active");
      scrambleText(metaEl, metaEl.getAttribute("data-loader-scramble") || metaEl.textContent, {
        duration: 700,
        speed: 32
      });
    }, 600);

    queueTimeline(function () {
      let statusIndex = 1;
      if (statusEl) statusEl.textContent = loaderStatuses[statusIndex];
      statusIndex++;
      statusTimer = setInterval(function () {
        if (statusIndex >= loaderStatuses.length) {
          clearInterval(statusTimer);
          statusTimer = null;
          return;
        }
        if (statusEl) statusEl.textContent = loaderStatuses[statusIndex];
        statusIndex++;
      }, 420);
    }, 900);

    queueTimeline(function () { beginExit(exitDuration); }, activeDuration);
  }

  /* ------------------------------------------------------------
     CONTENT INJECTION
     ------------------------------------------------------------ */
  function injectContent() {
    const c = window.siteContent;
    if (!c) return;

    // Meta / SEO
    document.title = c.meta.title;

    // Header
    document.getElementById("headerName").textContent = c.person.shortName;

    // Nav
    const navEl = document.getElementById("mainNav");
    navEl.innerHTML = "";
    c.nav.forEach(function (item) {
      const a = document.createElement("a");
      a.href = item.target;
      a.className = "nav-link";
      a.dataset.target = item.target;
      a.innerHTML = '<span class="nav-dot" aria-hidden="true"></span><span class="nav-label">' + item.label + "</span>";
      navEl.appendChild(a);
    });

    // Hero name lines
    const heroName = document.getElementById("heroName");
    heroName.innerHTML = "";
    c.person.splitName.forEach(function (word) {
      const span = document.createElement("span");
      span.dataset.finalText = word;
      span.textContent = word;
      heroName.appendChild(span);
    });

    document.getElementById("heroLocation").textContent = c.person.location;
    document.getElementById("heroSubtitle").textContent = c.person.subtitle;
    document.getElementById("heroStatement").setAttribute("data-final", c.person.statement);
    document.getElementById("heroStatement").textContent = c.person.statement;
    document.getElementById("heroFootnote").textContent =
      "[BASED IN JORDAN // WORKING THROUGH ARCHITECTURE, RESEARCH, AND SYSTEMS]";

    const heroImg = document.getElementById("heroImageTag");
    heroImg.alt = c.person.name + " — architectural study";
    markImagePresence(heroImg);

    // Work section
    document.getElementById("workTitle").innerHTML =
      "<span>SE</span><span>LECTED</span><span>W</span><span>O</span><span>RKS</span>";

    const projectList = document.getElementById("projectList");
    projectList.innerHTML = "";
    c.projects.forEach(function (p, idx) {
      const row = document.createElement("article");
      row.className = "project-row";
      row.setAttribute("role", "button");
      row.setAttribute("tabindex", "0");
      row.setAttribute("aria-label", "Open project details: " + p.title);
      row.dataset.index = idx;

      row.innerHTML =
        '<span class="project-number">' + p.number + '</span>' +
        '<div class="project-main">' +
          '<h3 class="project-title">' + p.title + '</h3>' +
          '<p class="project-cat">' + p.category + ' — ' + p.year + '</p>' +
          '<p class="project-desc">' + p.shortDescription + '</p>' +
        '</div>' +
        '<span class="project-arrow" aria-hidden="true">&#8594;</span>' +
        '<div class="project-image-preview placeholder-block" data-label="IMAGE / REPLACE">' +
          '<img src="' + p.image + '" alt="" loading="lazy">' +
        '</div>';

      projectList.appendChild(row);

      const img = row.querySelector(".project-image-preview img");
      markImagePresence(img);

      row.addEventListener("click", function () { openModal(idx); });
      row.addEventListener("keydown", function (e) {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          openModal(idx);
        }
      });
    });

    // Method section
    document.getElementById("methodLabel").textContent = c.method.label;
    document.getElementById("methodTitle").innerHTML = c.method.titleSplit
      .map(function (w) { return "<span>" + w + "</span>"; }).join("");
    document.getElementById("methodHeadline").textContent = c.method.headline;
    document.getElementById("methodIntro").textContent = c.method.intro;

    const methodGrid = document.getElementById("methodGrid");
    methodGrid.innerHTML = "";
    c.method.points.forEach(function (pt) {
      const cell = document.createElement("div");
      cell.className = "point-cell";
      cell.setAttribute("data-reveal", "");
      cell.innerHTML =
        '<span class="point-number">' + pt.number + '</span>' +
        '<h4 class="point-title" data-scramble data-final-text="' + pt.title + '">' + pt.title + '</h4>' +
        '<p class="point-text">' + pt.text + '</p>';
      methodGrid.appendChild(cell);
    });

    // Capabilities
    document.getElementById("capabilitiesLabel").textContent = c.capabilities.label;
    document.getElementById("capabilitiesTitle").innerHTML = c.capabilities.titleSplit
      .map(function (w) { return "<span>" + w + "</span>"; }).join("");
    document.getElementById("capabilitiesIntro").textContent = c.capabilities.intro;

    const capList = document.getElementById("capabilitiesList");
    capList.innerHTML = "";
    c.capabilities.items.forEach(function (item) {
      const row = document.createElement("div");
      row.className = "cap-row";
      row.setAttribute("data-reveal", "");
      row.innerHTML =
        '<span class="cap-marker">' + item.number + '</span>' +
        '<span class="cap-title">' + item.title + '</span>' +
        '<span class="cap-text">' + item.text + '</span>';
      capList.appendChild(row);
    });

    // Profile
    document.getElementById("profileLabel").textContent = c.profile.label;
    document.getElementById("profileTitle").innerHTML = c.profile.titleSplit
      .map(function (w) { return "<span>" + w + "</span>"; }).join("");
    document.getElementById("profileHeading").textContent = c.profile.heading;
    document.getElementById("profileIntro").textContent = c.profile.intro;

    const profileBody = document.getElementById("profileBody");
    profileBody.innerHTML = "";
    c.profile.body.forEach(function (paragraph) {
      const p = document.createElement("p");
      p.textContent = paragraph;
      profileBody.appendChild(p);
    });

    const factList = document.getElementById("profileFacts");
    factList.innerHTML = "";
    c.profile.facts.forEach(function (fact) {
      const li = document.createElement("li");
      li.textContent = fact;
      factList.appendChild(li);
    });

    // Contact
    document.getElementById("contactLabel").textContent = c.contact.label;
    const contactTitle = document.getElementById("contactTitle");
    contactTitle.innerHTML = "";
    c.contact.titleWords.forEach(function (word) {
      const span = document.createElement("span");
      span.dataset.finalText = word;
      span.textContent = word;
      contactTitle.appendChild(span);
    });

    const contactLinks = document.getElementById("contactLinks");
    contactLinks.innerHTML = "";
    c.contact.links.forEach(function (link) {
      const a = document.createElement("a");
      a.href = link.href;
      a.className = "contact-link";
      a.textContent = link.label;
      contactLinks.appendChild(a);
    });

    // Footer
    document.getElementById("footerLeft").textContent = c.footer.left;
    document.getElementById("footerCenter").textContent = c.footer.center;
    document.getElementById("footerRight").textContent = c.footer.right;
    document.getElementById("footerLocation").textContent = c.person.location;
  }

  function markImagePresence(imgEl) {
    imgEl.addEventListener("load", function () {
      if (imgEl.naturalWidth > 0) {
        imgEl.closest(".placeholder-block").classList.add("has-image");
      }
    });
    imgEl.addEventListener("error", function () {
      imgEl.style.display = "none";
    });
  }

  /* ------------------------------------------------------------
     LOCAL TIME
     ------------------------------------------------------------ */
  function updateTime() {
    const c = window.siteContent;
    const tz = (c && c.person && c.person.timezone) || "Asia/Amman";
    const now = new Date();

    const timeStr = new Intl.DateTimeFormat("en-GB", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
      timeZone: tz
    }).format(now);

    const dateStr = new Intl.DateTimeFormat("en-GB", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      timeZone: tz
    }).format(now).toUpperCase();

    const heroTime = document.getElementById("heroTime");
    const heroDate = document.getElementById("heroDate");
    const footerToday = document.getElementById("footerToday");
    if (heroTime) heroTime.textContent = timeStr;
    if (heroDate) heroDate.textContent = dateStr;
    if (footerToday) footerToday.textContent = dateStr;
  }

  /* ------------------------------------------------------------
     NAV — active section + mobile toggle + scramble hover
     ------------------------------------------------------------ */
  function setupNav() {
    const navToggle = document.getElementById("navToggle");
    const mainNav = document.getElementById("mainNav");

    navToggle.addEventListener("click", function () {
      const open = mainNav.classList.toggle("is-open");
      navToggle.setAttribute("aria-expanded", open ? "true" : "false");
    });

    mainNav.querySelectorAll(".nav-link").forEach(function (link) {
      link.addEventListener("click", function () {
        mainNav.classList.remove("is-open");
        navToggle.setAttribute("aria-expanded", "false");
      });

      link.addEventListener("mouseenter", function () {
        const labelEl = link.querySelector(".nav-label");
        scrambleText(labelEl, labelEl.textContent, { duration: 260, speed: 22 });
      });
    });

    const sections = Array.from(document.querySelectorAll("main > section[id]"));
    const links = Array.from(mainNav.querySelectorAll(".nav-link"));

    function setActive() {
      let currentId = sections[0] ? sections[0].id : null;
      const scrollPos = window.scrollY + window.innerHeight * 0.35;
      sections.forEach(function (sec) {
        if (sec.offsetTop <= scrollPos) currentId = sec.id;
      });
      links.forEach(function (link) {
        link.classList.toggle("is-active", link.dataset.target === "#" + currentId);
      });
    }

    window.addEventListener("scroll", throttle(setActive, 100));
    setActive();
  }

  function throttle(fn, wait) {
    let last = 0;
    return function () {
      const now = Date.now();
      if (now - last >= wait) {
        last = now;
        fn();
      }
    };
  }

  /* ------------------------------------------------------------
     SCROLL REVEAL + SCRAMBLE ON VIEWPORT ENTRY
     ------------------------------------------------------------ */
  function setupScrollObservers() {
    const revealObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          revealObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15 });

    document.querySelectorAll("[data-reveal]").forEach(function (el) {
      revealObserver.observe(el);
    });

    const scrambleObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          const el = entry.target;
          const finalText = el.getAttribute("data-final-text") || el.getAttribute("data-final") || el.textContent;
          scrambleText(el, finalText, { duration: 900, speed: 28 });
          scrambleObserver.unobserve(el);
        }
      });
    }, { threshold: 0.4 });

    document.querySelectorAll("[data-scramble]").forEach(function (el) {
      scrambleObserver.observe(el);
    });

    // Hero name + contact title word-by-word scramble
    const heroWordObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        const spans = entry.target.querySelectorAll("span[data-final-text]");
        spans.forEach(function (span, i) {
          scrambleText(span, span.dataset.finalText, {
            duration: 700,
            speed: 26,
            delay: i * 90
          });
        });
        heroWordObserver.unobserve(entry.target);
      });
    }, { threshold: 0.2 });

    const heroName = document.getElementById("heroName");
    const contactTitle = document.getElementById("contactTitle");
    if (heroName) heroWordObserver.observe(heroName);
    if (contactTitle) heroWordObserver.observe(contactTitle);

    // Project rows sequential reveal
    const rowObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.style.transitionDelay = (entry.target.dataset.index % 5) * 0.06 + "s";
          entry.target.classList.add("is-visible");
          rowObserver.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1 });

    document.querySelectorAll(".project-row").forEach(function (row) {
      row.setAttribute("data-reveal", "");
      rowObserver.observe(row);
    });
  }

  /* ------------------------------------------------------------
     PROJECT MODAL
     ------------------------------------------------------------ */
  let lastFocusedEl = null;

  function openModal(index) {
    const c = window.siteContent;
    const p = c.projects[index];
    if (!p) return;

    lastFocusedEl = document.activeElement;

    document.getElementById("modalNumber").textContent = "[" + p.number + "]";
    document.getElementById("modalTitle").textContent = p.title;
    document.getElementById("modalCategory").textContent = p.category;
    document.getElementById("modalYear").textContent = p.year;
    document.getElementById("modalRole").textContent = p.role;
    document.getElementById("modalDescription").textContent = p.description;

    const pointsEl = document.getElementById("modalPoints");
    pointsEl.innerHTML = "";
    p.points.forEach(function (pt) {
      const li = document.createElement("li");
      li.textContent = pt;
      pointsEl.appendChild(li);
    });

    const chipsEl = document.getElementById("modalChips");
    chipsEl.innerHTML = "";
    p.meta.forEach(function (m) {
      const span = document.createElement("span");
      span.className = "modal-chip";
      span.textContent = m;
      chipsEl.appendChild(span);
    });

    const modalImg = document.getElementById("modalImage");
    modalImg.src = p.image;
    modalImg.alt = p.title + " — project image";
    const modalImgWrap = document.getElementById("modalImageWrap");
    modalImgWrap.classList.remove("has-image");
    markImagePresence(modalImg);

    const modal = document.getElementById("projectModal");
    modal.hidden = false;
    requestAnimationFrame(function () {
      modal.classList.add("is-open");
    });
    document.body.style.overflow = "hidden";
    document.getElementById("modalClose").focus();
  }

  function closeModal() {
    const modal = document.getElementById("projectModal");
    modal.classList.remove("is-open");
    document.body.style.overflow = "";
    setTimeout(function () {
      modal.hidden = true;
      if (lastFocusedEl) lastFocusedEl.focus();
    }, 350);
  }

  function setupModal() {
    document.getElementById("modalClose").addEventListener("click", closeModal);
    document.getElementById("modalBackdrop").addEventListener("click", closeModal);

    document.addEventListener("keydown", function (e) {
      const modal = document.getElementById("projectModal");
      if (modal.hidden) return;
      if (e.key === "Escape") closeModal();

      if (e.key === "Tab") {
        const focusable = modal.querySelectorAll(
          'button, a[href], [tabindex]:not([tabindex="-1"])'
        );
        if (!focusable.length) return;
        const first = focusable[0];
        const last = focusable[focusable.length - 1];
        if (e.shiftKey && document.activeElement === first) {
          e.preventDefault();
          last.focus();
        } else if (!e.shiftKey && document.activeElement === last) {
          e.preventDefault();
          first.focus();
        }
      }
    });
  }

  /* ------------------------------------------------------------
     INIT
     ------------------------------------------------------------ */
  let mainSiteAnimationsInitialized = false;

  function initMainSiteAnimations() {
    if (mainSiteAnimationsInitialized) return;
    mainSiteAnimationsInitialized = true;
    setupScrollObservers();
  }

  document.addEventListener("DOMContentLoaded", function () {
    injectContent();
    setupNav();
    setupModal();
    updateTime();
    setInterval(updateTime, 60000);
    window.addEventListener("portfolioIntroComplete", initMainSiteAnimations, { once: true });
    initBinaryLoader();
  });
})();

(function () {
  "use strict";

  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function pad(value) {
    return String(value).padStart(2, "0");
  }

  function modulo(value, length) {
    return ((value % length) + length) % length;
  }

  function initReveals() {
    const items = Array.from(document.querySelectorAll("[data-shila-reveal]"));
    if (!items.length) return;

    document.body.classList.add("shila-motion");

    items.forEach(function (item) {
      const mode = item.dataset.shilaRevealMode || (item.matches("figure") ? "fade" : "text");
      const delay = Number(item.dataset.shilaRevealDelay || 0);
      item.classList.add("shila-reveal-ready");
      item.dataset.shilaRevealKind = mode;
      item.style.setProperty("--shila-reveal-delay", `${Number.isFinite(delay) ? delay : 0}ms`);
    });

    if (reducedMotion || !("IntersectionObserver" in window)) {
      items.forEach(function (item) { item.classList.add("is-visible"); });
      return;
    }

    const observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    }, { rootMargin: "0px 0px -5%", threshold: 0.1 });

    let revealFrame = 0;
    function revealVisibleItems() {
      revealFrame = 0;
      items.forEach(function (item) {
        if (item.classList.contains("is-visible")) return;
        const bounds = item.getBoundingClientRect();
        if (bounds.top < window.innerHeight * 0.95 && bounds.bottom > window.innerHeight * 0.02) {
          item.classList.add("is-visible");
          observer.unobserve(item);
        }
      });
    }

    function scheduleRevealCheck() {
      if (revealFrame) return;
      revealFrame = requestAnimationFrame(revealVisibleItems);
    }

    window.addEventListener("scroll", scheduleRevealCheck, { passive: true });
    window.addEventListener("resize", scheduleRevealCheck, { passive: true });

    items.forEach(function (item) {
      const bounds = item.getBoundingClientRect();
      if (bounds.top < window.innerHeight * 1.03) {
        item.classList.add("is-visible");
      } else {
        observer.observe(item);
      }
    });
    scheduleRevealCheck();
  }

  function prepareClone(slide) {
    const clone = slide.cloneNode(true);
    clone.dataset.galleryClone = "true";
    clone.setAttribute("aria-hidden", "true");
    clone.removeAttribute("data-shila-reveal");
    clone.querySelectorAll("[id]").forEach(function (element) { element.removeAttribute("id"); });
    clone.querySelectorAll("img").forEach(function (image) {
      image.alt = "";
      image.setAttribute("aria-hidden", "true");
    });
    return clone;
  }

  function initGallery(gallery) {
    const viewport = gallery.querySelector(".shila-gallery__viewport");
    const track = gallery.querySelector("[data-gallery-track]");
    const originalSlides = track
      ? Array.from(track.children).filter(function (slide) { return !slide.hasAttribute("data-gallery-clone"); })
      : [];
    const previous = gallery.querySelector("[data-gallery-prev]");
    const next = gallery.querySelector("[data-gallery-next]");
    const counter = gallery.querySelector("[data-gallery-counter]");
    const title = gallery.querySelector("[data-gallery-title]");
    const description = gallery.querySelector("[data-gallery-description]");
    const progress = gallery.querySelector("[data-gallery-progress]");
    if (!viewport || !track || originalSlides.length < 2 || !previous || !next) return;

    const slideCount = originalSlides.length;
    track.prepend(prepareClone(originalSlides[slideCount - 1]));
    track.append(prepareClone(originalSlides[0]));

    let logicalIndex = 0;
    let physicalPosition = 1;
    let pointerId = null;
    let startX = 0;
    let startY = 0;
    let dragX = 0;
    let horizontalDrag = false;
    let animating = false;
    let queuedSteps = 0;
    let transitionTimer = 0;
    let counterValue = counter ? counter.textContent : "";

    function preloadAdjacent() {
      [-1, 1].forEach(function (offset) {
        const candidate = originalSlides[modulo(logicalIndex + offset, slideCount)];
        const image = candidate.querySelector("img");
        if (!image) return;
        const preload = new Image();
        preload.src = image.currentSrc || image.src;
      });
    }

    function updateAccessibleState() {
      originalSlides.forEach(function (slide, slideIndex) {
        slide.setAttribute("aria-hidden", slideIndex === logicalIndex ? "false" : "true");
      });
      const active = originalSlides[logicalIndex];
      if (counter) {
        const nextCounterValue = `${pad(logicalIndex + 1)} / ${pad(slideCount)}`;
        if (nextCounterValue !== counterValue) {
          if (window.PortfolioEnhance && typeof window.PortfolioEnhance.scrambleTo === "function") {
            window.PortfolioEnhance.scrambleTo(counter, nextCounterValue, 320);
          } else {
            counter.textContent = nextCounterValue;
          }
          counterValue = nextCounterValue;
        }
      }
      if (title) title.textContent = active.dataset.title || "";
      if (description) description.textContent = active.dataset.description || "";
      if (progress) progress.style.transform = `scaleX(${(logicalIndex + 1) / slideCount})`;
      previous.disabled = false;
      next.disabled = false;
      previous.removeAttribute("aria-disabled");
      next.removeAttribute("aria-disabled");
      preloadAdjacent();
    }

    function setTrackPosition() {
      gallery.style.setProperty("--gallery-position", physicalPosition);
      gallery.style.setProperty("--gallery-drag", "0px");
    }

    function jumpTo(position) {
      physicalPosition = position;
      gallery.classList.add("is-jump");
      setTrackPosition();
      track.getBoundingClientRect();
      requestAnimationFrame(function () {
        requestAnimationFrame(function () { gallery.classList.remove("is-jump"); });
      });
    }

    function drainQueue() {
      if (!queuedSteps) return;
      const direction = queuedSteps > 0 ? 1 : -1;
      queuedSteps -= direction;
      requestAnimationFrame(function () { move(direction); });
    }

    function finishMove() {
      if (!animating) return;
      window.clearTimeout(transitionTimer);
      animating = false;
      if (physicalPosition === 0) {
        jumpTo(slideCount);
      } else if (physicalPosition === slideCount + 1) {
        jumpTo(1);
      }
      drainQueue();
    }

    function move(direction) {
      if (animating) {
        queuedSteps += direction;
        return;
      }

      gallery.classList.remove("is-jump", "is-dragging");
      logicalIndex = modulo(logicalIndex + direction, slideCount);
      physicalPosition += direction;
      dragX = 0;
      animating = true;
      setTrackPosition();
      updateAccessibleState();

      if (reducedMotion) {
        finishMove();
      } else {
        transitionTimer = window.setTimeout(finishMove, 340);
      }
    }

    function endDrag(event) {
      if (pointerId === null || event.pointerId !== pointerId) return;
      const activePointer = pointerId;
      const threshold = Math.max(42, viewport.clientWidth * 0.12);
      if (viewport.hasPointerCapture && viewport.hasPointerCapture(activePointer)) {
        viewport.releasePointerCapture(activePointer);
      }
      pointerId = null;
      gallery.classList.remove("is-dragging");

      if (horizontalDrag && Math.abs(dragX) >= threshold) {
        move(dragX < 0 ? 1 : -1);
      } else {
        dragX = 0;
        gallery.style.setProperty("--gallery-drag", "0px");
      }
      horizontalDrag = false;
    }

    previous.addEventListener("click", function () { move(-1); });
    next.addEventListener("click", function () { move(1); });

    gallery.addEventListener("keydown", function (event) {
      if (event.key === "ArrowLeft") {
        event.preventDefault();
        move(-1);
      } else if (event.key === "ArrowRight") {
        event.preventDefault();
        move(1);
      }
    });

    viewport.addEventListener("pointerdown", function (event) {
      if (animating || (event.button !== undefined && event.button !== 0)) return;
      pointerId = event.pointerId;
      startX = event.clientX;
      startY = event.clientY;
      dragX = 0;
      horizontalDrag = false;
      viewport.setPointerCapture(pointerId);
    });

    viewport.addEventListener("pointermove", function (event) {
      if (pointerId === null || event.pointerId !== pointerId) return;
      const deltaX = event.clientX - startX;
      const deltaY = event.clientY - startY;
      if (!horizontalDrag && Math.abs(deltaY) > Math.abs(deltaX) && Math.abs(deltaY) > 8) return;
      if (Math.abs(deltaX) > 6) horizontalDrag = true;
      if (!horizontalDrag) return;
      event.preventDefault();
      dragX = deltaX;
      gallery.classList.add("is-dragging");
      gallery.style.setProperty("--gallery-drag", `${dragX}px`);
    });

    viewport.addEventListener("pointerup", endDrag);
    viewport.addEventListener("pointercancel", endDrag);
    track.addEventListener("transitionend", function (event) {
      if (event.target === track && event.propertyName === "transform") finishMove();
    });

    jumpTo(1);
    updateAccessibleState();
  }

  function init() {
    initReveals();
    document.querySelectorAll("[data-gallery-group]").forEach(initGallery);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }
})();

(function () {
  "use strict";

  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function pad(value) {
    return String(value).padStart(2, "0");
  }

  function initReveals() {
    const items = Array.from(document.querySelectorAll("[data-shila-reveal]"));
    if (!items.length || reducedMotion || !("IntersectionObserver" in window)) {
      items.forEach(function (item) { item.classList.add("is-visible"); });
      return;
    }

    document.body.classList.add("shila-motion");
    const observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("is-visible");
        observer.unobserve(entry.target);
      });
    }, { rootMargin: "0px 0px -8%", threshold: 0.06 });

    items.forEach(function (item) { observer.observe(item); });
  }

  function initGallery(gallery) {
    const viewport = gallery.querySelector(".shila-gallery__viewport");
    const slides = Array.from(gallery.querySelectorAll(".shila-gallery__slide"));
    const previous = gallery.querySelector("[data-gallery-prev]");
    const next = gallery.querySelector("[data-gallery-next]");
    const counter = gallery.querySelector("[data-gallery-counter]");
    const title = gallery.querySelector("[data-gallery-title]");
    const description = gallery.querySelector("[data-gallery-description]");
    const progress = gallery.querySelector("[data-gallery-progress]");
    if (!viewport || !slides.length || !previous || !next) return;

    let index = 0;
    let pointerId = null;
    let startX = 0;
    let startY = 0;
    let dragX = 0;
    let horizontalDrag = false;

    function preloadAdjacent() {
      [index - 1, index + 1].forEach(function (candidate) {
        if (candidate < 0 || candidate >= slides.length) return;
        const image = slides[candidate].querySelector("img");
        if (!image) return;
        const preload = new Image();
        preload.src = image.currentSrc || image.src;
      });
    }

    function render() {
      gallery.style.setProperty("--gallery-index", index);
      gallery.style.setProperty("--gallery-drag", "0px");
      slides.forEach(function (slide, slideIndex) {
        slide.setAttribute("aria-hidden", slideIndex === index ? "false" : "true");
      });
      const active = slides[index];
      if (counter) counter.textContent = `${pad(index + 1)} / ${pad(slides.length)}`;
      if (title) title.textContent = active.dataset.title || "";
      if (description) description.textContent = active.dataset.description || "";
      if (progress) progress.style.transform = `scaleX(${(index + 1) / slides.length})`;
      previous.disabled = index === 0;
      next.disabled = index === slides.length - 1;
      previous.setAttribute("aria-disabled", previous.disabled ? "true" : "false");
      next.setAttribute("aria-disabled", next.disabled ? "true" : "false");
      preloadAdjacent();
    }

    function goTo(candidate) {
      index = Math.min(slides.length - 1, Math.max(0, candidate));
      render();
    }

    function endDrag(event) {
      if (pointerId === null || event.pointerId !== pointerId) return;
      const threshold = Math.max(42, viewport.clientWidth * 0.12);
      if (horizontalDrag && Math.abs(dragX) >= threshold) {
        goTo(index + (dragX < 0 ? 1 : -1));
      } else {
        render();
      }
      if (viewport.hasPointerCapture && viewport.hasPointerCapture(pointerId)) {
        viewport.releasePointerCapture(pointerId);
      }
      pointerId = null;
      dragX = 0;
      horizontalDrag = false;
      gallery.classList.remove("is-dragging");
    }

    previous.addEventListener("click", function () { goTo(index - 1); });
    next.addEventListener("click", function () { goTo(index + 1); });

    gallery.addEventListener("keydown", function (event) {
      if (event.key === "ArrowLeft") {
        event.preventDefault();
        goTo(index - 1);
      } else if (event.key === "ArrowRight") {
        event.preventDefault();
        goTo(index + 1);
      }
    });

    viewport.addEventListener("pointerdown", function (event) {
      if (event.button !== undefined && event.button !== 0) return;
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
      const resistingStart = index === 0 && deltaX > 0;
      const resistingEnd = index === slides.length - 1 && deltaX < 0;
      dragX = resistingStart || resistingEnd ? deltaX * 0.28 : deltaX;
      gallery.classList.add("is-dragging");
      gallery.style.setProperty("--gallery-drag", `${dragX}px`);
    });

    viewport.addEventListener("pointerup", endDrag);
    viewport.addEventListener("pointercancel", endDrag);
    render();
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

(function () {
  "use strict";

  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

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
      if (bounds.top < window.innerHeight * 1.03) item.classList.add("is-visible");
      else observer.observe(item);
    });
    scheduleRevealCheck();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initReveals, { once: true });
  } else {
    initReveals();
  }
})();

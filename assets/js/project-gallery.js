(function () {
  "use strict";

  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const pad = function (value) { return String(value).padStart(2, "0"); };
  const modulo = function (value, length) { return ((value % length) + length) % length; };

  function prepareClone(slide) {
    const clone = slide.cloneNode(true);
    clone.dataset.galleryClone = "true";
    clone.removeAttribute("data-image-state");
    clone.setAttribute("aria-hidden", "true");
    clone.querySelectorAll("[id]").forEach(function (element) { element.removeAttribute("id"); });
    clone.querySelectorAll("img").forEach(function (image) {
      image.alt = "";
      image.setAttribute("aria-hidden", "true");
      image.removeAttribute("data-image-lifecycle-ready");
      image.removeAttribute("data-image-retry-count");
      image.loading = "lazy";
      if ("fetchPriority" in image) image.fetchPriority = "low";
    });
    return clone;
  }

  function initGallery(gallery) {
    if (gallery.dataset.galleryReady === "true") return;
    const viewport = gallery.querySelector(".shila-gallery__viewport");
    const track = gallery.querySelector("[data-gallery-track]");
    const slides = track ? Array.from(track.children).filter(function (slide) {
      return !slide.hasAttribute("data-gallery-clone");
    }) : [];
    const previous = gallery.querySelector("[data-gallery-prev]");
    const next = gallery.querySelector("[data-gallery-next]");
    const counter = gallery.querySelector("[data-gallery-counter]");
    const title = gallery.querySelector("[data-gallery-title]");
    const description = gallery.querySelector("[data-gallery-description]");
    const progress = gallery.querySelector("[data-gallery-progress]");
    if (!viewport || !track || slides.length < 2 || !previous || !next) return;

    gallery.dataset.galleryReady = "true";
    const slideCount = slides.length;
    track.prepend(prepareClone(slides[slideCount - 1]));
    track.append(prepareClone(slides[0]));
    if (progress) {
      progress.replaceChildren();
      for (let index = 0; index < slideCount; index += 1) {
        const mark = document.createElement("i");
        mark.setAttribute("aria-hidden", "true");
        progress.appendChild(mark);
      }
    }

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

    function requestSlideImage(index, priority) {
      const image = slides[modulo(index, slideCount)].querySelector("img");
      if (!image) return Promise.resolve(false);
      image.loading = "eager";
      if ("fetchPriority" in image) image.fetchPriority = priority || "low";
      if (image.complete && image.naturalWidth > 0) {
        return typeof image.decode === "function" ? image.decode().then(function () { return true; }).catch(function () { return true; }) : Promise.resolve(true);
      }
      return new Promise(function (resolve) {
        let settled = false;
        function finish(value) {
          if (settled) return;
          settled = true;
          image.removeEventListener("load", loaded);
          image.removeEventListener("error", failed);
          resolve(value);
        }
        function loaded() {
          if (typeof image.decode === "function") image.decode().then(function () { finish(true); }).catch(function () { finish(true); });
          else finish(true);
        }
        function failed() {
          if (Number(image.dataset.imageRetryCount || 0) <= 2) return;
          finish(false);
        }
        image.addEventListener("load", loaded);
        image.addEventListener("error", failed);
        window.setTimeout(function () { finish(image.complete && image.naturalWidth > 0); }, 12000);
      });
    }

    function preloadAdjacent() {
      const adjacent = new Set([
        modulo(logicalIndex - 1, slideCount),
        modulo(logicalIndex + 1, slideCount)
      ]);
      adjacent.forEach(function (index) { requestSlideImage(index, "low"); });
    }

    function updateState(announce) {
      slides.forEach(function (slide, index) {
        slide.setAttribute("aria-hidden", index === logicalIndex ? "false" : "true");
      });
      const active = slides[logicalIndex];
      if (counter) {
        const value = `${pad(logicalIndex + 1)} / ${pad(slideCount)}`;
        counter.textContent = gallery.dataset.galleryCounterFormat === "bare" ? value : `IMAGE ${value}`;
      }
      if (title) title.textContent = active.dataset.title || "";
      if (description) description.textContent = active.dataset.description || "";
      if (progress) Array.from(progress.children).forEach(function (mark, index) {
        mark.classList.toggle("is-active", index === logicalIndex);
      });
      if (announce && gallery.dataset.galleryLabel) gallery.setAttribute("aria-label", `${gallery.dataset.galleryLabel}, image ${logicalIndex + 1} of ${slideCount}`);
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

    function finishMove() {
      if (!animating) return;
      window.clearTimeout(transitionTimer);
      animating = false;
      if (physicalPosition === 0) jumpTo(slideCount);
      else if (physicalPosition === slideCount + 1) jumpTo(1);
      if (queuedSteps) {
        const direction = queuedSteps > 0 ? 1 : -1;
        queuedSteps -= direction;
        requestAnimationFrame(function () { move(direction); });
      }
    }

    function move(direction) {
      if (animating) {
        queuedSteps += direction;
        return;
      }
      animating = true;
      gallery.classList.add("is-slide-loading");
      const targetIndex = modulo(logicalIndex + direction, slideCount);
      requestSlideImage(targetIndex, "high").then(function (ready) {
        gallery.classList.remove("is-slide-loading");
        if (!ready) {
          animating = false;
          gallery.classList.add("has-slide-error");
          queuedSteps = 0;
          return;
        }
        gallery.classList.remove("has-slide-error", "is-jump", "is-dragging");
        logicalIndex = targetIndex;
        physicalPosition += direction;
        dragX = 0;
        setTrackPosition();
        updateState(true);
        if (reducedMotion) finishMove();
        else transitionTimer = window.setTimeout(finishMove, 340);
      });
    }

    function endDrag(event) {
      if (pointerId === null || event.pointerId !== pointerId) return;
      if (viewport.hasPointerCapture && viewport.hasPointerCapture(pointerId)) viewport.releasePointerCapture(pointerId);
      pointerId = null;
      gallery.classList.remove("is-dragging");
      if (horizontalDrag && Math.abs(dragX) >= Math.max(42, viewport.clientWidth * 0.12)) move(dragX < 0 ? 1 : -1);
      else {
        dragX = 0;
        gallery.style.setProperty("--gallery-drag", "0px");
      }
      horizontalDrag = false;
    }

    previous.addEventListener("click", function () { move(-1); });
    next.addEventListener("click", function () { move(1); });
    gallery.addEventListener("keydown", function (event) {
      if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
        event.preventDefault();
        move(event.key === "ArrowLeft" ? -1 : 1);
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
    updateState(false);
    requestSlideImage(0, "high");
  }

  function init() {
    document.querySelectorAll("[data-gallery-group]").forEach(initGallery);
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init, { once: true });
  else init();
  window.addEventListener("pageshow", init);
})();

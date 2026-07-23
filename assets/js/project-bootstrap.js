(function () {
  "use strict";

  var root = document.documentElement;
  var key = String(root.dataset.projectKey || "").trim().toLowerCase();
  var projects = window.siteContent && Array.isArray(window.siteContent.projects)
    ? window.siteContent.projects
    : [];
  var project = projects.find(function (item) {
    return [item.slug, item.id, item.number].some(function (alias) {
      return String(alias || "").trim().toLowerCase() === key;
    });
  });
  var theme = project && project.theme === "manmatic" ? "manmatic" : "light";
  var themeColor = document.querySelector('meta[name="theme-color"]');
  var transitionKey = "ahmad-project-transition-v1";
  var transitionRequest = null;
  var shouldRunTransition = false;

  try {
    transitionRequest = JSON.parse(window.sessionStorage.getItem(transitionKey) || "null");
    window.sessionStorage.removeItem(transitionKey);
    shouldRunTransition = Boolean(
      transitionRequest &&
      transitionRequest.target === window.location.pathname &&
      Date.now() - Number(transitionRequest.startedAt || 0) < 5000 &&
      !window.matchMedia("(prefers-reduced-motion: reduce)").matches
    );
  } catch (error) {
    transitionRequest = null;
    shouldRunTransition = false;
  }

  window.__portfolioProjectLoaderData = project ? {
    number: /^(\d+)\.([a-z])$/i.test(String(project.number || ""))
      ? String(project.number).replace(/^(\d+)\.([a-z])$/i, function (_, number, branch) {
          return number.padStart(3, "0") + "." + branch.toUpperCase();
        })
      : String(parseInt(project.number, 10) || project.number || "").padStart(2, "0"),
    title: project.archiveTitle || project.title || "SELECTED PROJECT",
    subtitle: project.archiveSubtitle || project.type || project.category || "",
    type: project.type || project.category || "PROJECT FILE",
    year: project.year || "ARCHIVE",
    location: project.location || "",
    theme: theme,
    image: project.hero && project.hero.src ? "/" + project.hero.src.replace(/^\/+/, "") : "",
    hasImage: Boolean(project.hero && project.hero.src),
    srcset: project.hero && project.hero.srcset
      ? project.hero.srcset.replace(/(^|,\s*)assets\//g, "$1/assets/")
      : "",
    objectPosition: project.hero && project.hero.loaderObjectPosition
      ? project.hero.loaderObjectPosition
      : "50% 50%"
  } : null;

  root.classList.remove("no-js");
  root.classList.add("js");
  if (shouldRunTransition) {
    root.classList.remove("loader-complete", "loader-skipped", "motion-ready");
    root.classList.add("loader-pending");
  } else {
    root.classList.remove("loader-pending");
    root.classList.add("loader-complete", "loader-skipped", "motion-ready");
  }
  root.dataset.initialTheme = theme;
  root.dataset.siteTheme = theme;
  if (themeColor) {
    themeColor.setAttribute("content", theme === "manmatic" ? "#272727" : "#ffffff");
  }
  if (shouldRunTransition) {
    window.__portfolioLoaderFallback = window.setTimeout(function () {
      if (!root.classList.contains("loader-pending")) return;
      var loader = document.getElementById("loader");
      root.classList.remove("loader-pending");
      root.classList.add("loader-complete", "motion-ready");
      if (loader) {
        loader.hidden = true;
        loader.setAttribute("aria-hidden", "true");
      }
    }, 3200);
  }
})();

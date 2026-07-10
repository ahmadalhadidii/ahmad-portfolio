# Ahmad Alhadidii — Architecture Portfolio

A static editorial architecture portfolio built with semantic HTML, CSS, and vanilla JavaScript. There is no package manager, framework, build step, or required application server.

## Structure

```text
ahmad-portfolio/
├── index.html
├── project.html
├── content.js
├── assets/
│   ├── css/style.css
│   ├── js/main.js
│   ├── js/project.js
│   └── images/
│       ├── architecture-of-elsewhere-1400.jpg
│       └── architecture-of-elsewhere-2400.jpg
└── verify-site-cdp.ps1
```

- `index.html` contains the semantic homepage, complete CV, project index, contact details, and no-script-readable content.
- `content.js` contains the five validated project records shared by the reusable project document.
- `assets/js/main.js` progressively enhances the static pages with the loader, navigation, text reveal, image reveal, and restrained parallax.
- `project.html` is the reusable detail document.
- `assets/js/project.js` resolves a project query and renders only fields that contain real content.
- `assets/css/style.css` holds the shared white editorial system, responsive behavior, reduced-motion rules, and A4 CV print styles.

## Project routes

The selected projects use these canonical routes:

```text
project.html?project=project-01
project.html?project=project-02
project.html?project=project-03
project.html?project=project-04
project.html?project=project-05
```

The renderer also accepts each record’s ID, number, or array position. Unknown keys show a deliberate error page and return link instead of silently opening another project.

Project order in `content.js` controls the homepage route mapping and the previous/next sequence. Keep IDs and slugs unique.

## Media

`ARCHITECTURE OF ELSEWHERE` is supplied in two optimized JPEG sizes and is the homepage focal image. It directly supports the ManMaTIC project and is identified as a shared portfolio visual on the four other project records because their historical image paths were never committed.

When project-specific files become available:

1. Place compressed landscape images in `assets/images/`.
2. Update that project’s `hero.src`, `hero.srcset`, dimensions, alternative text, and caption in `content.js`.
3. Keep the first image eager and any later publication images lazy.
4. Preserve accurate proportions and never list a responsive source that is not present.

There is currently no portrait, CV PDF, or portfolio PDF. The profile grid therefore contains no portrait frame, and document actions remain absent. The complete CV is semantic HTML and prints directly from the browser.

## Loader behavior

The white opening sequence runs once per browser session. It is skipped for reduced-motion visitors, resolves independently of image loading, reveals the site after roughly 1.6 seconds under normal conditions, and has a 2.1-second hard release.

The session key is:

```text
portfolio:intro:editorial-v1
```

Clear that key or start a new browser session when retesting the opening.

## Accessibility and progressive enhancement

- The homepage has one `h1`, ordered section headings, landmarks, a skip link, descriptive image text, visible focus states, and a keyboard-operable mobile menu.
- The CV remains searchable, readable, and printable when JavaScript is unavailable.
- Software and language ratings expose text alternatives such as “4 out of 5.”
- Motion stops under `prefers-reduced-motion: reduce`.
- The mobile menu closes on selection or Escape, contains focus while open, and returns focus to its trigger.
- Contact values use real `mailto:`, `tel:`, LinkedIn, and Instagram destinations.

## Local preview and verification

The pages work from direct `file://` URLs because all internal assets are relative. A local static server can also be used.

Run the repository browser verification from PowerShell:

```powershell
.\verify-site-cdp.ps1
```

The check covers the required viewport set, overflow, white backgrounds, section order, contact destinations, project routes, loader session behavior, reduced motion, the mobile menu, and one reusable detail page.

Before publishing, confirm that every local file reference matches capitalization exactly. This matters on case-sensitive hosts such as GitHub Pages.

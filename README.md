# Ahmad Al Hadidii — Architecture Portfolio

A static, editorial, black-and-white architecture portfolio site. Built with plain HTML, CSS, and vanilla JavaScript — no frameworks, no build step, no npm.

---

## 1. How to edit content

All text, links, and project data live in **`content.js`**. The HTML files only contain structure — `assets/js/main.js` reads `content.js` and injects everything into the page. You never need to touch `index.html` for routine content edits.

Open `content.js` and edit the relevant object inside `siteContent`:

- **`siteContent.person`** — name, title, location, email, hero statement, subtitle.
- **`siteContent.nav`** — the four navigation items (label + target section).
- **`siteContent.projects`** — the array of project entries. Each project has a `number`, `title`, `category`, `year`, `image`, `role`, `shortDescription` (shown in the project list), `description` (shown in the modal), `points` (bullet list), and `meta` (chip tags).
- **`siteContent.method`** — the Method section: label, split title, headline, intro, and four points.
- **`siteContent.capabilities`** — the Capabilities section: label, split title, intro, and list of items.
- **`siteContent.profile`** — the About section: label, split title, heading, intro, body paragraphs, and facts list.
- **`siteContent.contact`** — the Contact section: label, split headline words, email, and link list.
- **`siteContent.footer`** — footer text (left / center / right).
- **`siteContent.meta`** — the page `<title>` fallback and meta description (also update these directly in `index.html`'s `<head>` if you want the raw HTML to match before JS runs).

To **add a new project**, copy an existing object inside the `projects` array, give it the next `number` (e.g. `"006"`), and fill in its fields. It will automatically appear in the Selected Works list and open correctly in the modal — no other file needs to change.

To **reorder projects**, reorder the objects inside the `projects` array.

---

## 2. How to replace images

1. Put your image files inside `assets/images/`.
2. Update the matching `image:` path in `content.js` (for projects) or the `<img>` `src` in `index.html` (for the hero image, `#heroImageTag`).
3. Keep filenames simple: lowercase, no spaces (e.g. `project-manmatic.jpg`).

If an image file is missing or fails to load, the layout will **not break** — a CSS placeholder block (diagonal hairlines + an "IMAGE / REPLACE" label) will show in its place automatically.

Images are displayed in grayscale by default and shift toward full contrast on hover — this is handled in `assets/css/style.css` and needs no JavaScript changes.

---

## 3. How to run locally

- **Simplest:** double-click `index.html` to open it directly in your browser. Everything works with no server.
- **Recommended (for live-reload while editing):** open the folder in VS Code and use the **Live Server** extension, then click "Go Live."

---

## 4. How to publish to GitHub Pages

1. Create a new GitHub repository.
2. Upload all files and folders exactly as they are (`index.html`, `content.js`, `README.md`, and the `assets/` folder) to the repository root.
3. In the repository, go to **Settings → Pages**.
4. Under "Build and deployment," set **Source** to "Deploy from a branch."
5. Set the branch to **main** and the folder to **/ (root)**, then save.
6. Wait a minute for the build to finish, then open the published link shown at the top of the Pages settings.

---

## 5. How to change the font

1. In `index.html`, edit the Google Fonts `<link>` tag inside `<head>` to swap or add font families/weights.
2. In `assets/css/style.css`, edit the font stack variables at the top of the file:

```css
:root {
  --font-main: "Geist", "Space Grotesk", Arial, sans-serif;
  --font-alt: "Space Grotesk", "Geist", Arial, sans-serif;
  --font-mono: "IBM Plex Mono", monospace;
}
```

---

## 6. How to change colors

Edit the CSS custom properties at the top of `assets/css/style.css`:

```css
:root {
  --bg: #f5f3ee;         /* page background */
  --bg-alt: #ebe8df;     /* placeholder / alt background */
  --text: #0f0f0f;       /* primary text */
  --muted: #696969;      /* secondary / caption text */
  --line: rgba(15, 15, 15, 0.18);   /* thin hairline borders */
  --line-strong: rgba(15, 15, 15, 0.88); /* strong borders, active states */
  --accent: #d85c27;     /* orange accent — hover states, numbers, active nav */
}
```

Changing these values updates the whole site automatically — nothing else needs to change.

---

## Notes on structure

```
portfolio-site/
├── index.html          → page structure only (semantic HTML5)
├── content.js           → ALL editable content
├── README.md
└── assets/
    ├── css/style.css    → design system, layout, animation states
    ├── js/main.js        → content injection, scramble text, modal, nav, scroll reveals
    └── images/           → project + hero images (with placeholder.jpg as fallback reference)
```

The scramble text effect, project modal, active-section nav highlighting, local time (Asia/Amman), and scroll reveals are all implemented in vanilla JavaScript in `assets/js/main.js`, with no external libraries. The site respects `prefers-reduced-motion` and is fully keyboard accessible (the project modal traps focus and closes on `Escape`).

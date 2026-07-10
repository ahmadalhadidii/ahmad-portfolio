# Ahmad Alhadidii — Architecture Portfolio

A static architecture portfolio built with HTML, CSS, and vanilla JavaScript. It has no framework, package manager, build command, or application server. The site is ready for GitHub Pages and also works by opening `index.html` directly from the folder.

```text
ahmad-portfolio/
├── index.html
├── content.js
├── README.md
└── assets/
    ├── css/
    │   └── style.css
    ├── js/
    │   └── main.js
    └── images/
        ├── hero.jpg
        ├── project-01-01.jpg
        ├── project-01-02.jpg
        └── ...
```

The `assets/images/` folder may be created when the first real image is added. Until an expected image exists, the portfolio shows a clean architectural replacement frame with its path and image code.

To preview the site, double-click `index.html` or open it from a browser. All internal files use relative paths, so the direct-file version does not need a local server. IBM Plex Mono is requested from Google Fonts when a network connection is available; the site remains usable with its local fallback fonts when offline.

## 1. Edit `content.js`

All portfolio writing, project data, CV entries, image paths, and external links belong in the `siteContent` object in `content.js`. The other files control structure, presentation, and interaction.

Edit values between quotation marks while preserving property names, commas, brackets, and braces. Save `content.js`, then refresh `index.html`; there is no build step.

The main editable groups are:

- `meta` — browser title and page description
- `boot` — opening-screen name, role, index label, and progress values
- `nav` — header labels and section targets
- `person` — name, display name, role, location, timezone, email, and statement
- `hero` — hero image, image code, and caption
- `profile` — biography, facts, and CV link
- `work` — selected-work section number, title, and accordion labels
- `projects` — the six editable project slots and their galleries
- `method` — methods, descriptions, and diagram types
- `cv` — education, experience, awards, skills, and software
- `contact` — closing text and contact/PDF links
- `footer` — copyright, name, and location

Keep the name spelling exact wherever it appears:

```text
Ahmad Alhadidii
AHMAD ALHADIDII
```

The `<title>` and description also have static copies in the `<head>` of `index.html` so they remain available before JavaScript runs. Keep those two values synchronized with `siteContent.meta` when changing them.

Each object in `contact.links` uses `label`, `value`, and `href`. `value` is the text displayed beside the label, while `href` is the destination. Replace both placeholder `"#"` values when adding a real LinkedIn, GitHub, portfolio PDF, or CV PDF link.

## 2. Change the hero image

The hero image is configured in `siteContent.hero`:

```js
hero: {
  image: "assets/images/hero.jpg",
  imageLabel: "0.1",
  caption: "Hero image / replace with selected architectural work"
}
```

To use the default path, place the selected image at:

```text
assets/images/hero.jpg
```

To use `.webp`, `.png`, or `.avif`, change both the filename and the `image` value so they match exactly. Replace the generic caption with a short description of the work; it is used as image context and may also support alternative text.

If `hero.jpg` is missing, the site intentionally shows an architectural placeholder instead of a broken-image icon.

## 3. What `0.1` means

`0.1` identifies the hero image:

```text
0.1 = Hero image 01 = assets/images/hero.jpg
```

Project numbering begins at `1.1`, so the `0` prefix keeps the hero separate from Project 01. Keep `imageLabel: "0.1"` unless the hero image system is intentionally expanded.

## 4. What `1.1`, `1.2`, and `2.1` mean

Project image codes follow `P.I`: the number before the dot is the project, and the number after it is that project's image position. The code is displayed at the bottom-right of its image frame.

```text
1.1 → Project 01 / Image 01 → assets/images/project-01-01.jpg
1.2 → Project 01 / Image 02 → assets/images/project-01-02.jpg
1.3 → Project 01 / Image 03 → assets/images/project-01-03.jpg

2.1 → Project 02 / Image 01 → assets/images/project-02-01.jpg
2.2 → Project 02 / Image 02 → assets/images/project-02-02.jpg
2.3 → Project 02 / Image 03 → assets/images/project-02-03.jpg

3.1 → Project 03 / Image 01 → assets/images/project-03-01.jpg
3.2 → Project 03 / Image 02 → assets/images/project-03-02.jpg
3.3 → Project 03 / Image 03 → assets/images/project-03-03.jpg

4.1 → Project 04 / Image 01 → assets/images/project-04-01.jpg
4.2 → Project 04 / Image 02 → assets/images/project-04-02.jpg
4.3 → Project 04 / Image 03 → assets/images/project-04-03.jpg

5.1 → Project 05 / Image 01 → assets/images/project-05-01.jpg
5.2 → Project 05 / Image 02 → assets/images/project-05-02.jpg
5.3 → Project 05 / Image 03 → assets/images/project-05-03.jpg

6.1 → Project 06 / Image 01 → assets/images/project-06-01.jpg
6.2 → Project 06 / Image 02 → assets/images/project-06-02.jpg
6.3 → Project 06 / Image 03 → assets/images/project-06-03.jpg
```

In general, code `P.I` maps to `assets/images/project-PP-II.jpg`, with two-digit project and image numbers in the filename. Paths are case-sensitive after publishing to GitHub Pages.

## 5. Rename project slots

Each object in `siteContent.projects` represents one project. Replace the neutral title while keeping its unique, zero-padded project number:

```js
{
  number: "01",
  title: "PROJECT SLOT",
  subtitle: "Add project subtitle here",
  year: "2026",
  type: "Architecture / Research / Visual Work",
  status: "Editable",
  description: "Write a short project description here.",
  details: [
    "Add note 01 here.",
    "Add note 02 here.",
    "Add note 03 here."
  ]
}
```

Change `title`, `subtitle`, `year`, `type`, `status`, `description`, and the `details` strings as needed. The JavaScript automatically builds the compact project row and inline project sheet; no matching project markup needs to be added to `index.html`.

## 6. Replace project images

Place each image at the `src` path already assigned in its project object. To replace image `1.1`, add or overwrite:

```text
assets/images/project-01-01.jpg
```

Then give it a meaningful caption in `content.js`:

```js
{
  code: "1.1",
  src: "assets/images/project-01-01.jpg",
  caption: "Ground-floor plan and circulation study"
}
```

The image appears after a refresh. If it is missing or cannot load, the replacement frame continues to show the expected path and code. WebP, PNG, and AVIF are supported by modern browsers; update the complete `src` value when changing an extension. Compress large drawings and renders before publishing, while retaining enough resolution for architectural detail.

## 7. Add more images

Add another complete object to the relevant project's `images` array. A fourth image for Project 01 should be:

```js
{
  code: "1.4",
  src: "assets/images/project-01-04.jpg",
  caption: "Add a meaningful image description"
}
```

Then add the matching file at `assets/images/project-01-04.jpg`. Separate adjacent objects with commas and keep every code unique within its project. Reorder the objects to reorder the gallery; remove a complete object to remove an image.

If a seventh project is added, use project number `"07"`, code `7.1`, and path `assets/images/project-07-01.jpg` for its first image.

## 8. Edit CV, experience, awards, skills, and software

The professional record is stored in `siteContent.cv`. Edit the existing entries in place and preserve the current object or array shape used by each group:

```js
cv: {
  education: [
    "Architecture Student — Al-Balqa Applied University"
  ],
  experience: [
    "BIM Lab — Architecture Training",
    "Publication / Research Support"
  ],
  awards: [
    "Environmental Legacy Makers Award — 1st Place"
  ],
  skills: [
    "Research-Based Design",
    "Concept Development",
    "Spatial Storytelling"
  ],
  software: [
    "Rhino",
    "Grasshopper",
    "Revit"
  ],
  downloadLink: {
    label: "CV / PDF",
    href: "#"
  }
}
```

All five CV categories are arrays of strings. Add, remove, or reorder complete strings to change their display order. Keep dates, institutions, offices, roles, and award names concise. `cv.downloadLink` and `profile.cvLink` each use `{ label, href }`; update those links and the contact CV link when a real PDF is available. A relative PDF path such as `assets/Ahmad-Alhadidii-CV.pdf` works when the PDF is committed with the site; a full `https://` URL can point to an externally hosted file.

## 9. Publish with GitHub Pages

1. Create a GitHub repository and place `index.html`, `content.js`, `README.md`, and the complete `assets` folder at its root.
2. Commit and push the files to the `main` branch.
3. Open the repository on GitHub and go to **Settings → Pages**.
4. Under **Build and deployment**, choose **Deploy from a branch**.
5. Select the `main` branch and `/ (root)` folder, then save.
6. Wait for deployment to complete and open the Pages URL GitHub provides.

Do not rename `index.html`; GitHub Pages uses it as the entry document. Because the site uses relative paths, it works both as a user site and inside a repository subpath. Check filename capitalization carefully—GitHub Pages is case-sensitive even when local Windows previews are not.

No build action or dependency installation is required. Opening `index.html` directly remains the quickest local check; a static server is optional.

## 10. Change the fonts

The site intentionally uses two font-family variables near the top of `assets/css/style.css`:

```css
--font-main: "Suisse Int'l", "Suisse Intl", "Suisse International", "Helvetica Neue", Arial, sans-serif;
--font-mono: "IBM Plex Mono", "Roboto Mono", monospace;
```

`--font-main` controls names, headings, project titles, and paragraph text. Suisse is not included or imported; if a licensed Suisse family is installed on the visitor's device, the browser can use it. Otherwise the stack falls back to Helvetica Neue, Arial, and the system sans-serif. Do not upload or redistribute paid Suisse font files without an appropriate webfont license.

`--font-mono` controls navigation, metadata, image codes, CV labels, and other small technical text. IBM Plex Mono is the only externally requested font and is loaded in `index.html` from Google Fonts. To change it, update both the Google Fonts `<link>` and `--font-mono`, while retaining a local monospace fallback.

## 11. Why only two fonts are used

The two-font system keeps the portfolio calm and recognizably architectural:

- The Suisse-style sans-serif stack gives project writing, headings, and identity text a neutral professional hierarchy.
- IBM Plex Mono distinguishes coordinates, labels, image codes, navigation, and CV metadata without turning the site into a terminal interface.
- Limiting the design to these roles improves consistency, loading performance, and typographic discipline.
- System fallbacks keep the direct-open and offline experience readable without bundling licensed font files.

Avoid adding decorative, rounded, display, or extra UI typefaces. Adjust weight, size, spacing, and layout within the two existing families instead.

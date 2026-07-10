# Ahmad Alhadidii — Architecture Portfolio

A static, editorial architecture portfolio built with semantic HTML, CSS, and vanilla JavaScript. It has no framework, package manager, build step, or application server. The home page presents Profile, CV, Work, Method, and Contact; one reusable project document renders every project from the shared content data.

## File structure

```text
ahmad-portfolio/
├── index.html                  # Home page and section shells
├── project.html                # Reusable project-detail document
├── content.js                  # CMS-style content and media data
├── README.md
└── assets/
    ├── css/
    │   └── style.css           # Home, detail, responsive, and motion styles
    ├── js/
    │   ├── main.js             # Home rendering, boot, header, menu, and theme
    │   └── project.js          # Slug lookup and project-detail rendering
    ├── images/                 # Hero, portrait, project, and responsive variants
    └── documents/              # CV and portfolio PDFs when supplied
```

The image and document folders can be created when real assets are available. Missing configured images use the site's architectural replacement frame rather than a broken-image icon.

## Edit content in `content.js`

`content.js` is the single content source used by both HTML documents. Layout and behavior belong in the HTML, CSS, and JavaScript files; names, writing, metadata, links, and media paths belong in `siteContent`.

The main groups are:

- `meta` — document title and description
- `loader` — opening-screen labels, counter range, and duration
- `nav` — the ordered Profile, CV, Work, Method, and Contact navigation
- `person` — name, discipline, location, timezone, and email
- `hero` — cover identity, cover image, caption, and responsive sources
- `profile` — portrait, position statement, profile paragraphs, metadata, and CV link
- `cv` — structured experience, education, awards, skills, software, languages, certifications, and PDF links
- `work` — selected-work section labels
- `projects` — preview and detail content for every project
- `method` — the five process stages and diagram types
- `contact` — email, social, and document links
- `footer` — copyright identity

Keep the name spelling exact wherever it appears:

```text
Ahmad Alhadidii
AHMAD ALHADIDII
```

Project and link values beginning with `ADD` are deliberate replacement markers, not portfolio claims. Replace them before publishing. Link objects marked `placeholder: true` remain intentionally inactive; after supplying a real destination, set `placeholder` to `false` as well as changing `href` and visible `value` where present.

The static `<title>` and meta description in each HTML file provide a non-JavaScript fallback. Keep the copies in `index.html`, `project.html`, and `siteContent.meta` synchronized when changing the site identity. Project-specific title and description values are applied by `project.js` after a valid project is resolved.

## Project CMS schema

Each object in `siteContent.projects` is one complete project. Array order is the canonical Work order and also determines Previous and Next navigation. Use a unique lowercase ASCII slug with words separated by hyphens.

The implemented schema is:

```js
{
  id: "project-01",
  slug: "project-slug",
  number: "01",
  title: "PROJECT TITLE",
  subtitle: "Optional project subtitle",
  year: "2026",
  location: "Jordan",
  type: "Architecture / Research",
  description: "One concise line for the Work preview.",
  tags: ["Research", "Systems"],

  previewImage: {
    src: "assets/images/project-01-preview.jpg",
    srcset: "assets/images/project-01-preview-960.webp 960w, assets/images/project-01-preview-1600.webp 1600w",
    sizes: "(max-width: 760px) 100vw, 66vw",
    alt: "Describe the visible architectural work.",
    code: "1.0",
    ratio: "16 / 10",
    position: "50% 50%"
  },

  detail: {
    metadata: {
      status: "Academic",
      role: "Architectural Designer",
      team: "Individual project"
    },
    introduction: {
      statement: "Short concept statement.",
      question: "The project question or problem.",
      response: "The main spatial response."
    },
    information: {
      research: "Project-specific research summary.",
      process: "Project-specific process summary.",
      designSystem: "Project-specific design-system summary.",
      technicalDevelopment: "Project-specific technical summary.",
      outcome: "Project-specific outcome."
    },
    images: [
      {
        code: "1.1",
        src: "assets/images/project-01-01.jpg",
        srcset: "assets/images/project-01-01-960.webp 960w, assets/images/project-01-01-1800.webp 1800w",
        sizes: "100vw",
        width: 1800,
        height: 1125,
        ratio: "16 / 10",
        position: "50% 50%",
        type: "drawing",
        alt: "Describe the drawing, plan, section, or image.",
        caption: "Ground-floor plan and circulation study",
        layout: "full"
      },
      {
        code: "1.2",
        src: "assets/images/project-01-02.jpg",
        alt: "Describe the visible work.",
        caption: "Section and environmental logic",
        layout: "half"
      }
    ]
  }
}
```

`layout: "full"` spans the project publication width; adjacent `layout: "half"` items form a controlled two-column sequence where space allows. Keep every `alt` value specific to what is visible; captions explain why an image matters. Media objects support optional `srcset`, `sizes`, `width`, `height`, `ratio`, `position`, `type`, `caption`, and `code` values. Empty optional fields are omitted by the renderer rather than printed as `undefined`.

The detail hero is resolved in this order: `detail.hero`, top-level `hero`, `previewImage`, top-level `preview`, then the first detail/project image. The current records use `previewImage` as both the Work preview and detail opening cover. Add a separate `detail.hero` object when the full project needs a different crop or source.

For more complex future publications, the renderer also accepts structured `detail.narrative` blocks and information arrays. The primary editable schema above remains the simplest shape for the six current projects.

To add a project:

1. Duplicate one complete object in `siteContent.projects`.
2. Assign a unique `slug` and zero-padded `number`.
3. Replace every preview, detail metadata, introduction, information, and image value.
4. Add the matching images and responsive variants.
5. Open its generated Work link and verify Previous/Next order.

Do not add matching project markup to `index.html` or create another detail HTML file. Both views are generated from the shared object.

## Project URLs and invalid slugs

Every Work preview is a normal link to the reusable template:

```text
project.html?project=project-slug
```

`project.js` reads the `project` query parameter, finds the matching `slug` in `siteContent.projects`, and renders that project's publication-style detail page. For compatibility it can also resolve the project's `id`, zero-padded number, or array index and accepts `slug` or `id` as fallback query-parameter names; the canonical public link remains `?project=<slug>`. Query strings work when navigating from a direct `file://` preview and on GitHub Pages because the scripts and assets use relative paths.

An absent, unknown, or malformed slug does not silently load the first project. The template displays a deliberate Project Not Found state with a link back to `index.html#work`.

Changing a slug changes its public URL. Update any external links or bookmarks that use the previous value. Slugs must be unique; duplicate slugs make project selection ambiguous. Previous and Next navigation follows the array order and wraps at either end; Project Index returns to `index.html#work`.

## Hero, portrait, and responsive images

The fallback image paths are:

```text
assets/images/hero-cover.jpg
assets/images/portrait.jpg
assets/images/project-01-preview.jpg
assets/images/project-01-01.jpg
assets/images/project-01-02.jpg
```

The filename is not hard-coded as a rule: the authoritative path is the relevant `src` value in `content.js`. A consistent responsive naming convention is recommended:

```text
hero-cover-960.webp
hero-cover-1600.webp
hero-cover-2400.webp

portrait-480.webp
portrait-800.webp

project-01-preview-960.webp
project-01-preview-1600.webp
project-01-01-1200.webp
project-01-01-2400.webp
project-01-02-960.webp
project-01-02-1800.webp
```

List each available variant in that media object's `srcset`, including its real width descriptor, and set an appropriate `sizes` value. Keep a broadly supported JPEG fallback in `src`. Do not list a file that has not been added.

The home hero and project-detail opening image load eagerly at high priority. Portraits, Work previews below the fold, drawings, and later project images load lazily. The CSS media frames reserve stable aspect ratios so replacing an image does not cause layout shift. Compress renders and drawings while preserving enough detail for architectural review.

## CV data: verified limits

No CV reference image or CV PDF was present in the supplied files. The website therefore uses only the professional information that could be verified from the available text:

- Architecture Student — Al-Balqa Applied University
- BIM Lab — Architecture Training
- Publication / Research Support
- Environmental Legacy Makers Award — 1st Place
- The supplied design-strength, technical-skill, and software names

Dates, locations, institutions beyond the one named above, responsibility descriptions, proficiency levels, additional experience, awards, and certifications must not be inferred. Add them only after checking the source CV exactly.

`cv.languages` and `cv.certifications` intentionally remain empty arrays until verified information is supplied. Their editorial groups remain visible with a neutral dash so the structure is ready without implying unsupported facts. Empty data is preferable to invented professional claims.

CV records use structured objects rather than display-only row strings. Preserve the existing property names for index, role or qualification, institution, location, date, and description. Leave an unverified optional value empty; do not substitute generic copy.

## Contact links and PDFs

Replace placeholder destinations in `profile.cvLink`, `cv.links`, and `contact.links`. A typical local document setup is:

```js
links: {
  view: {
    label: "VIEW CV",
    href: "assets/documents/Ahmad-Alhadidii-CV.pdf",
    placeholder: false
  },
  download: {
    label: "DOWNLOAD CV / PDF",
    href: "assets/documents/Ahmad-Alhadidii-CV.pdf",
    placeholder: false
  }
}
```

Then add the actual file at the same case-sensitive path. Use the equivalent pattern for `assets/documents/Ahmad-Alhadidii-Portfolio.pdf`.

Contact destinations should use:

- `mailto:` for email
- complete `https://` URLs for LinkedIn, GitHub, and Instagram
- relative `assets/documents/...` URLs for committed PDFs, or complete HTTPS URLs for externally hosted documents

Update both the visible `value` and the destination `href`, then set `placeholder: false`. Do not publish links whose destination is still `#` or empty. If an external link opens a new tab, retain `rel="noopener noreferrer"`.

## Opening sequence and session behavior

The black calibration/loading sequence belongs only to `index.html`. It plays once per browser session, lasts approximately 1.8–2.5 seconds, counts from `000` to `100`, and progressively reveals the hero. A marker in `sessionStorage` prevents it from replaying on same-session reloads or after visiting a project and returning home.

Project pages never play the boot sequence. Reduced-motion visitors skip it. If storage is blocked or unavailable—possible in restrictive direct-file browser settings—the site fails safely by revealing the page instead of repeatedly trapping the visitor in the loader.

Close the tab/browser session or clear `portfolio:intro:v3` from browser session storage when the first-visit animation needs to be tested again. If the sequence is intentionally revised, version this key in both the inline head check and the documentation.

## Scroll theme, mobile navigation, and accessibility

The home page transitions from an off-white Profile/CV environment to a near-black Work/Method environment and returns to off-white near Contact. The scroll handler updates the theme through animation-frame scheduling; the adaptive header changes foreground and surface treatment to maintain contrast.

The fixed header is transparent over the hero and gains a restrained surface after scrolling. On small screens, the navigation is controlled by a real menu button with `aria-expanded` and `aria-controls`. The menu closes on Escape, link activation, or return to a desktop width, and focus returns to the button.

When editing the site:

- Keep the section and navigation order `PROFILE`, `CV`, `WORK`, `METHOD`, `CONTACT`.
- Preserve semantic headings, landmarks, figure captions, visible focus styles, the skip link, and meaningful image alternatives.
- Keep links and menu controls keyboard accessible with comfortable touch targets.
- Verify text, dividers, focus indicators, and the header against both light and dark backgrounds.
- Do not remove reserved media ratios; they prevent layout shift.
- Respect `prefers-reduced-motion`; boot, reveal, transition, and hover movement should become immediate or stop.
- Test at approximately 360, 768, and 1440 pixels wide and confirm there is no horizontal overflow or tiny technical text.

## Preview locally

The quickest preview is to open `index.html` directly. Follow any Work preview link to test `project.html?project=...`; no server is required because the site uses classic deferred scripts and relative paths.

A local static server is optional and can make URL inspection more familiar. From the project root, use any static server you already trust, then open its `index.html`. There is no install or build command specific to this project.

IBM Plex Mono is requested from Google Fonts when a network connection is available. Local font fallbacks keep the site readable offline.

Before publishing, test:

- the home section order and active navigation
- first-load and same-session boot behavior
- the light/dark/light scroll transition
- every project URL, including an invalid slug
- Previous, Work Index, and Next navigation
- missing-image fallbacks and responsive source selection
- mobile menu keyboard behavior and focus return
- reduced motion, document links, social links, and both PDFs
- browser console output and horizontal overflow

## Publish with GitHub Pages

1. Keep `index.html`, `project.html`, `content.js`, `README.md`, and the complete `assets` folder at the repository root.
2. Commit and push them to the `main` branch.
3. In the repository, open **Settings → Pages**.
4. Under **Build and deployment**, select **Deploy from a branch**.
5. Select `main` and `/ (root)`, then save.
6. Open the generated Pages URL and repeat the preview checks above.

Do not rename `index.html`; GitHub Pages uses it as the entry document. Keep internal paths relative, such as `assets/images/hero-cover.jpg` and `project.html?project=project-slug`. Leading-slash paths such as `/assets/...` break repository-subpath deployments and direct-file previews. Filename capitalization must match exactly because GitHub Pages is case-sensitive even when a local Windows preview is not.

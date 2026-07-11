# Ahmad Alhadidii — Architecture Portfolio

A static editorial architecture portfolio built with semantic HTML, CSS, and vanilla JavaScript. There is no package manager, framework, build step, or required application server.

The interface keeps a predominantly white architectural-document base, then moves the complete viewport into a dark ManMaTIC operating state while that project is dominant. Restrained computer-operated motion includes the activation loader, continuously active monitor, heading assembly, word-level reading fields, project-image signals, portrait placeholder pixels, and Visual Studies slider. The production type system uses exactly two named font families: IBM Plex Sans for readable and display copy, and IBM Plex Mono for navigation, metadata, controls, codes, and system readouts.

## Repository structure

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
├── inspect-reference.ps1
├── inspect-reference-cdp.ps1
├── verify-site-cdp.ps1
└── CNAME
```

- `index.html` contains the semantic homepage, loader markup, opening monitor/showreel, profile, complete CV, five-project archive, a no-script Visual Studies fallback, contact information, and closing identity.
- `content.js` is the editable data source for the five reusable project records and six Visual Studies records.
- `assets/js/main.js` progressively enhances both documents with the loader, navigation, showreel, text scanning, image and section reveals, pointer-responsive headings, Visual Studies slider, active-project state, and restrained scroll effects.
- `project.html` is the reusable project-detail shell. It resolves its initial light or ManMaTIC theme before the main stylesheet renders.
- `assets/js/project.js` resolves a project query, renders only populated fields, updates page metadata, and builds cyclic previous/next navigation.
- `assets/css/style.css` contains the two-font visual system, loader and monitor treatments, contained ManMaTIC field, Visual Studies layout, responsive and safe-area rules, reduced-motion behavior, and A4 CV print styles.

## Homepage architecture

The homepage preserves this reading order:

1. Header and navigation, including the external `MANMATIC FIELD ↗` link.
2. Ahmad Alhadidii identity, professional roles, and opening monitor/showreel.
3. Architecture of Elsewhere concept statement.
4. Profile.
5. Curriculum Vitae.
6. Visual Studies.
7. Selected Work project archive.
8. Contact, closing `AHMAD ALHADIDII` identity, and the compact copyright/location/back-to-top row.

The homepage project rows remain semantic HTML so the archive is readable without JavaScript. Project detail content and Visual Studies are enhanced from `content.js`; when editing a project, keep its homepage summary synchronized with the corresponding data record.

## Font system

Both HTML documents request only:

- **IBM Plex Sans** — headings, paragraphs, project descriptions, profile and CV copy, contact statements, and Visual Studies interpretation.
- **IBM Plex Mono** — navigation, labels, dates, metadata, buttons, loader values, captions, and technical readouts.

The CSS exposes these as `--font-sans` and `--font-mono`. Generic `sans-serif` and `monospace` fallbacks remain for font-network failure; Source Serif 4 and other named families are not part of the production system.

## Loader behavior

The system-activation loader is present on both the homepage and reusable project document.

- Every full document refresh starts at `000` and visibly progresses to `100`.
- No `sessionStorage` or `localStorage` value suppresses or persists the sequence.
- Same-document anchor navigation does not restart the loader; navigating to another HTML document does.
- Normal motion uses staged progress with a minimum progression of about 1.88 seconds, followed by the mechanical opening transition.
- Readiness is gated by the local architectural preview and `document.fonts.ready`. Each wait has a bounded fallback so a failed image or remote font cannot trap the page.
- JavaScript enforces an approximately 3-second maximum, while the inline 3.2-second release is the final protection if initialization fails before the main script can clean up.
- At completion, the binary layer is removed and the loader is hidden and removed from the accessibility tree.
- Under `prefers-reduced-motion: reduce`, binary streams and scanning motion are suppressed and the same `000` to `100` state resolves in a short roughly 280–640 ms path.
- With JavaScript disabled, the loader is hidden and the semantic homepage remains available.

The counter is an interface status value and is not announced on every increment; assistive technology receives only the concise initialization and ready messages.

## Visual Studies

`siteContent.visualStudies` in `content.js` drives the slider. Each record supports an index, title, interpretation, related project, year, category, local image, responsive sources, dimensions, crop position, caption, and alternative text.

The current six studies use different `objectPosition` crops of the local Architecture of Elsewhere board. They are honest shared-board studies, not separate project images. JavaScript replaces the single semantic fallback slide with the data records and provides:

- Previous and next buttons.
- Current/total and progress indicators.
- Left/right keyboard navigation while the region is focused.
- Mouse drag and touch swipe through Pointer Events.
- Vertical-page scrolling preservation through `touch-action: pan-y pinch-zoom`.
- No automatic advancement.

To add a final study image, place an optimized local file in `assets/images/` and update that one data record rather than adding per-slide JavaScript.

## ManMaTIC field

The ManMaTIC row begins as a black operational field. When it becomes dominant in the viewport, JavaScript switches the root and body theme tokens so the page, sticky header, navigation, text, rules, captions, and ambient field all invert together. Hysteresis keeps the state stable while scrolling and restores the white portfolio field after leaving. The reusable ManMaTIC project route remains dark by default.

`https://www.manmatic.institute/` is linked from both page headers and from the ManMaTIC field. These links open in a new tab with `rel="noopener noreferrer"` and meaningful accessible labels.

## Project routes

The public project IDs and route mapping are:

| Archive file | Canonical route | Project |
| --- | --- | --- |
| 01 | `project.html?project=project-05` | Shila Museum — The Quarry That Folds Inward |
| 02 | `project.html?project=project-01` | ManMaTIC — Human–Machine Integration Institute |
| 03 | `project.html?project=project-02` | From Concrete Fatigue to Green Asset |
| 04 | `project.html?project=project-03` | Ground of Continuity |
| 05 | `project.html?project=project-04` | The Mechanics of Becoming |

The renderer also accepts a record's slug, ID, archive number, or array position. Unknown keys show a deliberate Project Not Found state instead of silently resolving to another record. Array order in `content.js` controls previous/next project navigation; keep IDs and slugs unique and stable.

## Media and known missing assets

The repository currently contains only two image files:

| Asset | Dimensions | Current use |
| --- | ---: | --- |
| `architecture-of-elsewhere-1400.jpg` | 1400 × 754 | Loader preview, responsive project/archive imagery |
| `architecture-of-elsewhere-2400.jpg` | 2400 × 1293 | Opening board, reusable project hero, Visual Studies source |

Architecture of Elsewhere directly supports ManMaTIC. It is explicitly labelled as a shared portfolio visual for the other four project records because their historical project-specific images were never committed:

- Shila Museum — The Quarry That Folds Inward.
- From Concrete Fatigue to Green Asset.
- Ground of Continuity.
- The Mechanics of Becoming.

Dedicated Visual Studies images are also not present; the current studies intentionally use three crops of the shared board. Replace those data entries when final local studies become available.

There is still no final portrait, CV PDF, portfolio PDF, or showreel video. The Profile now contains an explicitly labelled rectangular portrait placeholder using a temporary crop of the local board so its proportions and one-shot pixel assembly can be evaluated without presenting it as Ahmad's portrait. Document-download actions remain absent, the CV prints from semantic HTML, and the opening monitor uses its local six-frame fallback slideshow.

When adding media:

1. Place compressed files in `assets/images/`.
2. Update the relevant `hero` or `visualStudies` record in `content.js`, including dimensions, alternative text, caption, `srcset`, and crop position where appropriate.
3. Synchronize the corresponding static homepage project image when replacing a project visual.
4. Preserve accurate intrinsic dimensions and never reference a responsive source that is not committed.

## Accessibility and progressive enhancement

- The homepage retains one `h1`, ordered section headings, landmarks, skip navigation, descriptive image text, visible focus states, and a keyboard-operable mobile menu.
- The CV remains searchable, readable, and printable without JavaScript.
- Software and language ratings expose text alternatives such as “4 out of 5.”
- Reduced-motion mode removes binary streams, scan effects, scrambling, slider signal interruptions, smooth scrolling, and reveal displacement.
- The mobile menu closes on selection or Escape, contains keyboard focus while open, and restores body scrolling when closed.
- Contact values use real `mailto:`, `tel:`, LinkedIn, and Instagram destinations.

## Version-control checkpoint

The pre-redesign baseline is preserved on:

```text
codex/pre-digital-interface-20260711
386c0af09b1fd4bad82b1153ea00a12353a6990d
```

Keep this branch until the redesigned interface has been accepted and published. It is the recovery point for the exact portfolio state that existed before the digital-interface implementation.

The exact state immediately before the animated-heading and text-darkening restoration is preserved on:

```text
codex/pre-heading-text-darkening-20260711
ded0821e1e79eb92e21217261765a2c58cce570e
```

## Local preview and verification limits

All internal paths are relative, so the pages can open through `file://`; a local static server is preferable for final browser testing.

The repository includes a Windows Chrome/CDP regression script:

```powershell
.\verify-site-cdp.ps1
```

If local PowerShell policy blocks direct script execution, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\verify-site-cdp.ps1
```

The current verifier is a legacy partial harness and is **not yet an authoritative release gate for the redesigned interface**. It currently:

- Uses a hard-coded Windows Chrome installation and CDP device emulation, not real iOS Safari, Android Chrome, Firefox, or physical touch hardware.
- Covers only `1920×1080`, `1440×900`, `1366×768`, `1024×768`, `768×1024`, `430×932`, `390×844`, and `360×800`.
- Still asserts the removed session-skipping loader, a release below 1.4 seconds, a reduced-motion loader skip, and the old five-label navigation.
- Does not validate the new `000` to `100` asset-gated loader contract, repeated-refresh replay, Visual Studies controls/drag/swipe, the external ManMaTIC item, the closing identity, or the complete requested portrait and landscape matrix.
- Checks local structure and link presence but does not prove that external services are reachable from every deployment environment.

Until the harness is updated, use it only for the unaffected structural checks and perform the redesigned interaction, reduced-motion, overflow, touch, orientation, and cross-browser checks manually. Before publishing, also confirm that every local file reference matches capitalization exactly; GitHub Pages hosts are case-sensitive.

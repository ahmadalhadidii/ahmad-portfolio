# Strict portfolio cleanup — second pass

Implemented in the existing workspace. Existing first-pass changes were preserved. Nothing has been deployed.

## Exact implementation files changed

| File | Second-pass change |
| --- | --- |
| `index.html` | Removed the ornamental threshold SVG and its DATUM LOCKED caption, monitor status labels, fake signal readout, showreel file/system labels, portrait axes/coordinates/registration marks, bracket markers, section-number prefixes, redundant card file labels, ornamental CV identifiers, computational connector arrow, and SIGNAL SYNC banner. Removed arrow glyphs from the related-project entry labels while preserving their anchors. Replaced only the large final name display with the supplied GIF. |
| `content.js` | Removed the ornamental portrait file label and SUBJECT RECORD prefix from the shared data that JavaScript uses to refresh the caption. No project records, narratives or images were changed. |
| `assets/js/main.js` | Removed generation/update code for deleted loader and monitor readouts, the visual-entry arrow, and decorative visual scan spans. Simplified playback wording to PLAY/PAUSE and kept the existing playback logic. Removed the final name container from heading-text animation. Simplified ornamental running-caption wording without altering navbar menu behavior. |
| `assets/js/project.js` | Matched the existing project renderer to text-only Previous/Next and Back to ManMaTIC controls; removed file-number labels and their unused formatting helper; used canonical archive names for visible navigation titles. Kept destinations and project order. |
| `assets/css/style.css` | Deleted the removed elements' rules, pseudo-elements, threshold path animations, heading connector rules, and unused entry-action treatments, including their responsive variants. Scoped spacing preserves the measured original layout. Added responsive GIF sizing without a new frame/background. Retained the graph's original grid column after deleting its adjacent decorative arrow. |
| `assets/css/dabouq.css` | Removed the unused opening file-label rule. |
| `projects/shila/index.html` | Text-only project navigation and footer return; removed the file prefix in the running caption and used the canonical Shila (Stone) Museum name. |
| `projects/dabouq/index.html` | Removed the opening PROJECT FILE label and running-caption file prefix; matched text-only navigation and return wording. |
| `projects/concrete-fatigue/index.html` | Matched text-only navigation and footer return; simplified the running caption and used ELMA — TREE UNIT. |
| `projects/manmatic/index.html` | Removed decorative loader status/readout markup; simplified the running caption, bottom return and related-resource arrow glyphs. Kept the editorial board, images, section structure and meaningful research vocabulary. |
| `projects/protocol-port/index.html` | Matched return-link wording to BACK TO MANMATIC and removed ornamental footer arrows. Preserved both return destinations and the entire project board. |
| `scripts/generate-project-pages.ps1` | Synchronized generated file-free captions, text-only project navigation and return labels so generation does not restore the deleted UI. |
| `assets/images/ahmad_name_old_printer_transparent.gif` | Added an unchanged byte-for-byte copy of the supplied Downloads attachment. |

## Connectors and project-entry controls

Removed the local decorative threshold SVG axes/arcs/terminals/datum/scale/scan implementation and its animation rules; section-heading connector pseudo-elements; contact-heading rule markup; portrait axes and registration linework; and the free-standing computational arrow. The existing threshold container's authored height remains as whitespace so ManMaTIC does not move or resize.

Removed ornamental arrows from the Field/Protocol Port entry treatments and Previous/Next/return labels. Removed the dynamic and fallback Visual-entry arrow while preserving that distinct destination link. Removed obsolete `.project-row__action` styles. No OPEN PROJECT/VIEW PROJECT text existed in the primary cards at this pass's baseline; those cards remain whole-card anchors.

No blanket `display:none` workaround was added for these removals. Their markup, generating code, or pseudo-element implementations were deleted.

## Meaningful exceptions retained

- Project years, locations, types, descriptions, metadata, image sequence and actual technical specifications.
- One archive number per primary project, functional showreel/gallery image counters, and gallery buttons/keyboard controls.
- The real PLAY/PAUSE control and loader progress/lifecycle.
- ManMaTIC's actual research chapters, methodology diagrams and process arrows.
- Field and Protocol Port links, the live Field preview, and its genuine live/external identification.
- The main navigation menu, including its existing external-link indicator; functional social links and Back to Top.
- Linework in architectural image assets and the embedded external ManMaTIC Field research graph. That graph is meaningful project content, not a local decorative connector component.

## GIF integration

The GIF replaces `.closing-identity`'s large text immediately above the homepage copyright footer. It is not added to unrelated project footers. It has `width="1100"`, `height="260"`, `alt="Ahmad Alhadidii"`, responsive proportional scaling and no new border/background. The original animation and alpha transparency were preserved.

SHA-256: `91c9b05ab6a5aa4eaadeb4ed704cd1b8ffd8c9bdeeaf31a72cced0577c6a6619`

Verified 40 frames; original frame dimensions 1100 × 260; transparency present; source and copied file hashes identical. Browser screenshots taken 900ms apart changed pixels, confirming actual animation at desktop, tablet and mobile sizes.

## Verification results

- **135 focused assertions passed:** exact before/after project geometry at 1440/390px, no overflow, unchanged media markup except the added GIF, unchanged navbar menu markup, preserved destinations/order, mobile menus/Escape, keyboard focus, no nested controls, resolving card/footer destinations, gallery buttons/arrow keys, Protocol Port return and browser history. No uncaught JavaScript errors.
- **Exact homepage geometry matched at 1440, 820 and 390px:** opening section, showreel housing/screen, profile section/layout, CV, work section, ManMaTIC card/copy/category. Widths, heights and page positions matched the second-pass baseline; scoped whitespace compensates for removed labels.
- **Source and rendered DOM checks passed:** targeted monitor/loader statuses, PROJECT FILE/SYSTEM labels, DATUM LOCKED, SIGNAL SYNC, bracket labels, entry-action elements and heading connector pseudo-elements were absent. A caption reintroduced by `content.js` was found during visual review and corrected at its data source.
- **Existing Protocol Port suite: 134 assertions passed** at 390, 768, 1024 and 1440px, including project image order, slow mobile loading, gallery controls, browser history and no console errors. Its first concurrent run timed out on throttled image loading; the isolated rerun passed.
- **Existing Visual route suite: 99 assertions passed.**
- **Isolated UTF-8 project generation passed:** four generated pages with valid text-only navigation; the generator preserved its custom Protocol Port page. Production hand-composed pages were not regenerated.
- JavaScript syntax checks passed for `content.js`, `main.js` and `project.js`; Git whitespace check passed.
- No package manifest or configured lint/type-check command exists in this static HTML/CSS/JavaScript repository.
- Desktop/mobile screenshots of all five project footers and the work section were compared. Opening, profile, related ManMaTIC presentation and GIF footer were additionally captured at 1440, 820 and 390px and visually inspected. Evidence is in this directory, including `before.json`, `after.json`, `checks.json`, `geometry.json` and `visual-checks.json`.

## Scope and remaining inspection

Routes, project ordering, primary-card destinations, project media, project narratives, global fonts/colours, responsive breakpoints, scrolling logic, navbar menu and gallery logic were preserved. ManMaTIC retained its measured original container sizes, image proportions/cropping and horizontal composition; its decorative threshold overlay alone was removed.

The embedded external ManMaTIC Field site's own graph UI remains visible and was not edited or exhaustively tested. Browser verification covers the local pages and viewport sizes listed above, not every possible device or external destination.
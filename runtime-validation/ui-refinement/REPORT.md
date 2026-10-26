# Portfolio UI refinement

Implemented locally without redesigning the site.

## Changes by file

- `assets/css/style.css`: removed decorative scan-stripe overlays and their unused animation from non-ManMaTIC project images. Refined only project-footer navigation: smaller titles and padding, no enclosing bottom/vertical borders, subtle link hover and explicit keyboard focus. Existing responsive stacking remains.
- `index.html`: changed the redundant showreel caption to SELECTED PROJECTS; standardized project file/system numbers to three digits, including 002.B. Main card titles, media, destinations, dimensions and interactions remain unchanged.
- `projects/shila/index.html`, `projects/dabouq/index.html`, `projects/concrete-fatigue/index.html`: removed numerical metadata from Previous/Next labels and retained their exact destination/order. Consolidated the footer's return controls to WORK INDEX; the portfolio-root destination remains in the site footer and main navigation. Dabouq's opening file label now uses 003.
- `projects/manmatic/index.html`, `projects/protocol-port/index.html`: applied the same WORK INDEX treatment in the existing bottom navigation. Preserved all special ManMaTIC return and Field/Protocol Port links. No editorial section was changed.
- `assets/js/project.js`: synchronized generated navigation labels, retained descriptive accessible labels, used canonical archive names for visible navigation titles, and standardized file numbers to three digits.
- `scripts/generate-project-pages.ps1`: synchronized generated navigation presentation; removed unused number-format arguments. Generation was checked in a temporary directory to preserve the hand-composed project pages.

## Findings preserved intentionally

- No literal elbow connector paths or redundant OPEN PROJECT / VIEW PROJECT controls were found in the current project cards. No removal is claimed for absent elements.
- ManMaTIC's authored threshold graphic, technical research vocabulary, Field window, distinct resource links and landscape composition were preserved.
- The actual monitor and loading/interaction readouts were retained where their purpose was clear.

## Verification

- Captured before/after screenshots of the homepage work section and all five project footers at 1440px and 390px widths (24 screenshots in this directory).
- Exact before/after geometry matched for the homepage project rows and sampled ManMaTIC containers, sections and images at both widths. No horizontal overflow on any of the six pages.
- Focused browser/source verification: 135 assertions passed, no uncaught JavaScript errors. Covered unchanged media markup and global headers; preserved link destinations/order; mobile menus and Escape; keyboard focus and nested-control checks; resolving card/footer destinations; gallery buttons and arrow-key behavior; Protocol Port return and browser history.
- Existing Protocol Port suite: 134 assertions passed across 390, 768, 1024 and 1440px widths, including image order, slow loading and history navigation.
- Existing Visual route suite: 99 assertions passed.
- JavaScript syntax and Git whitespace checks passed.
- Isolated UTF-8 project generation: four pages generated with valid footer navigation. Custom Protocol Port page was preserved by the generator.
- No package manifest or configured lint/type-check command exists in this static HTML/CSS/JavaScript project.

## Older checks that did not pass

- `verify-clean-home-urls.ps1` expects `.project-header__system-nav` on Protocol Port; the existing custom page uses `.protocol-port-identity`. The actual return links were independently verified and preserved.
- `verify-manmatic-regression.ps1` stopped at line 190 because its browser evaluation returned null before JSON conversion. Focused before/after geometry and functional checks passed; this older suite is not reported as passing.

This verification covers the tested local pages and viewports. The site has not been deployed.
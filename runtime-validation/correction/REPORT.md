# Portfolio corrective implementation

Implemented in the existing workspace. This is a selective correction of the previous passes; no deployment was performed.

## Restored original elements

- Restored the exact `.manmatic-threshold__mark` SVG from Git HEAD, including its original paths, viewBox, stroke styles, animation rules, reduced-motion treatment and mobile width. Its original threshold container, alignment and dimensions were retained. The unrelated DATUM LOCKED caption was not restored.
- Restored the original text in `.closing-identity` after removing the misplaced GIF.
- Aligned the desktop ManMaTIC archive number with the title's baseline. Scoped spacing after removal of the branch CTA labels preserves the locked ManMaTIC dimensions.

## Removed the actual unwanted rendering

- Deleted VIEW VISUAL from both the static homepage fallback and `initVisuals()` in `main.js`.
- Wrapped each actual Visual image in a keyboard-accessible anchor to its own existing detail URL. Inactive slide links remain outside the tab order. Existing manual navigation and swipes remain functional; dragging a linked image does not accidentally navigate.
- Removed the complete `.visual-links` ribbon and `.visual-slider__progress` component, its CSS, and its JavaScript updates. No dots, replacement strip or progress bar were added.
- Removed ENTER THE FIELD / ENTER THE PROTOCOL PORT spans from the already-clickable homepage ManMaTIC branches. Their enclosing links and destinations remain.
- Removed the requested decorative Field arrow from existing external Field links, without changing their labels, URLs, typography, menu structure or behavior. Removed decorative arrows from Contact social labels and Visual-index return links, including their generating sources.
- Retained gallery controls, necessary Previous/Next navigation, meaningful standalone resource links, architectural diagrams, research graphics and the original ManMaTIC identity symbol.

## Correct Contact GIF location

The only GIF instance is now:

`#contact > .contact__intro > h3.contact__name > img`

It replaces the large AHMAD ALHADIDII name between CONTACT and the existing descriptive paragraph. The paragraph, contact details, copyright and working footer links remain. The GIF was removed from `.closing-identity` and was not added to a new section.

The original file is unchanged: 1100 × 260, transparent, animated, with explicit HTML dimensions, `alt="Ahmad Alhadidii"`, responsive proportional sizing and `object-fit: contain`. The copied asset's SHA-256 still matches the supplied Downloads file. Desktop and mobile screenshots show the animated name in the correct Contact position.

## Visuals autoplay

The existing carousel now schedules its next slide with a 45,000ms timeout. It wraps indefinitely through the five existing records. Wraparound avoids sweeping across intermediate slides; existing image-reveal transitions remain.

Manual buttons, keyboard navigation and gestures restart the interval. Autoplay pauses while hovered, keyboard-focused, offscreen, document-hidden, page-suspended or under prefers-reduced-motion. It resumes with a fresh interval when eligible. Page lifecycle handlers and removal observation clear the autoplay timer when the gallery is left or removed. Autoplay never opens a detail page or reloads the document.

## Navigation root cause and fix

The old capture-phase restoration handler treated every homepage link from every non-home page as a project-return request. It rewrote explicit destinations such as `/#work` and `/#contact` to `/` or a saved project anchor. Visual detail pages also initialized project-return context. Separately, the initial fragment listener was never registered when the homepage initially had no hash, and competing delayed alignment timers could override later navigation.

The correction:

- Restricts project-return context to actual project routes.
- Preserves existing anchor hrefs instead of rewriting them.
- Gives explicit section links and navbar/brand Index navigation priority over stale restoration data.
- Cancels superseded restoration work with a revision token.
- Retains project-card restoration for actual browser-history returns.
- Initializes fragment handling even on hash-free homepage visits.
- Uses animation-frame alignment, font readiness and ResizeObserver notifications to account for actual layout changes. It follows the selected anchor until deliberate user scrolling/focus movement, rather than applying arbitrary timed jumps.
- Handles repeated clicks on the same hash as well as hash changes and history navigation.

The global navbar was not redesigned or replaced. Its existing labels, routes, sticky behavior and styling remain; only the specifically requested Field arrow glyph was removed. The original ManMaTIC page's shorter menu remains unchanged in structure.

## Exact files changed in this corrective pass

| File | Correction |
| --- | --- |
| `index.html` | Original symbol, image links, removed branch CTAs/ribbon, correct Contact GIF, restored closing text, Contact/Field arrows. |
| `assets/css/style.css` | Original symbol styles, scoped baseline/spacing correction, responsive Contact GIF, image-link focus styling, deletion of obsolete CTA/ribbon styles. |
| `assets/js/main.js` | Image-link generation, autoplay/lifecycle/gesture handling, restoration and anchor-navigation fixes. |
| `assets/js/visual.js` | Removed decorative Visual-index return arrows at their generating source. |
| `projects/shila/index.html` | Removed the Field-link arrow only. |
| `projects/dabouq/index.html` | Removed the Field-link arrow only. |
| `projects/concrete-fatigue/index.html` | Removed the Field-link arrow only. |
| `projects/protocol-port/index.html` | Removed the Field-link arrow only. |
| `visuals/architecture-of-elsewhere/index.html` | Matched Field and Visual-index arrow removal in static markup. |
| `visuals/drawn-out-of-red/index.html` | Same narrow static arrow correction. |
| `visuals/stone-by-moonlight/index.html` | Same narrow static arrow correction. |
| `visuals/the-mechanics-of-becoming/index.html` | Same narrow static arrow correction. |
| `visuals/the-last-room-before-tomorrow/index.html` | Same narrow static arrow correction. |
| `scripts/generate-project-pages.ps1` | Synchronized the targeted Field-arrow removal. |
| `scripts/generate-visual-pages.ps1` | Synchronized Field/Visual-index arrow removal. |
| `scripts/verify-visual-routes.ps1` | Replaced the obsolete ribbon-link expectation with the no-script image-link/ribbon-removal check. |
| `scripts/verify-visual-runtime.ps1` | Updated the actual activation target from the deleted CTA to the image link. |
| `scripts/verify-portfolio-corrections.cjs` | Added browser regression coverage for the reported navigation, gallery and GIF issues. Requires existing Playwright through NODE_PATH; no production dependency was added. |

Earlier-pass modifications already present in `content.js`, `assets/js/project.js`, `assets/css/dabouq.css`, and `projects/manmatic/index.html` were preserved rather than reset. The existing GIF asset was reused, not regenerated or recompressed.

## Verification

- **Navigation suite: 129 assertions passed.** Tested actual visible section positions, not just URL hashes. Covered Profile, CV, Work, Computation, Visuals and Contact from the homepage, all five project pages where those links exist, and a Visual detail page; mobile coverage included homepage/project/Visual sources. Also covered Back to Work, All Visuals, browser Back/Forward and restoration of a visible project card.
- **Routing edge cases: 11 assertions passed.** Index from project and Visual detail pages ignores stale return data; repeated same-hash Work navigation realigns the section on desktop/mobile.
- **Gallery/GIF suite: 49 assertions passed.** All five distinct detail destinations opened through keyboard image activation; mouse dragging did not navigate, normal image clicks did; keyboard focus was visible. Checked the single correctly placed Contact GIF, aspect ratio, accessible name, original closing text, removed CTA/ribbon and removed Contact arrows.
- **Autoplay suite: 19 assertions passed with browser virtual time.** No advance at 44,999ms; advance at 45,000ms; complete wrap through the five visuals; hover/focus/offscreen pause and resume; manual interval reset; reduced-motion pause; removal clears the timer before another advance.
- **Native mobile touch verification passed.** A real CDP touch swipe on the linked image advanced the gallery without navigating; a touchscreen tap opened the corresponding detail page.
- **Existing Visual runtime suite: 229 assertions passed** across all five records, including detail identity, refresh, next navigation, return navigation and browser history.
- **Visual static route suite: 95 assertions passed.**
- **Build:** generated four project pages and five Visual pages in a temporary UTF-8 build directory. The generator preserved its custom Protocol Port page; existing hand-composed production pages were not overwritten.
- JavaScript syntax and Git whitespace checks passed. No configured lint/type-check command or package manifest exists in this static project.
- Exact SVG-source equality against Git and GIF-byte equality against the supplied file passed.
- Desktop/mobile before/after measurements in `layout.json` match for ManMaTIC's section, primary presentation link, category, branch, images, Field window and threshold: positions, widths and heights were preserved. Visual image sizes and aspect ratios also remain unchanged. The deleted CTA's mobile text-stack space and removed ribbon space collapse naturally; no replacement empty strip remains.
- Visually inspected the restored symbol, clickable Visuals presentation without the ribbon, and the Contact GIF at 1440px and 390px widths. Verified screenshots are `1440-contact-verified.png` and `390-contact-verified.png`.

## Remaining issues

No unresolved failures in the requested local checks. Architectural image/diagram arrows and the external ManMaTIC Field research graph were intentionally retained. No project image asset, narrative, route, project order, global font, colour palette or responsive breakpoint was changed by this correction.
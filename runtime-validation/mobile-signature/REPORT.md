# Contact mobile signature and Visuals timing

## Files changed
- assets/css/style.css: responsive override only for narrow screens or touch devices up to 1024px. The signature image participates in normal flow, without absolute positioning or transforms; its wrapper has an automatic aspect ratio. Existing proportional width/height:auto sizing remains. Negative margins compensate for the original transparent canvas padding, without clipping any animated ink. No fixed height is introduced. Desktop rules are unchanged.
- assets/js/main.js: existing autoplay timeout changed from 45000 to 20000 milliseconds; no other application JavaScript changed.
- scripts/verify-portfolio-corrections.cjs: existing autoplay checks now assert 19,999/20,000ms boundaries and manual reset halfway through the new interval.

## Diagnosis and limits
The asset is 1100 x 260, with 40 transparent animated frames and infinite looping. The original layout placed it absolutely in an overflow-hidden aspect-ratio wrapper, translated by percentages of its own canvas. The canvas therefore extended upward and leftward beyond the wrapper to compensate for transparent padding. No height:100%, object-fit:cover, scaleY, or flex/grid stretching was found on the image. Available WebKit and Chromium both reported the correct intrinsic image ratio before this change; the reported real-device stretching was not reproduced. The responsive correction removes the positioning dependency while preserving the visible signature dimensions and spacing. The exact device-specific rendering trigger is unconfirmed.

## Verification
- Playwright WebKit 26.5 on Windows, including actual iPhone 17 Pro and iPhone SE device presets in portrait and landscape, plus 402x874, 874x402, 375x667, 667x375 and 320x568 viewport checks.
- Chromium cross-check at the same viewport sizes.
- Original canvas ratio 1100/260 maintained; all-frame visible ink bounds remain inside the signature wrapper; heading and description do not overlap it; no horizontal overflow. Wrapper dimensions and paragraph spacing remain stable after load. Multiple distinct rendered GIF frames confirm playback.
- Desktop baseline comparisons at 1440px and 1025px; the responsive override also remains inactive on a 1024px desktop with a mouse.
- Existing autoplay suite: 19 assertions passed, including exact 20-second timing, all five slides and looping, manual reset, hover/focus/offscreen/reduced-motion pause/resume and cleanup on removal.
- Existing gallery suite: 49 assertions passed, including image destinations, manual controls, GIF presence and ratio.
- Visual routes: 95 assertions passed. Application/test JavaScript syntax checks and git diff --check passed.
- GIF SHA256 still matches the original supplied file: 91c9b05ab6a5aa4eaadeb4ed704cd1b8ffd8c9bdeeaf31a72cced0577c6a6619. Animation, alpha and source bytes are unchanged.

Real iOS Safari and a physical iPhone were unavailable. Windows WebKit emulation is useful engine-level coverage, not proof of real-device Safari behavior. Screenshots and JSON measurements accompany this report. Changes are local, not deployed.

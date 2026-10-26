# Stick development notes

## Current increment — scrolling sky

Date: 2026-10-26. Approach: **TDD**, explicitly chosen by the user.
Base: `feature/app-shell/00-base` at `b3dfad9` (current checkout already contains
the shell commits; earlier pending-review wording below is historical).
Iteration: `feature/app-shell/scroll-sky`. Review and merge approval pending.

At the user's request, the commits after base `b3dfad9` were squashed to
`f343d73` before the shadow revision. Its tree is identical to former tip
`a110292`; staged artwork and the local speed edit were preserved. The next
commit contains the shadow revision only. No merge or push is authorized.

Outcome: replace all placeholder SpriteKit geometry with Resources/sky-day.png
and Resources/sky-night.png. Day starts left-aligned; both images aspect-fill
with vertical centering and move left in a repeating day/night circuit.
The shared four-minute circuit gives two minutes per image. The updated night
artwork requested during implementation matches day at 3168 × 1344 pixels. SwiftUI
controls remain above the scene. Only these two requested resource files belong
to this increment; other user-provided Resources files remain untracked.

Learning goal: proportional image layout and recycling offscreen nodes, reusing
scene ownership, lifecycle, reference identity, and main-actor isolation.
The tradeoff is a direct seam between unmodified images rather than a blend.

TDD evidence: six new behavioral tests first ran against the placeholder scene;
all six failed because sky nodes were absent (`/tmp/stick-sky-red.xcresult`).
The first implementation passed layout, alternation, pause/resume, and resize;
adjacency assertions exposed SpriteKit frame rounding of about 0.001 points.
The coverage check now allows 0.01 point, well below a display pixel.
Final validation: Tuist generation passed; 9 Swift Testing unit tests (6 sky,
3 ownership) and 1 XCTest navigation/rendering test passed on iPhone 17 Pro,
iOS 26.3.1 Simulator. Result: `/tmp/stick-sky-updated-night.xcresult`.
The build copied the replacement 3168 × 1344 night image from Resources.
No warnings appeared in this final incremental build. Inspected the live sky
under the SwiftUI controls in `/tmp/stick-sky-home.png`; it fills the screen
and the placeholder geometry is gone. Hub-required practice `swift test`
separately passed 12 tests. Whitespace checks passed. No device validation.

Direction revision: user requested right-to-left motion on the same iteration.
TDD retained: revised initial placement, motion, alternation, and resumed-motion
checks failed against the rightward implementation (`/tmp/stick-sky-left-red.xcresult`).
Night now starts to the right of day; translation subtracts the shared offset.
Recycle a panel only when its right edge has passed the screen's left edge.
The loop duration and left-aligned starting day image are unchanged.
The first UI run rejected a correctly rendered pale sky: 100 sampled pixels
were colored, below the old requirement of 128. Inspected both launch/return
screenshots from `/tmp/stick-sky-left-attachments/`. The smoke check now requires
color to be present in the central world region, rather than a fixed coverage
of saturated artwork; a uniform gray world still fails.
Final revised run `/tmp/stick-sky-left-final.xcresult`: 9 unit tests and 1 UI
test passed; separate hub `swift test` passed 12. Whitespace checks passed.

Acceptance: exactly two sky nodes; bundled textures; proportional aspect fill;
left-aligned day initially; common slow leftward speed; repeated alternating
wraps with no uncovered strip; progress preserved on resize and navigation;
no catch-up jump after pause. Existing ownership and navigation checks remain.
No energy or performance claim. Reduce Motion support is not implemented yet.

Landscape revision: user requested a stationary overlay from
Resources/landscape-transparent.png. Interpret the sizing as full screen height,
proportional width, horizontally centered (also vertically centered). The image
is wide, so portrait presentation crops its sides. It sits above both sky panels
at zPosition 1 and is laid out only during construction or resizing.
TDD: both new landscape tests failed because the node was absent in
`/tmp/stick-landscape-red.xcresult`. The first implementation exposed missing
initial/resize layout; fixed placement in the layout path instead of frame updates.
Sky tests now read the configured circuit duration so local speed tuning does
not invalidate hardcoded time assumptions. The user's local 120-second duration
remains in the working file; the reviewed default is kept at 240 seconds.
This increment now includes the requested landscape asset; other staged artwork
and resources are separate work and must remain outside the review commit.
Validation: `/tmp/stick-landscape-final.xcresult` passed 11 unit tests and 1 UI
navigation/rendering test with the current local 120-second duration; separate
practice `swift test` passed 12. Inspected portrait launch/return screenshots
in `/tmp/stick-landscape-attachments/`: the landscape is centered and static,
its wide sides crop as expected, and sky is visible through the upper opening.
No device validation. Whitespace checks passed.

Proposed PR description: Replace the shell's placeholder meadow geometry with
two bundled sky panels. Scale each proportionally to fill the view and recycle
it after it exits left, keeping day and night in a continuous four-minute loop.
Reset frame timing across lifecycle pauses. Validation covers deterministic
layout/motion/wrap behavior and the existing navigation/rendering smoke test.
The artwork meets directly at a seam; no image editing or blending is included.
Overlay the provided transparent landscape, centered and scaled to screen height,
while only the sky moves. Verify landscape layering, dimensions, and resize behavior.

## Initial shadow revision — superseded by illumination revision

User request: mask out transparent landscape pixels and apply a black vertical
gradient, strongest at the top and zero at the bottom. Animate overall opacity
with each sky panel: 1 at both edges, 0 at its center, repeated for day and night.
Keep this revision in one commit after the squashed scene commit.

TDD: three new shadow tests failed against the previous scene because the shadow
node was absent (`/tmp/stick-shadow-red.xcresult`). Implementation bakes the
artwork alpha and gradient into one texture using sourceIn, preserving soft
alpha edges instead of the live crop node's thresholded mask. A fourth sprite
uses that texture at zPosition 2; only its alpha changes per frame. Its geometry
matches the landscape on creation and resize. Shared progress keeps the sky and
shadow in sync, including after navigation pauses. No image files are edited.

Learning goal: alpha compositing and shared animation progress; reuse texture
layout, reference lifetime, scene ownership, and lifecycle timing. No independent
mastery claim. A baked texture adds storage but avoids a live crop render pass;
no profiling or energy improvement is claimed.

Validation: `/tmp/stick-shadow-green.xcresult` passed 14 unit tests and 1 UI
test on iPhone 17 Pro / iOS 26.3.1 Simulator with local 120-second speed. Tests
cover sampled mask/gradient pixels, transparent regions, top and bottom limits,
both panels' opacity extrema, alignment, texture reuse, resize, and pause timing.
Separate hub practice `swift test` passed 12. Xcode emitted only the App Intents
metadata-extraction warning for targets without an AppIntents dependency.
Review commit keeps the existing 240-second default; user's local speed edit
and unrelated staged artwork remain separate. No device or energy validation.
Inspected `/tmp/stick-shadow-attachments/`: shading follows the landscape outline,
sky remains clear, and the gradient decreases toward the bottom. Whitespace checks passed.

PR addition: Shade the static landscape through its original alpha with a
cached top-to-bottom black gradient. Animate its opacity from full at each sky
panel's edges to clear at its center, preserving sky visibility and lifecycle
timing. Tests validate generated pixels and synchronized frame behavior.

## Illumination revision — pending review

User request: derive shadow opacity from average pixel brightness in the day
and night artwork. Start at day center with no shadow, reach full shadow at day
end, keep it full throughout night, then fade out with the measured dawn light.
TDD retained on the same review branch. Revised startup/night behavior checks
failed against the previous scene (`/tmp/stick-illumination-red.xcresult`).

Ran scripts/map_sky_illumination.py against both original PNGs. Mean normalized
RGB: day 0.867354, night 0.670498. The bundled JSON stores 128 full-height strip
averages per image, metadata, and original file hashes. docs/sky-illumination.svg
plots a representative portrait viewport's brightness and resulting shade.
These are encoded RGB averages for artwork control, not physical illumination.

SkyIllumination samples 32 positions across the visible width, wrapping between
images. It normalizes each day half against its center and adjoining edge light,
then applies smoothstep; night alpha stays 1 regardless of its painted brightness.
Flat/reversed daylight contrast has an eased positional fallback. Resize updates
the sampled width; the shared paused clock preserves synchronization.

Centering day initially required recycling the offscreen preceding panel at the
circuit seam too. Repeated-wrap tests caught an uncovered strip, fixed before
the final run. The baked vertical mask gradient itself remains unchanged.

PR description: Start the sky at day center and drive landscape shade from
generated brightness profiles instead of a triangular timed fade. Keep shade
at full strength throughout night and use measured light for dusk and dawn.
Bundle the generated map, its reproducible script, and a review chart; preserve
alpha masking and lifecycle timing. Regenerate the map after changing sky art.
No device performance or physical-lighting claim. Review and explanation pending.

Validation: `/tmp/stick-illumination-verified.xcresult` passed 19 unit tests and
1 navigation/rendering UI test on iPhone 17 Pro / iOS 26.3.1 Simulator at the
local 120-second speed. Tests include darker/brighter profile fixtures, visible
window averages over joins, full night despite bright clouds, flat contrast,
gradual bundled dusk/dawn, day-centered startup, repeated wraps, mask pixels,
resize, texture reuse, and pause timing. Separate practice tests passed 12.
Data and SVG regenerated byte-identically. Inspected day-center screenshots
under `/tmp/stick-illumination-attachments/`. Whitespace checks passed.
User's local speed edit and unrelated staged artwork remain separate.

## Previous increment — project skeleton

Date: 2026-10-26. Approach: **implementation-first**, chosen by the user for
this increment. Base: `feature/app-shell/00-base` at `a534633`.
Iteration: `feature/app-shell/add-project-skeleton`.
Status: implemented and validated; explicit review and merge approval pending.

Outcome: a runnable iPhone shell with placeholder SpriteKit scenery beneath
SwiftUI controls, plus Home → Settings → native Back navigation.
The model owns one lazy scene; navigation does not replace it. SwiftUI owns
app state and typed routes; SpriteKit owns visual state. See `architecture.md`.

Learning goal: explain ownership and identity across the SwiftUI/SpriteKit
boundary, reusing ARC, value semantics, and main-actor isolation. The hub tracks
pending acquisition and retrieval questions; no mastery claim from code alone.

## Acceptance checks

- Generate the workspace with pinned Tuist 4.191.1.
- Build app and tests in Swift 6 with complete concurrency checking.
- Unit tests: preserve world identity/state across a Settings round trip;
  distinct owners have distinct worlds; the world releases with its owner.
- UI test: launch, push Settings, use native Back, repeat; check that the
  world actually renders on launch and return, rather than staying gray.
- Inspect the placeholder home screen on the simulator.
- Run whitespace checks and the hub-required Swift practice tests separately.

Results: Tuist generation passed. Xcode 26.3 / Swift 6.2.4, iPhone 17 Pro,
iOS 26.3.1 Simulator: 3 Swift Testing ownership tests and 1 XCTest UI test
passed (0 failures), final run `/tmp/stick-shell-tests-final.xcresult`.
The final build emitted no compiler warnings. Home layout inspected visually
in `/tmp/stick-shell-home-3.png`. These temporary artifacts are local only;
the checked-in commands reproduce the checks. Whitespace checks passed.
Hub-required `swift test` in `practice/` separately passed 12 tests; that is
not validation of the app. No device, artwork, animation, or energy check yet.
No push or merge is authorized by passing checks.

The first build exposed a missing initializer override, fixed before tests.
A visual check then found a gray SpriteView when initialized paused during
the inactive phase. Phase logs confirmed activation and correct scene colors.
Explicitly updating `scene.isPaused` fixed the observed rendering issue; the
view remains able to draw. The UI rendering smoke check covers the regression.
Temporary diagnostic logging was removed. No energy-saving claim is made.

## Decisions and limits

Confirmed: SpriteKit world beneath SwiftUI controls; this app is a blog case
study and a tool for the user's own difficulty sticking to one interest.
Initial scope is a personal iPhone app, portrait, iOS 26.0 minimum. Tuist is
only a project-generation tool; there are no third-party runtime dependencies.

The placeholder uses static geometry. Illustrated assets, animation, interest
editing, daily rotation, persistence, reminders, and check-ins are not built.
Reduce Motion and lifecycle/energy behavior need checks with actual animation.
No performance baseline or improvement is claimed.

Missed-day rotation, optional check-in, and reminder timing remain product
choices to settle when their increments begin.

## Delivery order

Stick → Focus Flower → wallet. Transition milestone accepted 2026-10-26:
Stick is usable daily with ordered interests, a stable daily topic, an animated
home scene, and one daily reminder. Blog publication and App Store release can
follow and do not gate the transition.

## Proposed PR description

Stick previously contained only its product summary. Add a generated Xcode
project and a native SwiftUI shell that embeds a stable SpriteKit scene and
supports Settings navigation. Keep visual state outside navigation destinations
so a round trip preserves the world. Validation and remaining limits are above.

## Next step after review

Wait for explicit iteration approval before merging to the feature base or
starting another increment. Keep hub submodule updates separate and record
the approved app commit only after approval and merge. Nothing pushed here.


## Scrolling sky approval — 2026-10-26

User explicitly approved `to_base` and `to_main`. Approved implementation commits:

- f343d737c233552a42d5ad3cc6a4b9fdab3463e1 Implement looping skies and a static landscape
- 3ff45924a1e1c76cff2e946e298802fd56e09ffc Add an alpha-masked landscape shadow synchronized with the sky
- 562fbc81443e5be6ec54abe3da99ed56f65849ed Drive landscape shade from measured sky brightness

The recorded simulator checks above apply to these committed implementations.
Local staged artwork, artwork notes, and the 120-second speed adjustment in the
hub checkout are excluded. No code changed during merge bookkeeping.
Learning explanations remain unassessed; merge approval does not establish mastery.


## App shell feature approval — 2026-10-26

User approved merging the completed app shell feature into `main`.
Approved sky iteration squash: `3b1d1b863213050a21ca3ad83feb1ec76514451c`.
Original feature commits approved for the main squash:

- 822469f8bf1884d95f65e977d0df90c6ca070ed3 Add SwiftUI app shell with a persistent SpriteKit world
- b3dfad991d9c2d4b0b3c5d5443ecdf441ffb7e4b Keep README focused on app functionality and setup
- 3b1d1b863213050a21ca3ad83feb1ec76514451c Implement looping skies and a static landscape

Status: approved for main; preceding pending-review sections are historical.
The squash preserves the exact approved source tree and original commit titles.
No push is authorized. New work starts under `feature/drop-animation/`.

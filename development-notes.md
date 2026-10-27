# Stick development notes

## Current increment — reference-styled daily card

Date: 2026-10-27. User requested implementation on the current branch:
`feature/home-header/00-base` (starting at `b26b61c`); no new iteration branch.
Approach: **implementation-first**, accepted by the user. Test selection:
cover the check-in button, retain existing navigation checks, and review card
appearance/fixed font sizes visually. Approved with `pp_to_main` on 2026-10-27;
merged into main after a tree-preserving squash. Nothing pushed.

Outcome: warm ivory card with rounded corners and a soft shadow, dark-green
introductory text, bold rounded Photography placeholder, supporting text,
and a sage capsule button based on `Resources/base_design.jpeg`. Card text uses
fixed point sizes with no automatic scaling or shrinking. The design's check
is initially hidden and appears only after tapping “I spent some time”.
Another tap leaves it checked. Space for the icon is reserved to avoid a jump.

Interface: `DailyFocusCard` takes a binding to `AppModel.hasCheckedIn` through
HomeView. The model owns the acknowledgement for the current app run, including
navigation away from Home. This is presentation state, not saved daily history;
there is no persistence, daily reset, interest editing, or rotation yet.
SwiftUI retains interaction and accessibility while SpriteKit owns scenery.
Only the card's fonts are fixed; header typography is unchanged.

Main tradeoff: model-owned in-memory state survives card/view recreation and
Settings navigation, while deliberately stopping short of saved daily check-ins.
Reuses the existing Observation owner and binding-based native interface.
All implementation progress and review state stay in this app's notes.

PR description: Replace the placeholder Home box with the reference's ivory
daily-focus card, fixed-size green typography, and sage check-in button. Show
the check only after a tap and preserve it through navigation during the app run.
Validate unchecked → checked behavior, repeated taps, and Settings return;
review default and large-text simulator screenshots for the fixed card layout.
Photography remains placeholder content and the acknowledgement is not persisted.

Validation: Tuist generation passed. `/tmp/stick-daily-card-final.xcresult`
passed 24 unit tests and 3 UI tests on iPhone 17 Pro / iOS 26.3 Simulator.
The new UI test verifies initial unchecked state, checked state after tapping,
repeated taps remaining checked, and checked state after Settings return.
Inspected before/after screenshots and largest accessibility text size in
`/tmp/stick-daily-card-final-attachments/`; card typography/layout stays fixed.
Visual review moved the shadow onto the background shape to avoid shadowing
the card contents. Final whitespace checks passed. Only the existing App Intents
metadata-extraction warnings appeared. No physical-device validation.

References: [SwiftUI font](https://developer.apple.com/documentation/SwiftUI/Font)
and [managing interface state](https://developer.apple.com/documentation/swiftui/managing-user-interface-state).

### Home-header feature approval — 2026-10-27

User approved the completed feature with `pp_to_main`, including the reference
card and current app instructions. Approved source commits (oldest first):

- `b26b61ca9d3cbe79767ee23bd1bd66deb493886e` Style home header with a green wordmark and twig logo
- `9190f00b59e798e954bb75c1e13ecad9956b7004` Style the daily focus card and add tap-to-check feedback
- `179fc74cde30f6e3a3ff447c81689ab74a83196b` Update Agents.md

The final squash flattens the first commit's retained titles and preserves every
original title in chronological order. The approved tree is unchanged except
for this approval record; the checks above still apply. Delete only the
home-header base after successful fast-forward and ancestry verification.
The drop-animation planning base remains separate. The rejected white halo is
not included. No hub files, hub submodule pointer, commits, or pushes are updated.

## Previous increment — home-header branding

Date: 2026-10-26. Approach: **implementation-first**, chosen by the user.
Base: `feature/home-header/00-base` at approved main `5bd4c0e`.
Iteration: `feature/home-header/style-branding`. Approved with `to_base` on
2026-10-27; merged into `feature/home-header/00-base` after a tree-preserving
squash. The iteration branch is deleted after the verified fast-forward.
The approved drop-animation plan remains on its separate feature base.

Outcome: reference-inspired forest-green lowercase wordmark with a brown twig
and small green leaf, paired with a plain muted-green outlined gear. The header
sits within Home's top safe area. Settings retains native navigation and Back.
`Resources/base_design.jpeg` is retained as the design reference, copied from
the approved drop-animation base; it is not bundled in the app.

Interface: `StickWordmark` owns native text and vector twig paths. `HomeHeader`
owns the Settings NavigationLink; SpriteKit continues to own the scenery. The vector
twig stays sharp at different sizes. SF Rounded approximates the reference's
lettering. Branding scales only through xxxLarge so it leaves room for the gear.
VoiceOver sees one “Stick” heading and a named Settings control; the gear has a
44-point target. No bitmap generation or third-party font is needed.

Learning goal: explain native header ownership and navigation-bar visibility,
reusing SwiftUI environment, typed navigation, and the existing scene boundary.
Hub note: `notes/b-modern-ios/auto/swiftui-home-header.md`. User explanation
pending; implementation and test results do not establish mastery.

Checks: Tuist generation passed. Final `/tmp/stick-header-final.xcresult`
passed 19 unit tests and 2 UI tests on iPhone 17 Pro / iOS 26.3 Simulator.
UI tests cover repeated Settings round trips, accessible labels, target size,
alignment, no horizontal header overflow, and largest accessibility text size.
Hub practice `swift test` separately passed 12 tests. Whitespace checks passed.
Default-size simulator artwork/header inspected in the exported screenshots;
final attachments are under `/tmp/stick-header-final-attachments/`.
Only App Intents metadata-extraction warnings appeared in the final build.

Limits: exact painted lettering is approximated; the rest of Home's design and
bottom card are outside this increment. No device, energy, or performance
claim. Largest-text bottom-card layout is not addressed by the header check.

PR description: Replace Home's system title and toolbar styling with the design's
green wordmark, custom vector twig, and outlined Settings gear. Keep a named
44-point Settings target and native Settings navigation. Validate header labels,
layout, large-text behavior, rendering, and repeated navigation on the simulator.
Iteration review approved; merging the feature into main needs separate approval.
Nothing pushed.

### Sky-aligned tint revision — 2026-10-27

User requested darker greens against a bright sky and lighter greens as the sky
darkens, explicitly preserving each current color at full brightness.
Implementation-first continues on the same iteration; the feature base stays
unchanged. Wordmark day RGB: (0.20, 0.35, 0.23); settings day RGB:
(0.32, 0.41, 0.27). Both blend toward muted sage (0.50, 0.65, 0.42).
User found the first lighter endpoint too light; the final endpoint is subdued.
Twig artwork keeps its brown and leaf colors.

`SkyIllumination.headerDarkness` uses the existing 32-position visible-width
brightness average, normalizes between day-center and night-center brightness,
clamps, and smoothsteps. It follows painted night brightness too; it does not
use the landscape's full-night shadow policy. Flat/reversed center contrast
keeps the original daytime colors. These are encoded RGB artwork averages,
not physical illumination or an accessibility-contrast guarantee.

MeadowScene updates one retained observable `SkyAppearance` as it positions the
sky, including resize. Only HomeHeader reads its changing darkness value;
there is no separate timer, callback capture, or additional animation clock.
Pause/resume inherits scene timing. This reuses Observation, ownership,
visible-window sampling, and existing lifecycle behavior.

Revision PR description: Keep the exact original daytime wordmark and gear
greens, blending both toward muted sage as measured visible sky brightness
falls. Share the scene's timing and retain native Settings navigation. Validate
day/night/midpoint colors, brightness fixtures, joins/wraps, resize, and pause.
Both header commits are approved for the feature base. Nothing pushed.

Revision checks: Tuist generation passed. `/tmp/stick-header-tint-muted.xcresult`
passed 24 unit tests and 2 UI tests on the same iPhone 17 Pro simulator; practice
`swift test` passed 12. Tests cover exact original day colors, muted night and
intermediate colors, different brightness at the same progress, flat profiles,
visible joins and circuit wrap, scene resize, and pause/resume. Whitespace checks
passed; only the existing App Intents metadata warnings appeared. A prior run's
navigation check was interrupted by a manual app relaunch; the clean rerun and
final muted-color run both passed. No production fix was needed for that run.

Live visual check: `/tmp/stick-header-tint-day.png`,
`/tmp/stick-header-tint-dusk.png`, and `/tmp/stick-header-tint-night-review.png`
show the actual sky and header transitioning together with the final muted tint.
The long-running simulator captures also showed missing glyphs in the unchanged
bottom card. Cause and whether this predates the tint revision are unverified;
the short navigation/rendering tests do not cover this artifact. Record it for
follow-up; do not treat these captures as a clean whole-screen visual pass.

### Iteration approval — 2026-10-27

User explicitly approved `to_base`. Approved original implementation commits:

- `40411ff403103ffade8fdc21539b7bf1661b597f` Style home header with a green wordmark and twig logo
- `950689f941f28c6ed7ad49a09aa43f7e436fb7bf` Align home header greens with measured sky brightness

The squash retains the reviewed source tree and all original commit titles,
including approval bookkeeping. Existing passing checks above apply unchanged.
The unrelated working edit to AGENTS.md is excluded and preserved. Bottom-card
rendering follow-up and the user's learning explanation remain pending;
merge approval does not establish mastery. No main merge or push authorized.

## Previous increment — scrolling sky

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

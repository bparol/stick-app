# Stick development notes

## Local integration approval — 2026-11-05

User invoked `pp_to_base`, `pp_squash`, and `pp_to_main`, answered “shuash”
to the four-commit squash question, then directed: “commit all along, no separate
worktree”. This authorizes inclusion of all current tracked and untracked work
in this app, including the nine character assets and opt-in device MCP draft,
followed by the local squash and merges. No push or hub changes authorized.
Earlier pending implementation-review wording is historical for this approved
integration. Committing the MCP prototype does not replace the confirmed future
generic WDA direction or establish end-to-end readiness.

Approved prior implementation tip: `1cb369180fe81e2fc5edc3a3f904e31b9fa6c03c`.
Original source commits before the final all-changes commit, oldest first:

- 7ef7881e2e9179eaa436525ac2861b1a9a82cdc3 Add the first-use card and persist the first stick
- 4328c88d573a58a69bf13be84c02dc92f1dc4f46 Fit smaller sky images into the upper half of the scene
- d6f6a80b943e19b4d39c8fa49d8d51ab5d6396a4 Choose the current waiting domain from a long-press sheet
- 1cb369180fe81e2fc5edc3a3f904e31b9fa6c03c fixes

Integration source: `feature/sticks/add-first-stick`; feature base:
`feature/sticks/00-base`; final target: `main`. Both destinations start at
`9fed1a440a33fc85a396d4bffa7e960bd837928d`. Include approval bookkeeping in
the final source commit and selected squash. Preserve the exact committed tree
and flatten every prior included-title list without dropping duplicate titles.
The explicit base squash keeps an existing single unique commit. With one
base commit unique to main, the final merge needs no additional squash question.
Both merge shortcuts authorize deleting only their respective source branches;
the separate drop-animation base remains untouched.

Final preparation aligns stale scene assertions with the current 35%-height,
32%-foot-position layout; pose order, lifecycle, and wrap tests remain intact.
Remove the pre-existing positionSky trailing whitespace. No runtime behavior
changed during this integration preparation.

Validation: `/tmp/stick-all-integration.xcresult` passes all 57 unit tests and
9 UI tests with zero failures on iPhone 17 Pro / iOS 26.3 Simulator. This includes
selection, editing/deletion, onboarding, relaunch, session history/timing, large
text, and Home navigation/rendering. Tuist generation succeeds; the opt-in
StickAutomation scheme builds for testing (Simulator, signing disabled) in
`/tmp/stick-final-automation-build.log`. Four Python relay tests pass. Required
practice `swift test` passes 12 tests with build output under
`/tmp/stick-integration-practice-build`; no hub files changed. Final whitespace
check passes. A sandboxed Simulator inventory failed; the authorized retry with
Simulator access succeeded.

Limitations: custom device MCP has not been verified end to end or on a physical
device; the generic WDA replacement remains future work. Existing memory/CPU
termination investigation has no confirmed cause or measured fix. No new
physical-device performance or energy evidence. Character clock ownership and
its paused-time failure case were explained by the user in the earlier learning
follow-up; unrelated learning prompts remain unassessed. No new mastery claim.


## Character pose rotation — 2026-11-04

User requested transparent versions of all character images in
`/Users/bogu/Desktop/sticks` and replacement every 10 seconds.
Confirmed: nine source JPEGs, numbered 1–9. Implementation choice: direct
replacement in filename order, wrapping to the first pose, counting active Home
time only. Existing navigation/activity pause behavior applies. No app/session
state moves into SpriteKit.

Used the built-in imagegen tool, one background-extraction edit per JPEG.
Prompt set (same for each numbered input): remove only the vivid green backdrop,
including gaps between limbs and fingers; use genuine alpha; preserve character,
pose, expression, outlines, colors, green leaf, detached leaves and motion marks;
no added shadow, text, checkerboard, or extra objects. Generated cutouts preserve
the poses but subtly change linework/colors; they are not pixel-identical copies.
Original Desktop images remain intact. Final assets are
`Resources/stick-1-transparent.png` through `stick-9-transparent.png`, each
1254 × 1254 RGBA with alpha spanning 0–255. Original static artwork stays on disk
but is no longer bundled. Tuist bundles the nine numbered PNGs.

MeadowScene reuses its existing frame clock and single character node. It retains
partial intervals over pauses, replaces the texture only at a 10-second boundary,
and handles long frame gaps by advancing the appropriate number of poses.
Layout keeps canvas proportions, height, center, and bottom anchor stable; visible
artwork margins vary slightly by pose. Textures load on demand; physical-device
memory/energy impact has not been measured. No performance improvement claimed.

Final validation: `/tmp/stick-character-final.xcresult` passes all 57 unit tests
and the Home → Settings → Back UI test (zero failures). Two timed simulator
captures, `/tmp/stick-pose-first.png` and `/tmp/stick-pose-second.png`, show
the waving pose replaced by the next pose with transparent surroundings.
Whitespace checks pass. Initial 57-test run had three failures caused by tests
assuming separately loaded textures share object identity; compare rendered image
content for order/wrap instead. Updated tests also check the interval boundary,
partial-interval pause/resume, large steps, negative deltas, and stable geometry.
Separate required practice `swift test` passes all 12 tests using
`/tmp/stick-character-practice-build`. Tuist generation succeeds.

Primary API sources verified: [scene update](https://developer.apple.com/documentation/spritekit/skscene/update(_:))
and [sprite texture](https://developer.apple.com/documentation/spritekit/skspritenode/texture).
Apple documentation JSON read directly after the web renderer could not read its
Markdown counterpart. Review and learning explanation pending; no commits,
merges, pushes, or hub writes. Learning prompt: why reuse the scene clock for pose
rotation, and what would go wrong if the first frame after resuming counted the
entire time spent in Settings?


Learning follow-up — 2026-11-04: user explained that reusing the scene clock
avoids lifecycle tracking in two places and permits synchronized animation.
These ownership/timing reasons are correct. They also suggested performance;
avoiding an additional timer is reasonable, but no measured performance benefit
has been established. Failure-case explanation completed correctly on 2026-11-05 (see below).

Full user follow-up: “reusing scene clock helps with performance and we don't
need to track app lifecycle in two different places + we can synronise both
animaitons. Which timestemp are you taling about?”

Answer: the timestamp is `previousUpdateTime` in MeadowScene, used by
`elapsed = max(0, currentTime - previousUpdateTime)`. The `isPaused` observer
sets it to nil. The first update after resuming establishes a new baseline
without advancing either animation; it preserves `characterElapsed`, the partial
10-second interval. Without rebasing, a frame at 130 after the last pre-pause
frame at 100 would count 30 paused seconds and skip three character poses while
also jumping the sky. This describes app code; no runtime changes or new tests.


Learning check completed — 2026-11-05. Prompt: “What visible behavior would you
expect if we kept the old timestamp after spending 30 seconds in Settings?”
User answer: “after getting back to the scene the character would instantly
switch to a differnt one”. Result: correct; identifies the visible jump caused
by counting paused time. Together with the prior explanation of shared lifecycle
handling and synchronization, the main decision and failure case are explained.
No substantive miss. Feedback: a 30-second gap advances three poses at once;
the sky also jumps. Implementation review remains pending. Learning evidence is
recorded only in this app; no hub cycle/ledger writes or mastery-level promotion.


## Idle foreground termination investigation — 2026-11-04

Console follow-up: user has no other logs and supplied CoreUI CUIThemeStore
“No theme registered with id=0” (twice), SpriteKitViewCoordinator
“implements focusItemsInRect: - caching for linear focus movement is limited
as long as this view is on screen”, PointerUI “non-launching port is
incompatible with service identifier com.apple.PointerUI.pointeruid.default-service”,
and “cannot add handler to 0 from 0 - dropping” (twice).
Answer: these lines do not identify a memory kill, CPU-resource exception, or
watchdog termination. Their wording concerns theme lookup, focus handling, and
service/handler registration; no causal connection to this termination has been
established. Do not treat “caching … is limited” as proof of a memory leak.
Next useful comparison is an unattached Release run for the observed failure
duration, followed by Time Profiler of idle Home; stable 117 MB in Allocations
and 35% CPU are observations, not a termination diagnosis. No runtime changes
made based on these console lines.

User report: “App is being killed for using too much memory. Investigate how we
can fix it”. Clarifications: Home remains visible; Allocations shows no growth;
after eight minutes persistent memory is 117 MB; CPU stays around 35%.
Follow-up: “but CPU is contatnly 35%, maybe it's CPU ?”

Findings:

- Code retains one lazy MeadowScene per AppModel. Frame updates reuse textures;
  shadow generation happens at scene construction. No obvious unbounded scene,
  node, or texture collection found by inspection. This does not rule out a leak.
- Current day/night assets are each 1584 × 672; landscape is 1678 × 937;
  character is 1132 × 1389. Five RGBA8 images including the generated shadow
  total about 26.1 MiB, excluding decoded copies, caches, render surfaces and
  framework memory. This is a pixel-format estimate, not measured GPU memory.
- Shadow construction loads the landscape through UIImage as well as SpriteKit
  and draws a full-size temporary image. Candidate startup/footprint improvement,
  but it does not explain sustained growth without additional evidence.
- Connected iPhone 14 Pro reports iOS 27.0.1. Retrieved the two available Jetsam
  reports to /tmp/stick-jetsam-2026-11-03.ips and
  /tmp/stick-jetsam-2026-11-04.ips. The former lists Stick active/frontmost:
  8760 resident pages × 16384 bytes = 136.875 MiB, lifetimeMax 12660 pages =
  197.8125 MiB. Its entry has no kill reason; other processes have kill reasons.
  Today's report does not list Stick. Neither establishes the reported kill.
- Activity Monitor and memory-only VM Tracker recordings both failed because
  Instruments could not lock kperf, reporting another session. Failed traces
  under /tmp/stick-memory-*.trace are not valid performance measurements.

Answer to CPU question: sustained 35% CPU warrants investigation for this slow
scene, but the percentage alone does not identify a termination cause. Check the
actual report: EXC_RESOURCE CPU/CPU_FATAL indicates excess CPU, MEMORY indicates
a memory resource issue, and watchdog 0x8badf00d indicates unresponsiveness.
Check NON-FATAL CONDITION too; some resource reports do not terminate the app.
Stable Allocations persistent bytes argues against growing heap allocations;
it does not establish stable total footprint including graphics memory.

Next proposed experiments, not confirmed fixes: capture Time Profiler for the
idle visible scene and Game Memory for total CPU/GPU footprint; compare an
unattached Release run. Compare 60 versus 30 FPS, then suppress header darkness
publication separately to isolate rendering versus SwiftUI update cost. The
current header receives changing darkness every frame; illumination recomputes
reference averages per frame. Optimize only the measured dominant work. Do not
shrink artwork further solely from the reported 117 MB Allocations value.

No Swift or assets changed; no tests required for this diagnostic notes update.
Termination cause and performance fix remain unverified. No commits, merges,
pushes or hub writes. Learning explanation pending: why does stable Allocations
not establish stable total footprint, and why would lower CPU fail to prove a
memory termination fixed?

Sources: [EXC_RESOURCE](https://developer.apple.com/documentation/xcode/exc_resource),
[watchdog terminations](https://developer.apple.com/documentation/xcode/addressing-watchdog-terminations),
[Game Memory](https://developer.apple.com/documentation/xcode/analyzing-the-memory-usage-of-your-metal-app),
[Jetsam reports](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports),
[image memory](https://developer.apple.com/videos/play/wwdc2018/416/).

## Waiting-domain selection — ready for review

2026-11-04, same pending increment feature/sticks/add-first-stick after 4328c88;
feature/sticks/00-base remains unchanged. User requested a pre-start long press
on domain rows to open a bottom sheet with one action: Set as current.

Confirmed scope: interpret pre-start as the current topic's waiting state.
Running/paused sessions block selection. Selecting a row changes only the cursor,
leaving it waiting and preserving user order/history. Reuse the accepted
AppModel/atomic snapshot and root-owned shared-sheet architecture, and standing
model TDD plus UI/visual checks. No new storage or scene-owned app state.

AppModel guards store availability, unfinished sessions and missing targets;
same-current selection is a no-op. Persist before publishing the new cursor.
The root shared sheet handles add/edit/actions. Set as current dismisses only
after a successful save; errors retain the sheet. Accessibility text sizes use
a medium-height sheet. Settings owns an explicit Edit-mode binding, disables
row movement outside Edit, and disables the simultaneous hold gesture in Edit.
A release tap cannot replace an already-open action sheet with the editor.

Validation:

- TDD red: /tmp/stick-selection-red.xcresult failed to compile on the absent
  setCurrentDomain API/error. Green /tmp/stick-selection-model.xcresult passes
  all 55 unit tests, including five selection tests for persisted cursor/order/
  history, next Stop successor, busy-state rejection, failed save consistency,
  missing IDs, same-ID no-op, and unreadable-store protection.
- Initial gesture attempts (priority, full-width content shape, exclusive tap,
  simultaneous gesture, and plain button style) failed to open the sheet. The
  first two full UI runs each retained seven passing existing regressions.
  Disabling native row movement outside explicitly bound Edit mode resolved
  the conflict. /tmp/stick-selection-modes.xcresult passes both new UI tests:
  hold/action, relaunch, unchanged order, Edit drag, normal tap editing, running/
  paused suppression, and largest accessibility text.
- One method-level test-filter attempt ran zero tests; it is not validation.
  New cases use a separate CurrentDomainUITests class for reliable filtering.
- Required practice Swift tests pass 12 (/tmp/stick-selection-final-practice.log).
- Final full app regression passes all 55 unit and 9 UI tests with zero failures
  (/tmp/stick-selection-regression.xcresult). Staged diff whitespace check passes.
- Inspected normal and largest-text action-sheet screenshots from the passing
  run in /tmp/stick-selection-review-images. Both show the title and single
  readable, reachable action. Physical-device gesture verification remains open.

Self-review checked save-before-publish, unchanged history/order, authoritative
model guards, sheet lifetime, and coexistence with native Edit gestures. A prior
prompt assertion now uses its stable identifier so the independent user wording
edit remains intact. Pre-existing card wording, scene whitespace, and earlier
uncommitted notes stay outside this revision. No merge, push, or hub writes.
Human review and learning explanation pending.

Learning prompt: Why guard selection in AppModel as well as hiding the UI action,
and what should the cursor show if saving the new selection fails?

## Upper-half sky revision — ready for review

2026-11-03 on feature/sticks/add-first-stick after squash 7ef7881; feature base
feature/sticks/00-base remains unchanged. User chose full-image proportional
resizing, no cropping: smaller clouds are desired. Supersedes the proposed
bottom-half crop. Use deterministic image tools and the proposed TDD/visual checks.

Rendering remains inside MeadowScene. Sky height is exactly half the scene,
centered at 75% of scene height. Portrait retains two alternating nodes; very
wide previews reuse additional pairs sharing the original two textures, allocated
only on resize. This preserves proportions and gap-free coverage without a crop
mask. Foreground geometry and app/session ownership remain in their existing roles.

Both images are resized from 3168 × 1344 to 1584 × 672 with Pillow LANCZOS,
preserving the entire composition. Night's alpha was uniformly 255; remove it
and retain its sRGB rendering intent. Compared quarter/half/two-thirds/three-quarter
night variants at a representative 3x phone display size. Quarter size visibly
softens/loses small stars; half size preserves substantially more detail.
Native detail comparisons and originals are in /tmp/stick-upper-sky-work.
PSNR for the sampled viewport is 49.59 dB for half size versus 42.76 for quarter;
this supports visual review but is not a perceptual-quality guarantee.

Measured asset changes:

- Day: 4,161,677 → 956,316 bytes (77.02% smaller).
- Night: 4,846,954 → 1,078,318 bytes (77.75% smaller).
- Each image has 75% fewer pixels. A simple RGBA8 representation of both would
  be 8.12 MiB versus 32.48 MiB; actual resident/GPU memory has not been measured.

Regenerated brightness JSON/hashes and the review chart for half-height layout.
A second generation was byte-identical. No repeatable physical-device CPU,
energy, or frame-time comparison collected; no runtime improvement claimed.

TDD red /tmp/stick-upper-sky-red.xcresult reproduces incorrect full-height bounds
and wide-layout coverage. Green /tmp/stick-upper-sky-model.xcresult passes all
50 unit tests, including upper-half bounds, full-texture proportions, shared
texture identity, wide/portrait resizing, wrap coverage, and pause continuity.
Separate practice swift test passes 12. /tmp/stick-upper-sky-ui.xcresult passes
all 7 UI tests. Inspected timed native captures at 2.4 seconds (day) and 30.6
seconds (night): /tmp/stick-upper-sky-day.png and /tmp/stick-upper-sky-night.png.
Both show smaller clouds with clear stars and no exposed sky/landscape gap.
Installed app binary matched the tested build, and its night asset was 1584 × 672.
The simulator needed a reboot after the UI runner shut it down; no app fix was
needed for that tooling state. Generated JSON/chart repeatability is verified.

Self-review checked full-image aspect ratio, exact vertical bounds, shared texture
reuse, allocation only on resize, resize/wrap continuity, and correct brightness
sampling window. Asset pixel/file-size reductions above are measured; physical
CPU, energy, resident memory, and frame-time improvements remain unverified.

Review description: Fit proportional, uncropped day/night panoramas into the
upper half of the scene and resize both source images to 1584 × 672. Preserve
loop timing and lifecycle behavior, share textures for wide-preview coverage,
and regenerate the brightness data/chart for the new visible window.
Review against previous tip 7ef7881 or the full increment against its base.

Pre-existing uncommitted notes and MeadowScene trailing whitespace are preserved
outside the review commit. A concurrent DailyFocusCard wording edit is also
excluded and preserved. Review and user learning explanation remain pending.
Learning prompt: Why does fitting the full image into half-height make clouds
smaller, and what failure case would break horizontal coverage during resizing?
No merge, push, or hub writes.


## Performance clarification — artwork workload, 2026-11-03

User: “the app does nothing, counter and animation. However the animation moved
large png image”

For this counter/slow-scene workload, the reported CPU/energy readings warrant
investigation. Inspected actual assets: both skies are 3168 × 1344; landscape is
1678 × 937; character is 1132 × 1389. A basic RGBA8 representation of the two
skies would occupy about 32.5 MiB, excluding other resources and possible copies.
This is a format-based estimate, not measured resident texture memory.

MeadowScene retains the sprite nodes/textures and creates its masked shadow
texture once. Frame updates change positions/opacity and compute illumination;
they do not explicitly reread PNG files or recreate textures. Moving large
artwork can incur rendering cost even with small node count. Candidate experiments
remain 60 versus 30 FPS and Home versus Settings, followed by CPU/power traces.
No benchmark, optimization, artwork change, or measured improvement performed.

Sources: [SKTexture](https://developer.apple.com/documentation/spritekit/sktexture)
and [RGBA8 format](https://developer.apple.com/documentation/metal/mtlpixelformat/rgba8unorm).

## Question — performance gauges, 2026-11-03

User: “how do you find performance?” Screenshot shows CPU 35%, memory 145 MB,
Energy Impact High, 60 FPS, and zero instantaneous disk/network traffic.
These are user-supplied observations; device/build configuration and workload
duration are unverified. No Instruments trace or repeatable baseline collected.

Answer: I’d investigate energy efficiency before calling this healthy for Stick.

| Reading | Assessment |
| --- | --- |
| 60 FPS | Reaching the displayed frame-rate target. |
| 35% CPU | Higher than I’d want for this slow-moving scene. |
| 145 MB memory | One reading cannot establish a leak; check whether it grows. |
| High energy impact | The main concern for battery use. |

Measure a Release build on the phone with Time Profiler and Power Profiler,
comparing Home, Settings, and background activity.
[Apple profiling guidance](https://developer.apple.com/tutorials/instruments/identifying-a-hang)
[Apple energy guidance](https://developer.apple.com/documentation/xcode/analyzing-your-app-s-battery-use)

The first experiment I’d try is 30 FPS for the scenery, comparing visual quality
and measured cost against 60 FPS. The code’s per-frame lighting calculations
and frequent SwiftUI header updates are also candidates to profile. Their actual
contribution remains unmeasured.

Source inspection: HomeView uses SpriteView without a frame-rate override;
MeadowScene.positionSky recalculates shadow/header illumination each update and
publishes changed SkyAppearance.darkness. These are hypotheses for investigation,
not proven bottlenecks. No implementation or performance improvement claimed.
Frame-rate source: https://developer.apple.com/documentation/spritekit/skview/preferredframespersecond

## Question — permanent storage, 2026-11-03

User: “where are session and domains stored permanently ?”

Answer: Both share one local JSON file on your phone:

```text
<App data container>/Library/Application Support/Stick/sessions.json
```

It contains the ordered domains, current domain ID, and all sessions with their
timestamps. [DomainStore.swift](/Users/bogu/Workspace/bparol/swifty-apple/apps/stick-app/Stick/Sources/Domains/DomainStore.swift:6)
encodes the snapshot with Codable and writes it atomically.

Application Support is inside the app's private sandbox.
[Apple documentation](https://developer.apple.com/documentation/foundation/url/applicationsupportdirectory)
The file survives app relaunches; deleting the app removes its local data.
[Apple's deletion explanation](https://support.apple.com/en-us/102598)

## Explicit iteration squash — 2026-11-03

User invoked pp_squash on feature/sticks/add-first-stick against
feature/sticks/00-base. Squash only; review remains pending.
Original source commits, oldest first:

- b2d90b5dce738d67321182fd338acc574cda8822
- a102ddc5df0c98bbfc3830fa75eaca1abe409c98
- 7d2bf155848fae61afe52b2064b12143eb9ceecc
- 1b7f2a73b7cef3f302b355da5222f9b9167a8187

New squash: 7ef7881e2e9179eaa436525ac2861b1a9a82cdc3.
The prior squash title list is flattened without dropping original titles.
Existing uncommitted signing Q&A stays uncommitted and outside the squash.
Status: complete; identical committed tree, base parent, and one unique commit verified.
No merge, deletion, push, or hub update.


## Question — automatic signing, 2026-11-03

User: “is it because of autoamtic signing ?” (screenshot: Automatically manage
signing enabled, Personal Team selected, bundle ID com.parbo.cheatah).

Answer: No. Automatic signing manages the certificates and provisioning needed
to run the app on your phone. Leave it enabled.
[Apple documentation](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)

The alert comes from our saved-data loader. The likely cause is older session
records missing the newly required domain-name field. Changing signing settings
will not fix that data-format mismatch.

## Sessions history revision — ready for review

2026-11-03 on `feature/sticks/add-first-stick`, extending the current review
increment at 7d2bf15; base `feature/sticks/00-base` unchanged.
User accepted the recommended behavior, architecture, and test coverage.

- A Sessions row with a native chevron below My domains opens session history.
- Include completed, running, and paused sessions, grouped by original start
  day, newest days/sessions first. Show domain, active duration, and status.
- Swipe-to-delete saves atomically. Deleting an unfinished session discards
  its time and returns the same domain to waiting, without advancing the cursor.
  Deleting completed history removes it from future totals. Failed writes
  leave history, session status, and cursor unchanged.
- Extend AppModel actions and typed navigation; a native SessionsView owns
  presentation only. Add a domain-name snapshot to each session, so deleted
  domains remain readable. Existing domains resolve to their current name;
  deleted domains use the name recorded at session start. No migration code.
  Earlier development snapshots without the name field require a data reset.
- TDD for grouping, ordering, deletion, totals, relaunch, names, and failure
  consistency; UI tests and visual review afterward, including an empty list.

Implementation uses the existing JSON snapshot and publish-after-save path.
SessionDayGroup is derived presentation data, not another persisted collection.
The only row timer refreshes running duration; app/scene state stays in AppModel.

TDD red: /tmp/stick-history-red.xcresult failed to compile on absent grouping,
deleteSessions, and saved-name APIs. Green /tmp/stick-history-model.xcresult
passes all 49 unit tests. These cover original-day/newest-first grouping,
completed deletion affecting subsequent totals, running/paused deletion returning
the same domain to waiting, preserving a different active session, relaunch,
failed-write consistency, names after rename/domain deletion, and empty history.
Tuist generation and whitespace checks pass; separate practice swift test passes
12 using a /tmp scratch build. Full /tmp/stick-history-flow.xcresult passes
49 unit tests and 7 UI tests on iPhone 17 Pro / iOS 26.3 Simulator. The new UI
flow covers Settings → Sessions → Back, empty state, newest-first paused and
completed rows, running rows, swipe deletion, preserving a different active
session, same-domain waiting after unfinished deletion, and relaunch persistence.
Reviewed screenshots under /tmp/stick-history-flow-attachments; empty, grouped,
running, and paused rows are clear. Reviewed the Settings Sessions chevron row
in /tmp/stick-history-settings-attachments. Only existing App Intents metadata
warnings.
No physical-device validation or performance/energy claim. The snapshot remains
synchronous and grows with history; no export, migration, or session-detail view.

Self-review: deletion only removes requested IDs and leaves currentDomainID
unchanged; no artificial completion or cursor advance is introduced. Groups use
the stored attribution day, not display-time calendar conversion. Snapshot names
keep removed-domain rows readable; live domains resolve current names.
Learning explanation pending: “Why does deleting an unfinished session leave the
cursor unchanged, and what should happen if saving that deletion fails?”
No assessed learning claim. Human review pending; no merge, push, or hub writes.

Review description: Add a Sessions chevron row beneath My domains and a native
history list grouped by original day, newest first. Include running/paused
sessions, snapshot domain names for deleted-domain history, and save deletions
before updating app state. Removing unfinished time resets the same domain to
waiting without advancing; removing completed history adjusts future totals.

Apple references: [List deletion](https://developer.apple.com/documentation/swiftui/dynamicviewcontent/ondelete(perform:))
and [value navigation](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack).
Review this revision against 7d2bf15, and the full increment against
feature/sticks/00-base. Base unchanged; no independent full-feature review yet.

## Review revision — two-line domain title

2026-11-03, same increment; user requested at most two title lines on Home.
Keep the 42-point font and cap the saved domain name at two lines with trailing
ellipsis. This is a view-only constraint; no architecture or timing change.
No new automated tests for this small layout adjustment. Simulator build passed
(`/tmp/stick-title-limit-build.log`); required practice swift test passed 12;
whitespace checks passed. Long-name visual review remains for human review.
Apple references: [lineLimit](https://developer.apple.com/documentation/swiftui/view/linelimit(_:)-513mb)
and [truncationMode](https://developer.apple.com/documentation/swiftui/view/truncationmode(_:)).
Review pending; base unchanged, nothing merged or pushed.

## Session timing change request — ready for review

2026-11-03. Revise the existing unapproved increment
`feature/sticks/add-first-stick`; base `feature/sticks/00-base` remains unchanged.
Behavior was agreed step by step. Implemented and validated; human review pending.

Confirmed behavior:

- Replace check-in with Start (play), Continue (play), and Pause (HH:MM,
  pause icon). Remove “A little time counts.” The timer shows the current
  session's accumulated active time, excluding paused gaps.
- Start, pause, resume, and completion timestamps must persist. Running time
  continues through Settings, backgrounding, and app shutdown.
- Pause saves the current fragment. Continue adds a fragment to the same
  session, attributed to its original start day even after midnight.
- A circular Stop button appears while running or paused, hidden before Start.
  Stop saves and completes the session/topic, then advances to the next topic
  in waiting/Start state. There is no separate Finish topic action.
- Multiple topics and repeated sessions per topic can be recorded on a day.
  Wrap around after the final topic. Totals accumulate per topic and start day.
  Show a total-time toast after Stop only.
- Remove daily rotation. An unstarted topic waits across dates; unfinished
  sessions retain their topic and original day until stopped. A subsequent
  Start establishes its own day attribution.
- Keep the list in user-defined order with a separate current-item cursor.
  Remove Today; only the current row shows waiting, started, or paused.
- Allow rename/reorder/delete during sessions. Reordering preserves the current
  topic; Stop selects its successor from the latest order. Deleting the current
  topic completes/saves its session, retains history, and selects the next
  remaining topic waiting. Deleting the last topic restores the empty screen.

Architecture accepted: extend AppModel and the atomic JSON snapshot with a
separate current-domain ID and timestamped session fragments. Persist before
publishing state. SwiftUI derives elapsed time; SpriteKit remains visual only.
User explicitly rejected migration (no users yet): use a fresh sessions.json
schema, leaving earlier development files unused. No migration code or tests.

Test approach accepted: TDD for timing, persistence/failure consistency,
original-day attribution, cursor/totals, and editing/deletion; UI tests and
visual review afterward. Replace obsolete check-in/rotation tests, retain
unrelated domain validation, onboarding, and scene tests.

TDD red: /tmp/stick-session-red.xcresult failed to compile because the requested
session/cursor APIs were absent. Initial green attempts caught a HomeView
syntax typo and missing try inside throwing #require expressions; corrected.
Model green: /tmp/stick-session-model-v3.xcresult passed all 42 unit tests.
Full /tmp/stick-session-flow.xcresult passed 42 unit tests and 6 UI tests on
an iPhone 17 Pro / iOS 26.3 Simulator. Tuist generation and whitespace checks
pass; separate practice swift test passes 12 tests using a /tmp scratch build,
without editing the hub. Only the existing App Intents metadata warnings appear.

Reviewed running controls, Stop toast, and reordered-list screenshots under
/tmp/stick-session-flow-attachments. The paused screenshot caught overlapping
Pause/Continue labels. A focused follow-up passed but reproduced the visual
artifact; the restored paused layout also needed checking. Moved TimelineView
inside the running label so the controls and paused label remain regular SwiftUI
views. Added paused-after-Settings/relaunch captures and assertions that Stop is
hittable and separate from Continue after restoration.

Final /tmp/stick-session-final.xcresult passed all 42 unit tests and 6 UI tests.
Immediate screenshots still caught intermediate rendering; the screenshot helper
now allows one second for transitions after behavioral assertions. Focused
/tmp/stick-session-settled.xcresult passes with clean running, paused,
paused-after-Settings, paused-after-relaunch, and Stop-toast captures under
/tmp/stick-session-settled-attachments. No remaining persistent control artifact
was reproduced in these settled captures. No drawing/compositing workaround added.
Practice swift test again passes 12; whitespace checks pass.
No physical-device or energy/performance validation. Wall-clock changes can
affect durations; negative fragment intervals clamp to zero. Snapshot rewrites
remain synchronous and grow with history. No history browsing/export screen.

Self-review: checked one-session ownership, original-day attribution, cursor
wrap after latest ordering/multi-delete, history retention, and publish-after-save.
Human line-by-line review remains pending; no independent feature review yet.

Review description: Replace daily check-in and midnight rotation with persistent
Start/Pause/Continue/Stop sessions. Keep user ordering separate from the current
cursor, advance only on completion, and total active time by domain/start day.
Show status on the current Settings row and a total toast after Stop. Use a
fresh snapshot without legacy migration, as explicitly requested.

Learning explanation pending: “Why persist timestamps rather than timer ticks,
and what should happen to the session and cursor if saving Stop fails?”
This reuses value snapshots, main-actor ownership, dependency injection, and
atomic persistence; no independent mastery claim.

Review range: previous increment tip b2d90b5 to this revision; complete increment
against feature/sticks/00-base. Keep the feature base unchanged pending approval.

Primary API references checked for this implementation:

- [Timeline schedule](https://developer.apple.com/documentation/swiftui/timelineschedule/animation(minimuminterval:paused:))
- [Date intervals](https://developer.apple.com/documentation/foundation/date/timeintervalsince(_:))

No merge, push, or hub writes authorized. Learning explanation remains pending.

## Explicit iteration squash — 2026-11-01

User requested `pp_squash` on `feature/sticks/add-first-stick` relative to
`feature/sticks/00-base`. This authorizes squashing only: no merge, deletion,
push, or iteration approval. Preserve the final tree and every original title.
The implementation and review state above/below remain unchanged. Prior checks
apply because no code changes during this operation.

Original implementation commits, oldest first:

- 281c784cef0e6adba2b1b27ec9250563759f507c Add the first-use card and persist the first stick
- 2170318625fffe384d229f6f6ab61f4a7427bbbd Refine the first-use prompt and outline its twig CTA
- aec3ef4b9b9d799471e84c42f0473b05f922b199 Show saved sticks in Settings and persist daily check-ins
- 749c72018603ba27d81e6f2d3f877264a15fb485 Complete stick editing, deletion, reordering, and daily rotation
- 72eede5697ea35c641f16ba00fe2770e851d5925 Add the static stick character above the home card
- 09d2bc88e2412656d4ca55672f5d5664f89d5aef Add a white app icon with the Stick wordmark
- ecc542ac087940f1953e47027acfa9569f4301b6 Use only the twig on the white app icon
- 7bdd3b475af5c76d7a656ee9d5a0f171cddeb508 Update domain wording, home layout, and app configuration
- 77ddadcd13a20376585cc3e51ab85a36211290b0 Use domains, advance completed focus at midnight, and soften sky shading


## Current revision — domains, midnight completion, gradual lighting

2026-10-31 on `feature/sticks/add-first-stick`, base unchanged. User confirmed
TDD for lighting continuity, rotation, and data compatibility, followed by UI
and visual review. The iteration remains pending review; nothing merged or pushed.

Confirmed rotation: check-in never replaces the active domain during the day.
With daily rotation on, advance by elapsed local calendar days, checked or not.
With it off, unchecked domains carry across days; a completion advances once at
the following midnight (or once on the next opening after missed days).
The persisted anchor excludes old completion records when a domain comes round
again. Rename, delete, add, and toggle actions synchronize the date first.
Manual reorder still selects the first domain and clears only today's check.

Rename focus-related types, files, properties, actions, text, accessibility IDs,
and the debug UI-test token to domain terminology. Preserve StickApp, module,
project, app branding, StickWordmark, TwigMark, character names, and artwork.
Application Support remains under the app's Stick directory. New snapshots use
domains.json, `domains`, and `domainID`. Read-only legacy filename/key aliases
are necessary to retain saved IDs, checks, order, and preferences. The new file
wins once written; old files remain untouched. Corrupt data still blocks writes.
Historical notes below retain their original terminology and decisions.

Lighting diagnosis: the old bundled curve drops from opacity 1 to about 0.38
in three seconds of dawn on the current 60-second circuit. Blend daylight
progress (80%) and measured artwork darkness (20%), then smoothstep. This
spreads dawn/dusk across daylight, keeps full-day clear/full-night dark, and
has no opacity jump at image/cycle boundaries. Keep the user's 60-second speed.
The offline review chart generator uses the same curve; the JSON artwork data
is unchanged. No artwork edits or claimed performance improvement.

TDD red `/tmp/stick-domain-red.xcresult`: missing completion-driven advancement
and steep dawn curve reproduced. Migration red
`/tmp/stick-domain-migration-red.xcresult`: modern domain schema and legacy
filename lookup fail before implementation. Initial model run exposed old
assertions that assumed rotation-off froze completed domains forever; revise
those expectations to the confirmed rule while retaining history/reorder checks.
The expanded suite now passes 53 unit tests, including midnight versus same-day
reload, unchecked carry-over, one-step advancement after missed days, daily
rotation without checks, old completion exclusion, and old/new storage formats.
Final `/tmp/stick-domain-flow.xcresult` passes all 53 unit tests and 6 UI tests
on iPhone 17 Pro / iOS 26.3 Simulator. Reviewed first-use, Settings, saved-domain,
and largest-text screenshots under `/tmp/stick-domain-flow-attachments/`.
The longer prompt wraps without automatic font sizing. Reviewed the regenerated
lighting curve and a live intermediate-shade capture at
`/tmp/stick-domain-transition.png`; the artwork remains clear and Stick is static.
The initial immediate-launch capture was the splash screen and was excluded.
Existing user removal of the header wordmark is preserved, and its UI expectation
now matches that committed design. Tuist generation, chart regeneration, and
whitespace checks pass. The verified app is installed and opened on the simulator.
No physical-device verification or performance claim. Ready for explicit review.

PR description: Use domain naming throughout the daily focus flow while
preserving the Stick brand and existing saved data. Keep check-ins on today's
domain until midnight; daily rotation always advances, while completion mode
carries unchecked domains forward. Soften the landscape dawn/dusk curve and
regenerate its review chart. Validate persistence and boundaries with TDD and
the real editing/check-in flow with UI tests.

No hub records, outer files, branches, or submodule pointers are changed.
Review and user explanation remain pending; tests do not establish mastery.

## App icon revision — twig only

2026-10-29. User requested removing the stick text from the app icon.
Rendered only the existing TwigMark on solid white, enlarged and optically
centered with padding. Retains original twig, leaf, and outline colors.
Export verified as 1024 × 1024 with no alpha; visual review confirms no text.
Existing AppIcon asset configuration remains in place. Simulator build passes
(`/tmp/stick-twig-icon-build.log`); whitespace checks pass.
User-staged Home changes and source JPEG are excluded from this revision.
No merge or push; review pending.

## Current addition — white wordmark app icon

2026-10-28, on `feature/sticks/add-first-stick`, pending review.
User asked: “create an icon for the app. Generate white icon displaying the StickWordmark”.
Rendered the existing StickWordmark SwiftUI view directly on white, with its
rounded green lettering and original vector twig, using a temporary macOS
ImageRenderer exporter. It reads the current wordmark and tint definitions;
no runtime views are changed. The PNG is 1024 × 1024, opaque, with generous
padding for system icon masking. Added an AppIcon asset set and selected it
in the app target. No custom dark/tinted variants were requested.

This is an image and build-configuration change. Validate the export visually,
check dimensions/opacity, and build the asset catalog; no behavioral tests or
manufactured TDD failure. Existing uncommitted user edits to HomeHeader,
HomeView, and DailyFocusCard, plus the staged stick.jpeg, remain separate.
Verification: 1024 × 1024 PNG, no alpha, visually checked on white.
Tuist generation and `/tmp/stick-icon-build.log` simulator build pass; compiled
Info.plist selects AppIcon. Whitespace checks pass. The build includes the user's
current uncommitted Home edits, which remain outside the icon commit.
Ready for review. No merge or push.

References: [SwiftUI ImageRenderer](https://developer.apple.com/documentation/swiftui/imagerenderer),
[App icon asset catalog](https://developer.apple.com/documentation/xcode/configuring-your-app-icon).

## Current addition — static stick character

2026-10-28, on the existing pending iteration `feature/sticks/add-first-stick`.
User requested background removal from Resources/stick.jpeg and a static
character positioned as in Resources/base_design.jpeg. Keep the original JPEG;
bundle the transparent PNG cutout. The JPEG was already staged by the user and
must remain staged separately from this implementation commit.

User chose TDD plus visual review. Two scene tests fail first because the
character node is absent: `/tmp/stick-character-red.xcresult`. They check actual
asset loading, design placement, foreground layering, aspect ratio, stationary
behavior during sky motion, and resizing. Implement one SpriteKit sprite above
the landscape shade, centered with a bottom anchor at 36% of scene height and
height 30%. No animation or changing tint. Existing scene node-count expectations
now include the character.

Green: `/tmp/stick-character-green.xcresult` passes 45 unit tests and two focused
Home UI tests. Visual review of saved-stick and largest-text first-use screenshots
in `/tmp/stick-character-green-attachments/` confirms transparent edges and a
static character above the card without overlap. Tuist generation and whitespace
checks pass. No physical-device validation or performance claim.

PR description: Add the transparent stick character to the existing SpriteKit
world, centered on the path above the Home card using reference-relative sizing.
Keep it still during sky animation and preserve its proportions on resize.
Validate missing-character red tests, passing scene tests, and Home screenshots.

Question: “tdd with review. How do you write the tests? Red-green, empty mody
first or other method”
Answer: Use red → green → review. Write a test for observable behavior and run
it against the current implementation; here it fails because the character is
missing, so no empty method is needed. Add the smallest implementation that
passes, refactor only when useful, and review screenshots against the design.
An empty method is useful only when a new API needs a compiling stub to reach
a meaningful failing assertion. Avoid adding an artificial failure just to get red.

All changes stay within this app. Review remains pending; no merge or push.

## Current review — complete stick management

Date: 2026-10-27. Base `feature/sticks/00-base` remains at `9fed1a4`.
Iteration `feature/sticks/add-first-stick`; review pending, nothing merged or pushed.
This revision completes the originally requested editing, deleting, reordering,
and daily rotation toggle. Earlier deferrals below are historical and superseded.
Retain the agreed TDD coverage for model/storage behavior and UI tests afterward.
All work stays within this app; no outer hub records or submodule pointer updates.

Settings: tap a row to edit its name; Edit exposes native drag and delete controls,
and swipe-to-delete also works. Today labels the first row. Unlimited additions
append to order. Rename keeps the string ID and check. Every real reorder makes
the first row today's stick and clears only today's check, even when that first
row stays the same. Unchanged order does not clear it. Deleting the current stick
clears today's check; removing another preserves it. Deleting all restores onboarding.
Past dates remain, including checks for deleted sticks.

Daily rotation defaults on, advances by elapsed calendar days including missed
days, and persists its anchor so relaunch never rotates twice. Disabling freezes
order; enabling starts from the current day without catch-up. Manual reorder
anchors today. Gregorian dates and day distances respect the injected time zone
and DST. No backward rotation on a backward clock change.

Main tradeoff: persist ordered sticks, flat daily checks, toggle, and anchor as
one atomic JSON snapshot. Saving before publishing prevents reordered sticks
and stale same-day checks being committed independently. Read legacy arrays and
separate checks without losing IDs/history; leave the legacy file untouched and
ignore it after migration. Native shared add/edit sheet retains names on failure.
The synchronous local snapshot suits the current small string-only dataset;
notifications and physical-device performance validation remain outside this change.

TDD red: `/tmp/stick-manage-red.xcresult` fails compilation on the missing rename,
delete, reorder, and rotation APIs. Initial green `/tmp/stick-manage-model.xcresult`
passes 41 unit tests, including write-failure consistency and legacy migration.
The expanded unit suite passes 43 tests, adding DST/year-boundary and invalid
reorder checks. The actual Settings UI flow passes rename, switch-off, native
handle drag, restart with new order/check state, deletion, and restart empty.
The first UI run exposed automation mismatches: tapping the outer toggle row
missed the inner switch, edit mode prefixes row labels with Remove, and plain
rows are now buttons. Corrected test targeting using switch coordinates and
stable row IDs; no test-only reorder or mutation hook was added. Final full-suite
verification: `/tmp/stick-manage-verified.xcresult` passes all 43 unit tests
and 6 UI tests on iPhone 17 Pro / iOS 26.3 Simulator, with serial testing.
Inspected the edit controls and reordered Settings screenshots in
`/tmp/stick-manage-verified-attachments/`: Reading is first and marked Today;
rotation is off. Existing first-use, carousel, persistence, header, fixed-font,
check-in, and navigation regressions all pass. Tuist generation and whitespace
checks pass. No physical-device or energy claim. Ready for explicit user review.

PR description: Finish stick management in Settings with name editing, deletion,
manual drag reorder, and a persisted daily rotation toggle. Keep today's stick
first and clear only today's check on reordering, preserving history. Save list,
checks, and rotation metadata together, migrate existing data, and verify the
actual simulator flow plus failure and calendar behavior.

References: [onMove](https://developer.apple.com/documentation/swiftui/dynamicviewcontent/onmove(perform:)),
[EditButton](https://developer.apple.com/documentation/swiftui/editbutton),
[atomic writes](https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic).
User review and explanation of the main decision/failure case remain pending;
passing tests do not authorize a merge or establish learning mastery.

## Earlier iteration records

## Current increment — first stick and first-use card

Date: 2026-10-27. Base: `feature/sticks/00-base` from approved main `9fed1a4`.
Iteration: `feature/sticks/add-first-stick`. Implemented; review pending.
User approved TDD for name validation/stable IDs and persisted sticks, followed
by UI tests for the first-use flow and examples. Visual review for styling.

Agreed first increment: empty Home shows “What will you stick to today?”, four examples
(Photography, Guitar, Drawing, Reading) advancing right-to-left every five
seconds, no supporting line, and “Add your first stick”. The CTA opens a native
name editor. Saving a nonempty trimmed name stores a string ID/name and replaces
the introduction with the existing daily card. Card fonts remain fixed.
Rename Interests to Sticks. Data survives relaunch. The persistence revision
below now also saves daily checks. Cancel must not create a stick.

Later reviewed increments: edit/delete/reorder list management and calendar-day
rotation. Settings can now list/add sticks and dated checks are persisted by
the revision below. Confirmed rotation policy: local
calendar-day rotation toggle defaults on; disabling freezes the current stick,
re-enabling starts from it without catching up. Reordering makes the first row
today's stick and clears only today's cached check, preserving prior dates.
At most one check record per YYYY-MM-DD key; “rerder” means reorder, not render.
Rotation and clearing today's cache on manual reorder remain future requirements.

Main tradeoff: a small JSON snapshot in Application Support fits the current
string-ID/name model and simple local list. Native SwiftUI owns the editor and
first-use presentation; SpriteKit continues to own scenery. The example task
must stop while Home is inactive, covered, or showing the editor. Reuses existing
Observation, identity, and lifecycle boundaries. No hub curriculum writes.

TDD: `/tmp/stick-first-red.xcresult` failed to compile because the new store
and model API did not exist. After implementation,
`/tmp/stick-first-model-green.xcresult` passed all 29 unit tests. Coverage includes
an empty/missing store, trimmed names, distinct/stable string IDs and order after
reload, blank rejection, real write failure without publishing unsaved data,
and unreadable JSON remaining untouched while saves are blocked.

Final `/tmp/stick-first-flow.xcresult`: 29 unit tests and 5 UI tests passed on
iPhone 17 Pro / iOS 26.3 Simulator, serial testing. UI checks cover example
advancement, absent supporting line, disabled blank submission, cancellation,
first save replacing onboarding, persistence after relaunch, check-in/navigation,
and the existing header/rendering checks. Tests use isolated storage files and
do not clear the person's normal sticks. Tuist generation and whitespace checks
passed; only the existing App Intents metadata-extraction warnings appeared.

Visual review: inspected first-use card, native editor, saved first stick, and
largest-text screenshots under `/tmp/stick-first-flow-attachments/`. Confirmed
the live example advances from Photography to Guitar after five seconds:
`/tmp/stick-first-home.png` and `/tmp/stick-first-home-next.png`. Fixed card fonts
are retained. Reduce Motion uses a fade; no physical-device validation or
energy/performance claim. Native editor styling is used as the initial UI.

PR description: Replace the empty daily card with the first-use prompt, four
sliding examples, and an Add your first stick CTA. Present a native name editor,
save a trimmed name and stable string ID in a local JSON array, then show the
saved stick on the daily card. Settings lists saved sticks and can add more.
Save check-ins by local date and stick ID, restoring the selected state after
restart, and use dark-green/checked-sage daily button fills. Preserve cancellation
and save failures without false success or overwritten unreadable data. Validate
persistence/model behavior with TDD and the real flow with UI tests. Editing,
deleting, reordering, and rotation/toggle remain separate increments.

References: [Application Support](https://developer.apple.com/documentation/foundation/url/applicationsupportdirectory),
[atomic data writes](https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic),
and [view-bound task cancellation](https://developer.apple.com/documentation/swiftui/view/task(id:priority:_:)).
Main review decision: save before publishing the new stick, and block writes
after a load failure. User explanation and implementation review are pending;
passing tests do not establish learning or authorize merging. Nothing pushed.

### First-use CTA revision — 2026-10-27

User requested the prompt “What will you stick to today?” and a transparent
CTA with a green border/text and the twig icon after its title. Reuse the same
vector TwigMark as the header; center the label/icon as a group. Apply this
style only to Add your first stick; the daily check-in keeps its filled sage
button. Fixed card font sizes and the existing action/accessibility label stay
unchanged. This is a visual revision of the current iteration: retain the
agreed model/storage tests and UI flow checks, with visual review for styling.
Update UI text expectations to the revised prompt. Review pending.

Revision validation: `/tmp/stick-first-outline.xcresult` passed all 29 unit
tests and 5 UI tests. Inspected the outlined CTA and centered label/twig group
at default and largest accessibility text size under
`/tmp/stick-first-outline-attachments/`; prompt and button fit with fixed fonts.
Whitespace checks passed. The first-use save/cancel, carousel, persistence,
and daily check-in navigation checks continue to pass. Nothing merged or pushed.

### Settings list and check persistence fixes — 2026-10-27

User reported saved sticks missing from Settings and check-in selection lost
after restarting. Settings now receives the saved array and lists every stick,
with Add a stick reusing the native editor so the list can grow. AppModel now
derives the selected check from persisted date/stick records rather than an
app-run Boolean. One local Gregorian YYYY-MM-DD key per day, flat JSON array
in sticks.checks.json beside the existing sticks.json; previous days retained.
No stick-file migration or deletion needed. App state publishes a check only
after its atomic save succeeds. Repeated checks do not duplicate the date.

The root refreshes the day on activation and significant-time-change events,
including midnight. The current first stick remains today's stick until the
later rotation/reorder increment. Clock/time-zone injection supports boundary
tests. A different current ID cannot inherit the old stick's same-day check.

Corrected visual request: the unchecked daily button is filled forest green,
matching the card text, with the existing ivory label. Checked keeps the sage
fill and ivory checkmark/label. Only Add your first stick remains outlined.
No new outline is applied to the daily button.

TDD red: `/tmp/stick-check-red.xcresult` reproduced the reported restart bug
with a failing hasCheckedIn assertion after reloading the same store. Added
coverage for unique date records, previous-date retention, current-ID matching,
local midnight/New Year keys, failed saves, and unreadable history protection.
UI regression checks now include the Settings list and adding a second stick,
both persisted after relaunch, plus checked state after relaunch.
Review of the current iteration and this revision remains pending.

Validation: `/tmp/stick-check-green.xcresult` passed 34 unit tests and 5 UI tests.
The real Settings flow adds Guitar and Reading, displays both, then reloads both
after an app restart. The check-in flow verifies selected state after Settings
navigation and a full restart. Date fixtures cover local date rollover and
calendar-year boundaries; cache tests verify one entry per day and retained
history. Tuist generation and whitespace checks passed. Only the existing
App Intents metadata warnings appeared. No physical-device validation.

Visual review: inspected `/tmp/stick-check-green-attachments/` screenshots of
the filled dark-green unchecked CTA, sage checked CTA after relaunch, and
Settings containing Guitar and Reading with Add a stick. All match the
corrected request. No hub files modified, and nothing merged or pushed.

Sources: [calendar components](https://developer.apple.com/documentation/foundation/calendar/datecomponents(_:from:))
and [significant-time notifications](https://developer.apple.com/documentation/uikit/uiapplication/significanttimechangenotification).

## Previous increment — reference-styled daily card

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


## Physical-device automation question — 2026-11-05

User question (verbatim):

> for fun, I want to have a dedicated test target I can run on my physial device that has a button that launches app and open settings:
>
> let app = XCUIApplication(bundleIdentifier: "our isdentifier")
> app.activate()
>
> let button = app.buttons["Settings"]
> XCTAssertTrue(button.waitForExistence(timeout: 5))
> button.tap()
>
> is it doable?

Answer: a dedicated XCUITest target can run this on a physical iPhone through
Xcode's test runner. The current Project.swift app identifier is
`com.parbo.cheatah`; README still lists a different identifier. The Settings
button has the stable accessibility identifier `open-settings`. An example:

```swift
import XCTest

@MainActor
final class DevicePlaygroundTests: XCTestCase {
    func testOpenSettings() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.parbo.cheatah")
        app.activate()
        let button = app.buttons["open-settings"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }
}
```

`activate()` launches if needed and otherwise foregrounds the existing instance;
it does not reset navigation. This example assumes Home is visible. Select the
signed physical device and use the test's run diamond in Xcode. A standalone
phone app with its own button cannot use XCUIAutomation as an ordinary app API;
that requires a running UI-test session. For an independent on-device launcher
button, a small companion app and a Settings deep link in Stick would be the
appropriate design instead. No target or Swift source changed; no tests run.
Existing local edits preserved. No commits, pushes, or hub writes.

Sources: [Apple activate](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/activate()),
[Apple XCUIAutomation](https://developer.apple.com/documentation/XCUIAutomation),
[Apple running tests](https://help.apple.com/xcode/mac/current/en.lproj/dev42b289fbc.html).


## Device MCP experiment — 2026-11-05, uncommitted prototype

User request: “I would like to create mcp that I can use to control my app via
the runner app (the app that runs XCTest)”. Clarification offered custom Swift
runner versus WebDriverAgent; user follow-up: “Tell me pros and cons”.

Confirmed: control Stick through the XCTest runner from an MCP client, including
a physical iPhone. Proposed implementation, not a confirmed preference: local
Python MCP server over stdio, authenticated HTTP relay on the Mac, and a Swift
runner polling for serial commands. Initial tools are activate, inspect, tap,
type_text, and screenshot. No arbitrary Swift evaluation or app-state API.

Started the custom prototype while awaiting the optional preference answer.
After the user requested comparison, stopped extending its behavior and checked
what was already written. Custom runner advantages: small Swift implementation,
explicit tool behavior, easy app-specific extension, learning value. Costs:
we own command lifecycle, recovery, accessibility observations, gestures, timing,
and compatibility. WebDriverAgent advantages: existing XCTest command server,
remote interactions, device/simulator support and USB support. Costs: a larger
external dependency, its API and setup, plus ongoing compatibility updates.
Both require runner signing and an active automation session. The MCP wrapper
is still ours either way. Recommendation: custom for exploring the bridge;
WebDriverAgent when dependable broad app control is the main objective.

Files: Project.swift adds StickAutomationRunner and an explicit StickAutomation
scheme; the normal Stick scheme excludes the long-lived test. Swift command loop
lives in Stick/AutomationRunner; Python relay, tests, setup and limitations live
in tools/device-mcp. README links the technical setup. Prior artwork, scene,
tests and notes edits are preserved. No hub writes, commits, merges or pushes.

Validation so far: Tuist generation succeeds; Simulator build-for-testing for
StickAutomation succeeds (/tmp/stick-mcp-build.log); four Python relay tests pass
(serial dispatch, correlated results, disconnected runner, expired work, and
error propagation); required practice swift test passes all 12 tests.
The app unit-test run is pending at this entry. No MCP client-to-runner command
or physical-device connection has been verified. Local network, signing and
one-hour session behavior remain unverified. This is a prototype, not a finished
or connected MCP installation. User's runner choice and review remain open.

Learning explanation pending after a direction is chosen: why must the runner
remain in an active XCTest session, and why is automatically retrying a timed-out
tap unsafe? No mastery assessment or curriculum-file writes.

Primary sources: [Apple XCUIAutomation](https://developer.apple.com/documentation/XCUIAutomation),
[Apple async XCTest](https://developer.apple.com/documentation/xctest/asynchronous-tests-and-expectations),
[Apple execution allowance](https://developer.apple.com/documentation/xctest/xctestcase/executiontimeallowance),
[WebDriverAgent](https://github.com/appium/WebDriverAgent),
[MCP SDK 1.x](https://github.com/modelcontextprotocol/python-sdk/tree/v1.x).


Device MCP follow-up — 2026-11-05.

App validation completed: 57 tests ran, 54 passed and three MeadowSceneTests
failed with 13 assertion issues. Existing local layout changes use character
height 0.35 and foot position 0.32, while assertions expect 0.30 and 0.36.
These scene files were not changed by this MCP work and remain untouched.
Build warnings include the existing missing AccentColor and App Intents metadata
extraction warning. Whitespace checks pass.

User question (verbatim): “I'm rather thinking about full control of my app,
how the webdriven runner controls the app? how I can point it instruction to
perform a concrete steps in my app ?”

Answer: WebDriverAgent runs an HTTP server inside an active XCTest runner.
The client selects an app by bundle ID and sends structured requests. WDA
resolves accessibility locators into XCUIElement objects and invokes XCTest
interactions. The AI/MCP client interprets natural-language goals; WDA itself
executes individual commands. Suggested generic MCP surface: activate_app,
get_ui_tree, find_element, tap, type_text, swipe, long_press, screenshot and
wait_for_element. Example instruction: open Stick, go to Settings, add Guitar,
and verify it appears. The AI observes each screen, identifies controls, taps,
types, saves, and observes the result; it need not have a prewritten test per
flow. A deterministic script can call the same tools in a fixed sequence.
For Settings specifically, POST /session/{session}/element with using=
accessibility id and value=open-settings returns an element reference; POST
/session/{session}/element/{element}/click taps it. Accessible UI, text input,
gestures and screenshots provide broad UI control, not direct access to private
AppModel state. SpriteKit artwork may need coordinates or accessibility support
if individual scene objects become interactive. Stable accessibility identifiers
reduce ambiguity. Given the clarified preference for broad control, recommend
WebDriverAgent behind a generic MCP wrapper. No WDA installed or running;
custom draft remains uncommitted and is not validated end to end.

Current primary implementation sources:
[WDA app sessions](https://github.com/appium/appium-ios/blob/main/packages/webdriveragent/WebDriverAgentLib/Commands/FBSessionCommands.m),
[element search](https://github.com/appium/appium-ios/blob/main/packages/webdriveragent/WebDriverAgentLib/Commands/FBFindElementCommands.m),
[actions](https://github.com/appium/appium-ios/blob/main/packages/webdriveragent/WebDriverAgentLib/Commands/FBElementCommands.m).


Generic WDA MCP scope clarification — 2026-11-05.

User question (verbatim): “I want a generic purpose MCP that will be completely
driven via WDA. Befor we continue, what frameworks are using WDA on iOS ?”

Confirmed direction supersedes the earlier proposed Stick-only custom runner:
generic MCP, driven through WebDriverAgent, with app selection by bundle ID.
No further implementation until this framework discussion is settled. Existing
custom runner draft remains uncommitted; it is not the agreed final architecture.

Answer: Appium's XCUITest driver directly uses WDA and manages/proxies its
commands. Katalon Studio and Robot Framework's AppiumLibrary use it through
the Appium stack for XCUITest-backed iOS automation. Airtest uses WDA / its
customized iOS-Tagent fork. DeviceLab maestro-runner offers an explicit WDA
backend, though it also has other backends and is distinct from Maestro.
openatx/facebook-wda is a direct Python WDA client rather than a full test
framework. Apple's XCTest/XCUIAutomation sits underneath WDA; XCTest itself
does not depend on WDA. For the requested MCP, direct MCP-to-WDA HTTP calls
avoid requiring Appium; MCP-to-Appium-to-WDA remains an option when Appium's
session/device lifecycle management is useful. This is architectural guidance,
not a newly implemented integration. No new code or test runs in this follow-up.

Sources:
[Appium architecture](https://appium.github.io/appium-xcuitest-driver/latest/overview/),
[Katalon WDA](https://docs.katalon.com/katalon-studio/manage-projects/set-up-projects/mobile-testing/ios/mobile-install-webdriveragent-for-real-ios-devices-in-katalon-studio),
[Robot AppiumLibrary](https://docs.robotframework.org/docs/different_libraries/appium),
[Airtest iOS](https://airtest.doc.io.netease.com/en/IDEdocs/3.2device_connection/4_ios_connection/),
[maestro-runner backends](https://devicelab.dev/open-source/maestro-runner/docs/cli-reference),
[Python WDA client](https://github.com/openatx/facebook-wda).


Repetitive app workflows question — 2026-11-05.

User question (verbatim): “can I use any of these tools to perform repetivie
tasks and save time? I'm thinking about test scenarios where I need to create
a new user via signup or just reach particular path, and perform a task there”

Answer: yes. Appium can drive reusable signup and navigation scripts; Robot
Framework plus AppiumLibrary provides reusable named keywords. For the agreed
WDA-only MCP, use generic primitives with reusable parameterized scenarios in
a separate layer. Example pseudocode: signup(email, password), navigate to
Notifications, set a value, verify the result, then leave the app open for manual
inspection. Natural-language goals can be explored with the AI, then saved as
explicit steps with expected UI states for frequent repetition. Shared signup
steps can be composed into different scenarios. Scenario execution should wait
for concrete elements rather than fixed sleeps and stop with useful diagnostics
when a prerequisite fails. Signup requires a fresh identity or explicit account
cleanup; email/SMS verification needs an available test mechanism or a manual
handoff. Reinstalling the app does not delete server-side accounts. If signup
itself is not under test, provision a test account through a test fixture/API
when available, then automate the UI path. Such account provisioning would be
outside the WDA-only MCP; keep it a separate optional setup mechanism.
Session teardown must be configured to preserve the app when handing back to
the user. No additional automation implementation or test runs for this answer.

Sources: [Appium Python example](https://appium.io/docs/en/latest/quickstart/test-py/),
[Robot AppiumLibrary](https://docs.robotframework.org/docs/different_libraries/appium),
[XCUITest session capabilities](https://github.com/appium/appium-xcuitest-driver/blob/master/docs/reference/capabilities.md).

# Stick architecture

## Current boundary

`StickApp` creates a window containing `AppRootView`. The root stores an
`@Observable`, `@MainActor` `AppModel` in `@State`. The model holds a typed
`[AppRoute]` navigation path and lazily owns one `MeadowScene`.
It also owns ordered domains, a separate current-domain ID, and session history.
DomainItem holds a stable string ID and editable name. Advancing changes the
cursor, never the user's order. There is no date-driven rotation.

DomainStore reads/writes sessions.json, one atomic snapshot in Application
Support containing domains, currentDomainID, and sessions. This is a fresh
schema: old check-in/rotation data is not migrated or loaded. A missing snapshot
starts empty. Unreadable or structurally inconsistent snapshots block mutations
rather than being overwritten. Writes complete before observable state changes.
The synchronous snapshot suits current local use; tests inject isolated URLs.

Each FocusSession stores a string ID, domain ID, original local Gregorian
YYYY-MM-DD day, timestamped active fragments, and an optional completion time.
A fragment starts on Start/Continue and ends on Pause/Stop. The unfinished last
fragment identifies a running session; closed fragments without completion
identify a paused session. There is at most one unfinished session.

AppModel owns Start/Continue, Pause, and Stop. Each action saves the whole
snapshot before publishing. Stop closes any open fragment, records completion,
and advances the cursor together. Summing fragment intervals excludes pauses;
summing sessions by domain ID and original day yields the toast total. Every
resume retains the original attribution day, even across midnight or relaunch.
Settings/background/shutdown do not stop an open fragment. No background timer
or per-tick writes are required. The injected clock/time zone make this testable.
Wall-clock adjustments can affect time; negative intervals clamp to zero.

Renaming/reordering preserves the cursor and active session. Stop follows the
latest order, wrapping to the first domain. Deleting the current domain closes
its session and selects the next surviving successor in the same atomic write.
Deleting all domains clears the cursor and retains recorded sessions by ID.
The current row's waiting/started/paused status is derived, not separately persisted.

DailyFocusCard uses a pausable TimelineView only to refresh the running time
label. It derives elapsed time from timestamps, rather than accumulating ticks.
The display refresh pauses with Home visibility; session tracking is independent
of SpriteKit simulation. AppRootView presents a six-second, cancellable toast
only after a successful Stop, using the completed domain's original day total.

Session history uses a second typed route, Settings → Sessions. AppModel derives
SessionDayGroup values from session.day, sorts original days descending, and
sorts each day's records by start time descending (ID breaks timestamp ties).
SessionsView receives those groups, a name resolver, and a throwing delete
action. Its native List provides day sections, swipe deletion, Edit, and an
empty state. Running rows refresh only the duration text while the app is active.

Each session snapshots its domain name at Start. Rows use the current domain
name while the domain exists and the snapshot after deletion. This required
field changes the development schema; snapshots with earlier timer records need
a reset.
There is no migration path, as agreed.

Deleting sessions removes records in one atomic snapshot, preserving the cursor.
If the unfinished record is removed, derived status becomes waiting on that same
domain; it does not count as completing the domain. Removing completed history
also removes its contribution to later totals. A failed save leaves model state
unchanged and the history screen presents an error. Successful history deletion
clears any stale Home toast. Grouping never uses the last resume/completion day.

Waiting-only manual selection changes the current-domain ID in the existing
atomic snapshot. AppModel.setCurrentDomain validates store availability, rejects
unfinished sessions, validates the target ID, and saves before publishing. It
preserves list order/history and creates no session. Selecting the same current
ID is a no-op; Stop subsequently follows the selected row's successor.

Settings adds a simultaneous long press to domain rows while retaining native
tap-to-edit. It owns the Edit-mode binding: row movement is disabled outside
Edit, and the hold gesture is disabled inside Edit. The root ignores a release
tap while a sheet is already open.
Its action forwards the domain to AppRootView's shared DomainSheetRequest enum
(add/edit/actions), keeping one sheet presenter. DomainActionsSheet has one
Set as current button, dismisses after a successful save, and stays open with
an error after failure. It uses a compact detent, or medium at accessibility
text sizes. The model guard remains authoritative even if a stale UI action
arrives after a session starts. Reordering in Edit mode bypasses the hold gesture.

The empty list selects the first-use card. Its CTA presents DomainEditorView in
a native sheet; the same editor renames existing rows without replacing IDs.
Cancellation leaves storage unchanged and a save error keeps the sheet open.
Settings uses native EditButton, onMove, and onDelete controls, passing stable IDs
to AppModel. The sheet pauses scenery and examples. The view-bound carousel task
advances four examples every five seconds and stops while Home is covered or
inactive. Reduce Motion uses a fade. Card fonts remain fixed. Session controls use forest green; only first-use is outlined.

Debug UI tests select an isolated storage file with a UUID environment token;
they do not delete or seed the person's normal saved-domain file. Reload tests
reuse that token to exercise actual disk persistence across app launches.

`NavigationStack` binds to that path. `NavigationLink(value:)` pushes Settings;
the system Back button and swipe update the same path. Route cases describe
destinations, rather than carrying views, scenes, or entire data models.

`HomeView` receives the scene reference and its pause state explicitly.
`SpriteView` renders the scene beneath native SwiftUI controls. The scene's
simulation pauses when the app is inactive or a destination covers Home.
The view can still draw; this is not a measured rendering-energy optimization.
`MeadowScene` contains only
visual state and displays alternating sky sprites. It does not own
navigation, user interests, notifications, or persistence.

## Ownership and isolation

The model survives Home → Settings → Back while the root keeps its identity.
Its scene is excluded from Observation: SpriteKit manages its drawing, and
node mutations should not drive SwiftUI invalidation. Lazy construction avoids
allocating a scene in each temporary model created during view initialization.
The world is released with its model; it is not a singleton. Process termination
does not preserve it, and there is no navigation restoration yet.

App model and scene mutations are main-actor isolated. The project uses Swift 6
language mode and complete strict-concurrency checking. Future simulation work
must respect SpriteKit's frame callbacks and avoid doing heavy work in UI code.

## Why this shape

SwiftUI owns native interaction and presentation; SpriteKit owns the animated
world. This supports independent creature movement and future visual effects
while keeping app behavior testable separately from rendering. Feature folders
are enough for the shell. There is no generic router, dependency container,
view-model protocol hierarchy, or package boundary without a real consumer need.

Tuist generates the Xcode workspace from a small checked-in Swift manifest.
The tool was already installed locally; the project pins that version and adds
no runtime framework beyond Apple's. Both tests and the app share the same
build settings. The iOS 26 deployment floor is an initial personal-app choice,
not a requirement imposed by SpriteKit or Observation.

## Checks and limits

The day image starts centered horizontally, with night adjacent offscreen.
Full sky images fit the upper half of the scene: height is scene height / 2,
center y is scene height × 0.75, and width preserves the source aspect ratio.
The original composition is proportionally resized to 1584 × 672 for each PNG;
no source cropping or generative edits are applied. Night's fully opaque alpha
channel is removed, and its sRGB rendering intent is retained.

Portrait uses two alternating panels. Wide previews reuse additional pairs with
the same texture references, keeping enough coverage for the viewport plus one
panel. Tiles are allocated/removed only on resize, then recycled as they leave
the viewport. This keeps full image proportions without an offscreen crop mask.
Frame updates advance one shared circuit progress over 60 seconds and translate
all panels left at the same speed. Resizing preserves progress; lifecycle pauses
reset frame timestamps so returning does not catch up. Project.swift explicitly
bundles both textures. The brightness-map generator uses the same half-height
geometry when calculating its representative visible window.

The transparent landscape sits at zPosition 1 above the sky panels. Its height equals scene height, its width keeps the image's aspect
ratio, and its center matches scene center. It is laid out on construction and
resize; frame updates move only the sky. Project.swift bundles the landscape PNG.

The Stick character uses two cached transparent textures at zPosition 3:
`stick-6-transparent.png` for a running session and `stick-1-transparent.png`
while waiting or paused. HomeView derives that presentation from session status
on initial appearance and subsequent changes; the scene owns no session state.
The character's height is 35% of scene height, anchored 32% up from the bottom.
Its texture keeps its aspect ratio on resize. A soft radial-gradient ellipse at
zPosition 2.5 sits below the meditation pose and above the landscape shading.
The shadow texture is generated once per scene and reused; its geometry scales
with the character. The shadow is hidden with the standing pose. There is no
timed pose cycling. Tuist bundles these two character PNGs.

A sprite shades the landscape at zPosition 2. LandscapeShadow draws the
artwork once into a transparent image renderer, then composites a black vertical
gradient using sourceIn. Output alpha is artwork alpha multiplied by gradient
alpha, preserving soft edges and leaving the sky opening clear. The gradient is
opaque at the top and clear at the bottom. The resulting texture is retained
and reused across frame updates and resizing, matching the landscape frame.
The generated sky-illumination.json stores 128 full-height strip averages per
image, using mean encoded RGB channel value normalized to 0...1. During rendering,
32 interpolated samples across the visible horizontal window estimate average
sky brightness, including both images when the view crosses a join. For day,
combine normalized artwork darkness (20%) with distance from day center (80%),
then ease with smoothstep. This spreads the fade across daylight instead of
losing most shade near dawn. Both endpoints have zero slope. Shade is zero at day center,
one at day edges, and always one throughout night, even for bright night clouds.
A flat or reversed daylight contrast falls back to eased positional progress.
It shares the sky clock, including navigation and inactivity pauses. The scene
starts at the day midpoint; resize preserves circuit progress and reevaluates
brightness for the new visible width. No live
crop node or per-frame texture generation is needed; no measured energy claim.

Tests exercise initial layout, aspect ratio, direction, day/night alternation,
repeated wraps without uncovered areas or extra nodes, resize, and pause/resume.
Landscape tests check full-height proportional sizing, centering, draw order,
stationary placement during sky updates, and relayout after resizing.
Shadow tests sample generated texture pixels against the source alpha and
gradient, check transparent areas and top/bottom limits, exercise opacity at
day-center and all-night behavior, and verify texture reuse, layout, and pause
timing. Synthetic illumination fixtures check brighter/darker artwork, seam
averaging, and flat-profile fallback; bundled data checks cover gradual dusk/dawn.
The images meet directly; their edges are not edited or blended. Reduce Motion
support and device energy measurements remain future work.

Swift Testing verifies scene identity across navigation changes, independence
between model instances, and release when its owner is released. XCTest UI
automation exercises the actual Settings push and native Back path twice,
and checks that the central world renders color on launch and return. This
caught a gray first frame when SpriteView was initially created paused on the
tested simulator. The shell instead keeps the view rendering and explicitly
updates `scene.isPaused`. This observation is not a claim about all OS versions.
These do not establish visual quality, energy use, or animation performance.
Lifecycle pause behavior still needs device checks once animation exists.

## Sources

- [Managing model data in your app](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- [Understanding the navigation stack](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack)
- [SpriteView](https://developer.apple.com/documentation/spritekit/spriteview)
- [SKScene](https://developer.apple.com/documentation/spritekit/skscene)
- [Scene resizing](https://developer.apple.com/documentation/spritekit/scaling-a-scene-s-content-to-fit-the-view)
- [Frame updates](https://developer.apple.com/documentation/spritekit/skscene/update(_:))
- [Node draw order](https://developer.apple.com/documentation/spritekit/sknode/zposition)
- [Image renderer](https://developer.apple.com/documentation/uikit/uigraphicsimagerenderer)
- [Source-in compositing](https://developer.apple.com/documentation/coregraphics/cgblendmode)

- [TimelineView animation schedule](https://developer.apple.com/documentation/swiftui/timelineschedule/animation(minimuminterval:paused:))
- [Date intervals](https://developer.apple.com/documentation/foundation/date/timeintervalsince(_:))
- [List deletion](https://developer.apple.com/documentation/swiftui/dynamicviewcontent/ondelete(perform:))

- [Simultaneous gesture](https://developer.apple.com/documentation/swiftui/view/simultaneousgesture(_:isEnabled:))
- [Disable row movement](https://developer.apple.com/documentation/swiftui/view/movedisabled(_:))
- [Sheet detents](https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:))

## Session duration corrections

SessionsView presents SessionDurationEditorView from the trailing duration
button. The sheet keeps a local hours/minutes draft and invokes AppModel only
on Save; failed writes leave the sheet open with its draft. It uses native wheel
pickers with medium/large sheet detents (large at accessibility text sizes).

FocusSession retains an optional durationAdjustment in seconds. Elapsed time is
the nonnegative sum of fragment time and that correction. Saving a new duration
replaces the correction relative to fragment time at the instant of Save;
fragments, original day, completion timestamp, and session status stay intact.
A running fragment continues accumulating afterward. Domain/day totals use the
same elapsed calculation. The JSON decoder accepts existing snapshots without
the optional field. AppModel saves the updated snapshot before publishing state.
Picker edits have minute precision, support zero, and normally offer 0–999 hours;
existing larger hour values remain available. Unedited durations retain seconds.

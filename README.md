# Stick

An iPhone app for making time for several interests through one focus at a time.

## Product scope

- Keep named interests (domains) in a user-defined order.
- Focus on one domain at a time and track active time with Start, Pause,
  Continue, and Stop. Stop completes the domain and selects the next one,
  wrapping around at the end. Multiple domains can be completed in a day.
- Display a pastel nature scene with a twig companion beneath native controls.
- Send one daily reminder (not implemented yet).

## Implemented functionality

- Home screen with a SpriteKit meadow. The character meditates with a soft ground
  shadow during a running session; waiting and paused sessions show stick-1.
  The topic title uses at most two lines and shrinks down to half its base size
  when space is limited.
- An ivory first-use card with rotating examples and an outlined
  “Add your first domain” button. Examples pause while Home is covered or
  inactive; Reduce Motion uses a fade. Card fonts use fixed sizes.
- A native name editor that trims whitespace and saves domains with stable
  string IDs. Cancellation saves nothing; failed saves keep the editor open.
- Start/Continue with a play icon, Pause with a pause icon and current-session
  active time in hours:minutes, and a circular Stop button while running/paused.
  Paused gaps are excluded; elapsed seconds are retained without rounding.
- Sessions persist start/resume fragment timestamps, pause timestamps, and
  completion timestamps. Running sessions continue through Settings, app
  backgrounding, and shutdown, using elapsed wall-clock time on return.
- All fragments belong to the local date of the session's first Start,
  including resumes after midnight. A new Start establishes a new attribution
  date. Totals accumulate per domain and start date, including repeated turns.
- Stop saves the session, advances the cursor, and shows a six-second toast
  with the completed domain's total for its original start date. Pause shows
  no toast. There is no automatic midnight rotation.
- While the current domain is waiting, touch and hold a domain in Settings to
  open a bottom sheet with “Set as current”. Choosing it saves the current
  cursor and keeps the domain in Start state, preserving order and history.
  Running or paused sessions must be stopped before choosing another domain.
  A normal tap still edits the name; Edit supports native delete/reorder.
- Settings preserves user-defined order. Only the current row shows waiting,
  started, or paused. Rename and reorder preserve the active session; Stop
  selects its successor from the latest order. Deleting the current domain
  completes its session and selects the next remaining domain; history remains.
  Deleting all domains restores the first-use card.
- Ordered domains, current domain ID, and session history are stored together
  in one atomic JSON snapshot (`Stick/sessions.json` in Application Support).
  Saving succeeds before the UI changes. Unreadable snapshots block writes.
  This fresh development format does not migrate earlier check-in data;
  previous development files are left unused. Session records now require a
  saved domain name; snapshots containing earlier timer session records need a
  data reset.
- A Sessions row below My domains opens history grouped by original start day,
  newest first. Rows show domain name, start time, active duration, and status,
  including running/paused sessions. Swipe left or use Edit to delete. Removing
  an unfinished session discards its time and resets the same domain to waiting;
  removing history adjusts future totals. Deletion persists across relaunch.
  Sessions retain their original domain name for display after domain deletion;
  existing domains display their current name.
- Tap a duration in Sessions to edit its hours and minutes in a bottom sheet.
  Save updates the session and its totals; Cancel or dismissal saves nothing.
  Started, paused, and completed sessions can be corrected. Running sessions
  continue counting from the saved duration; original timestamps remain intact.
  The picker sets whole minutes and supports durations longer than 24 hours.
- Settings screen with native Back navigation. The visual scene keeps its state
  across navigation and pauses when the app is inactive or Settings covers Home.

The scene displays full day and night sky images in the upper 50% of the screen.
Each image keeps its aspect ratio and fits that region's height; the panorama
scrolls continuously to the left. Both bundled PNGs are 1584 × 672 pixels,
resized from the original composition without cropping. One circuit takes one minute; animation
pauses while Settings covers Home or the app is inactive. The source images
meet directly at their edges, so their artwork determines the visible seam.
A static transparent landscape sits above the sky. It matches the screen height,
keeps its proportions, and is centered horizontally; wide edges are cropped.
A black gradient shades only the landscape's visible pixels, strongest at the
top and clear at the bottom. The scene starts at day center without shade.
Shadow opacity blends measured sky brightness with a gradual daylight curve, reaching
full strength at day end and staying full throughout night. Transparent sky
areas remain unshaded.
Notifications and history export are not implemented yet. Manual system-clock
changes can affect measured time; negative fragment durations are clamped to zero. The synchronous snapshot grows with history;
physical-device performance and energy use have not been measured.

## Architecture

SwiftUI owns app state, controls, and typed navigation. SpriteKit owns the
illustrated world. An observable app model retains one lazily created scene
so view updates and navigation preserve its identity.

The project uses Swift 6 with complete strict-concurrency checking. App model
and scene mutations are main-actor isolated. There are no third-party runtime
dependencies. See [architecture.md](architecture.md) for the code structure,
ownership boundary, and technical limitations.

## Setup

Requires Xcode 26.3, Swift 6, and Tuist 4.191.1 (pinned in `.mise.toml`).
Deployment target: iOS 26.0, iPhone portrait. Bundle identifier:
`com.bparol.domain`. Select your signing team in Xcode to run on an iPhone.

From a fresh checkout, with [mise](https://mise.jdx.dev/) installed:

```sh
mise install
tuist generate --no-open
```

Open `Stick.xcworkspace` and select the Stick scheme.
`Project.swift` is the source of truth; generated Xcode files are ignored.

## Tests

An opt-in `StickAutomation` scheme hosts a live XCTest runner for local MCP
control on Simulator or a signed iPhone. See [device MCP setup](tools/device-mcp/README.md)
for its server configuration, commands, and limitations.

The bundled `Resources/sky-illumination.json` contains 128 average RGB brightness
samples per image. After replacing either sky PNG, regenerate it with Python,
Pillow, and matplotlib installed:

```sh
python3 scripts/map_sky_illumination.py
```

This also updates [the brightness and shadow chart](docs/sky-illumination.svg).
The app loads this data once; Python is not required to build or run the app.

Select an installed simulator from `xcrun simctl list devices available`
and substitute its UUID:

```sh
xcodebuild -workspace Stick.xcworkspace -scheme Stick \
  -destination 'platform=iOS Simulator,id=<SIMULATOR-UUID>' \
  CODE_SIGNING_ALLOWED=NO test
```

Unit tests cover scene ownership, rendering geometry, sky movement, illumination,
and lifecycle timing. Model tests cover session fragments, persisted timestamps,
paused gaps, relaunch, midnight attribution, totals by domain/date, cursor wrapping,
editing/deletion during sessions, history grouping/deletion, and failed writes.
UI tests exercise onboarding,
Start/Pause/Continue/Stop, status labels, stop-only toast, relaunch restoration,
native editing/reordering/deletion, session-history navigation/deletion, and
Home → Settings → Back rendering.

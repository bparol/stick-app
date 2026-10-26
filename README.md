# Stick

An iPhone app for making time for several interests through one daily focus.

## Product scope

- Add interests during onboarding and arrange them in an ordered rotation.
- Reveal one interest on the first opening of a day and keep it stable for
  the rest of that day. Daily use is optional.
- Show today's interest in a card reading “Today you stick to:”.
- Display a pastel, storybook nature scene with a twig companion, moving
  clouds, swaying trees, and occasional butterflies. The logo is a stick.
- Send one daily notification asking whether the user spent time on the topic.

## Implemented functionality

- Home screen with a SpriteKit meadow beneath native SwiftUI controls.
- A daily-focus card with placeholder content.
- Settings screen with native Back navigation.
- The visual scene keeps its state across navigation and pauses its simulation
  when the app is inactive or Settings covers Home.

The scene displays aspect-filled day and night sky images that
scroll continuously to the left. One circuit takes four minutes; animation
pauses while Settings covers Home or the app is inactive. The source images
meet directly at their edges, so their artwork determines the visible seam.
A static transparent landscape sits above the sky. It matches the screen height,
keeps its proportions, and is centered horizontally; wide edges are cropped.
A black gradient shades only the landscape's visible pixels, strongest at the
top and clear at the bottom. The scene starts at day center without shade.
Shadow opacity follows measured sky brightness through dusk and dawn, reaching
full strength at day end and staying full throughout night. Transparent sky
areas remain unshaded.
Interest editing, daily
rotation, persistence, notifications, and check-ins are not implemented.

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
`com.bparol.stick`. Select your signing team in Xcode to run on an iPhone.

From a fresh checkout, with [mise](https://mise.jdx.dev/) installed:

```sh
mise install
tuist generate --no-open
```

Open `Stick.xcworkspace` and select the Stick scheme.
`Project.swift` is the source of truth; generated Xcode files are ignored.

## Tests

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

Unit tests cover scene ownership, identity, release, sky layout, leftward
motion, alternating wraps, resizing, pause/resume timing, and stationary
landscape sizing and layering. The UI test covers
repeated Home → Settings → Back navigation and verifies the world renders
on launch and return.

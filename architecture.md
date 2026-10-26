# Stick architecture

## Current boundary

`StickApp` creates a window containing `AppRootView`. The root stores an
`@Observable`, `@MainActor` `AppModel` in `@State`. The model holds a typed
`[AppRoute]` navigation path and lazily owns one `MeadowScene`.

`NavigationStack` binds to that path. `NavigationLink(value:)` pushes Settings;
the system Back button and swipe update the same path. Route cases describe
destinations, rather than carrying views, scenes, or entire data models.

`HomeView` receives the scene reference and its pause state explicitly.
`SpriteView` renders the scene beneath native SwiftUI controls. The scene's
simulation pauses when the app is inactive or a destination covers Home.
The view can still draw; this is not a measured rendering-energy optimization.
`MeadowScene` contains only
visual state and displays two alternating sky sprites. It does not own
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

The day image starts centered in the viewport, with night adjacent offscreen.
Each image scales uniformly by the larger of the horizontal and vertical fill
ratios, with vertical centering. Each keeps its own proportional width, so the
layout also supports differently sized artwork. Frame updates advance one shared circuit progress
over 240 seconds and translate both panels left at the same speed. Panels recycle
outside the viewport; centered presentation also wraps the preceding panel to
the left when needed at the circuit seam. Resizing
preserves circuit progress; pausing resets the timestamp used to compute the
next frame's elapsed time. Sky textures are bundled explicitly by Project.swift.

The transparent landscape is a third sprite at zPosition 1 above the two sky
panels. Its height equals scene height, its width keeps the image's aspect
ratio, and its center matches scene center. It is laid out on construction and
resize; frame updates move only the sky. Project.swift bundles the landscape PNG.

A fourth sprite shades the landscape at zPosition 2. LandscapeShadow draws the
artwork once into a transparent image renderer, then composites a black vertical
gradient using sourceIn. Output alpha is artwork alpha multiplied by gradient
alpha, preserving soft edges and leaving the sky opening clear. The gradient is
opaque at the top and clear at the bottom. The resulting texture is retained
and reused across frame updates and resizing, matching the landscape frame.
The generated sky-illumination.json stores 128 full-height strip averages per
image, using mean encoded RGB channel value normalized to 0...1. During rendering,
32 interpolated samples across the visible horizontal window estimate average
sky brightness, including both images when the view crosses a join. For day,
normalize brightness between day center and the corresponding dawn/dusk edge,
clamp to 0...1, then ease the value with smoothstep. Shade is zero at day center,
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

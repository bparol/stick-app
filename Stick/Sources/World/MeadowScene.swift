import SpriteKit
import UIKit

/// Two aspect-filled sky panels move left and alternate without allocating new nodes.
@MainActor
final class MeadowScene: SKScene {
    let appearance = SkyAppearance()
    // About two minutes per image; one complete day/night circuit takes four minutes.
    let cycleDuration: TimeInterval = 240
    private let day = SKSpriteNode(imageNamed: "sky-day.png")
    private let night = SKSpriteNode(imageNamed: "sky-night.png")
    private let landscape = SKSpriteNode(imageNamed: "landscape-transparent.png")
    private let shadow = SKSpriteNode()
    private let illumination: SkyIllumination = {
        do { return try .load() }
        catch { preconditionFailure("Missing or invalid sky illumination map: \(error)") }
    }()
    private var progress: Double?
    private var previousUpdateTime: TimeInterval?

    override var isPaused: Bool {
        didSet {
            // Frame timestamps keep advancing while navigation or app activity pauses us.
            // Rebase the clock so returning to Home does not jump ahead.
            previousUpdateTime = nil
        }
    }

    override init() {
        super.init(size: CGSize(width: 390, height: 844))
        scaleMode = .resizeFill
        backgroundColor = .black
        for (name, sprite) in [("sky-day", day), ("sky-night", night)] {
            sprite.name = name
            sprite.anchorPoint = CGPoint(x: 0, y: 0.5)
            addChild(sprite)
        }
        landscape.name = "landscape"
        landscape.zPosition = 1
        addChild(landscape)
        if let artwork = UIImage(named: "landscape-transparent.png") {
            shadow.texture = SKTexture(image: LandscapeShadow.image(maskedBy: artwork))
        }
        shadow.name = "landscape-shadow"
        shadow.zPosition = 2
        addChild(shadow)
        layoutSky()
    }

    required init?(coder: NSCoder) {
        // This scene is built in code; no .sks archive is used.
        return nil
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutSky()
    }

    override func update(_ currentTime: TimeInterval) {
        defer { previousUpdateTime = currentTime }
        guard let previousUpdateTime, let progress, !isPaused else { return }
        let elapsed = max(0, currentTime - previousUpdateTime)
        self.progress = (progress + elapsed * Double(speed) / cycleDuration)
            .truncatingRemainder(dividingBy: 1)
        positionSky()
    }

    private func layoutLandscape() {
        guard let imageSize = landscape.texture?.size(), imageSize.height > 0 else { return }
        landscape.size = CGSize(
            width: size.height * imageSize.width / imageSize.height,
            height: size.height
        )
        landscape.position = CGPoint(x: size.width / 2, y: size.height / 2)
        shadow.size = landscape.size
        shadow.position = landscape.position
    }

    private func layoutSky() {
        guard size.width > 0, size.height > 0 else { return }
        for sprite in [day, night] {
            guard let imageSize = sprite.texture?.size(),
                  imageSize.width > 0, imageSize.height > 0 else { continue }
            let scale = max(size.width / imageSize.width, size.height / imageSize.height)
            sprite.size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        }
        if progress == nil {
            progress = Double(day.size.width / (2 * (day.size.width + night.size.width)))
        }
        positionSky()
        layoutLandscape()
    }

    private func positionSky() {
        let circuitWidth = day.size.width + night.size.width
        let phase = progress ?? 0
        let offset = CGFloat(phase) * circuitWidth
        shadow.alpha = CGFloat(illumination.shadowAlpha(
            at: phase, dayFraction: Double(day.size.width / circuitWidth),
            visibleFraction: Double(size.width / circuitWidth)
        ))
        let darkness = illumination.headerDarkness(
            at: phase, dayFraction: Double(day.size.width / circuitWidth),
            visibleFraction: Double(size.width / circuitWidth)
        )
        if appearance.darkness != darkness {
            appearance.darkness = darkness
        }
        for (sprite, start) in [(day, CGFloat.zero), (night, day.size.width)] {
            var x = size.width / 2 + start - offset
            // Recycle only after the panel's right edge clears the viewport.
            if x + sprite.size.width <= 0 {
                x += circuitWidth
            } else if x >= size.width {
                // Centered startup can place the preceding panel off to the
                // right at the circuit seam. Keep it ready on the left instead.
                x -= circuitWidth
            }
            sprite.position = CGPoint(x: x, y: size.height / 2)
        }
    }
}

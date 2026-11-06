import SpriteKit
import UIKit

/// Full sky images move left in the upper half, sharing textures across recycled panels.
@MainActor
final class MeadowScene: SKScene {
    let appearance = SkyAppearance()
    // One complete day/night circuit takes one minute.
    let cycleDuration: TimeInterval = 120
    private let day = SKSpriteNode(imageNamed: "sky-day.png")
    private let night = SKSpriteNode(imageNamed: "sky-night.png")
    // Portrait uses the original pair; wide previews can need additional tiles.
    private var extraSkies: [SKSpriteNode] = []
    private var skyPanels: [SKSpriteNode] { [day, night] + extraSkies }
    private let landscape = SKSpriteNode(imageNamed: "landscape-transparent.png")
    private let shadow = SKSpriteNode()
    static let characterImageNames = (1...9).map { "stick-\($0)-transparent.png" }
    private let character = SKSpriteNode(imageNamed: characterImageNames[0])
    private var characterElapsed: TimeInterval = 0
    private var characterIndex = 0
    private let characterInterval: TimeInterval = 10
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
        character.name = "stick-character"
        character.zPosition = 3
        character.anchorPoint = CGPoint(x: 0.5, y: 0)
        addChild(character)
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
        advanceCharacter(by: elapsed * max(0, Double(speed)))
    }

    private func advanceCharacter(by elapsed: TimeInterval) {
        characterElapsed += elapsed
        let steps = Int(characterElapsed / characterInterval)
        guard steps > 0 else { return }
        characterElapsed.formTruncatingRemainder(dividingBy: characterInterval)
        characterIndex = (characterIndex + steps % Self.characterImageNames.count)
            % Self.characterImageNames.count
        character.texture = SKTexture(imageNamed: Self.characterImageNames[characterIndex])
        layoutCharacter()
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

    private func layoutCharacter() {
        guard let imageSize = character.texture?.size(), imageSize.height > 0 else { return }
        // Match the reference's character height and foot position on the path.
        let height = size.height * 0.35
        character.size = CGSize(width: height * imageSize.width / imageSize.height, height: height)
        character.position = CGPoint(x: size.width / 2, y: size.height * 0.32)
    }

    private func layoutSky() {
        guard size.width > 0, size.height > 0 else { return }
        for sprite in [day, night] {
            guard let imageSize = sprite.texture?.size(),
                  imageSize.width > 0, imageSize.height > 0 else { continue }
            let skyHeight = size.height / 2
            sprite.size = CGSize(width: skyHeight * imageSize.width / imageSize.height, height: skyHeight)
        }
        // Keep full image proportions even when a preview is wider than a panel.
        // Extra tiles share the two existing textures and are allocated only on resize.
        let circuitWidth = day.size.width + night.size.width
        let pairs = max(1, Int(ceil((size.width + max(day.size.width, night.size.width)) / circuitWidth)))
        let extraCount = (pairs - 1) * 2
        while extraSkies.count > extraCount { extraSkies.removeLast().removeFromParent() }
        while extraSkies.count < extraCount {
            let index = extraSkies.count
            let source = index.isMultiple(of: 2) ? day : night
            let panel = SKSpriteNode(texture: source.texture)
            panel.name = "sky-extra-\(index)"
            panel.anchorPoint = source.anchorPoint
            extraSkies.append(panel)
            addChild(panel)
        }
        for (index, panel) in extraSkies.enumerated() {
            panel.size = (index.isMultiple(of: 2) ? day : night).size
        }
        if progress == nil {
            progress = Double(day.size.width / (2 * (day.size.width + night.size.width)))
        }
        positionSky()
        layoutLandscape()
        layoutCharacter()
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
        let poolWidth = CGFloat(1 + extraSkies.count / 2) * circuitWidth
        var start = CGFloat.zero
        for sprite in skyPanels {
            var x = size.width / 2 + start - offset
            // Recycle only after the panel's right edge clears the viewport.
            if x + sprite.size.width <= 0 {
                x += poolWidth
            } else if x >= size.width {
                // Centered startup can place the preceding panel off to the
                // right at the circuit seam. Keep it ready on the left instead.
                x -= poolWidth
            }
            sprite.position = CGPoint(x: x, y: size.height * 0.75)
            start += sprite.size.width
        }
    }
}

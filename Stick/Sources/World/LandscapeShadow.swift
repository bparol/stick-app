import UIKit

/// Bake the artwork's alpha into a black top-to-bottom gradient once.
@MainActor
enum LandscapeShadow {
    static func image(maskedBy artwork: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = artwork.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: artwork.size, format: format)
        return renderer.image { output in
            let bounds = CGRect(origin: .zero, size: artwork.size)
            artwork.draw(in: bounds)
            // sourceIn keeps gradient alpha multiplied by the artwork's alpha,
            // including soft edges; completely transparent sky stays untouched.
            output.cgContext.setBlendMode(.sourceIn)
            let colors = [UIColor.black.cgColor, UIColor.black.withAlphaComponent(0).cgColor]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray, locations: [0, 1]
            )!
            output.cgContext.drawLinearGradient(
                gradient, start: .zero,
                end: CGPoint(x: 0, y: artwork.size.height), options: []
            )
        }
    }
}

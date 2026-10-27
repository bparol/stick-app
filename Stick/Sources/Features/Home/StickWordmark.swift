import SwiftUI

/// Native lettering and vector artwork based on Resources/base_design.jpeg.
struct StickWordmark: View {
    var tint = HomeHeaderTint(darkness: 0).wordmark
    @ScaledMetric(relativeTo: .largeTitle) private var letterSize = 38
    @ScaledMetric(relativeTo: .largeTitle) private var twigHeight = 36

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("stick")
                .font(.system(size: letterSize, weight: .regular, design: .rounded))
                .foregroundStyle(tint)
            TwigMark()
                .frame(width: twigHeight * 0.55, height: twigHeight)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stick")
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("stick-wordmark")
    }
}

private struct TwigMark: View {
    private let outline = Color(red: 0.31, green: 0.30, blue: 0.19)

    var body: some View {
        GeometryReader { geometry in
            let scale = CGAffineTransform(scaleX: geometry.size.width / 22, y: geometry.size.height / 40)

            // A leaning stem with a short side branch; all coordinates share
            // one design space so the outline and leaf scale together.
            let stem = Path { path in
                path.move(to: CGPoint(x: 6, y: 38))
                path.addLine(to: CGPoint(x: 12.5, y: 3))
                path.addQuadCurve(to: CGPoint(x: 17, y: 4), control: CGPoint(x: 16, y: 0))
                path.addLine(to: CGPoint(x: 13.8, y: 19))
                path.addLine(to: CGPoint(x: 19.5, y: 16))
                path.addQuadCurve(to: CGPoint(x: 21, y: 19), control: CGPoint(x: 22, y: 16))
                path.addLine(to: CGPoint(x: 13, y: 23))
                path.addLine(to: CGPoint(x: 10.5, y: 39))
                path.closeSubpath()
            }.applying(scale)

            let leaf = Path { path in
                path.move(to: CGPoint(x: 11, y: 15))
                path.addCurve(
                    to: CGPoint(x: 5, y: 4),
                    control1: CGPoint(x: 3, y: 15), control2: CGPoint(x: 3, y: 8)
                )
                path.addCurve(
                    to: CGPoint(x: 11, y: 15),
                    control1: CGPoint(x: 12, y: 5), control2: CGPoint(x: 12, y: 10)
                )
                path.closeSubpath()
            }.applying(scale)

            stem
                .fill(Color(red: 0.66, green: 0.56, blue: 0.36))
                .overlay {
                    stem.stroke(outline, style: StrokeStyle(lineWidth: geometry.size.height * 0.045, lineJoin: .round))
                }
            leaf
                .fill(Color(red: 0.55, green: 0.65, blue: 0.30))
                .overlay {
                    leaf.stroke(outline, style: StrokeStyle(lineWidth: geometry.size.height * 0.035, lineJoin: .round))
                }
            Path { path in
                path.move(to: CGPoint(x: 7, y: 8))
                path.addQuadCurve(to: CGPoint(x: 11, y: 16), control: CGPoint(x: 10, y: 12))
            }
            .applying(scale)
            .stroke(outline, style: StrokeStyle(lineWidth: geometry.size.height * 0.025, lineCap: .round))
        }
    }
}

#Preview {
    StickWordmark().padding()
}

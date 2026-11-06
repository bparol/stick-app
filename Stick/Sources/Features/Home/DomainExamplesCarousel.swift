import SwiftUI

struct DomainExamplesCarousel: View {
    let isActive: Bool

    private let examples = ["Photography", "Guitar", "Drawing", "Reading"]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    var body: some View {
        ZStack {
            Text(examples[index])
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .tracking(-0.5)
                .frame(maxWidth: .infinity)
                .id(index)
                .transition(reduceMotion ? .opacity : .asymmetric(
                    insertion: .move(edge: .trailing), removal: .move(edge: .leading)
                ))
        }
        .frame(height: 56)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Example: \(examples[index])")
        .accessibilityIdentifier("domain-example")
        .task(id: isActive) {
            guard isActive else { return }
            do {
                while true {
                    try await Task.sleep(for: .seconds(5))
                    try Task.checkCancellation()
                    withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.6)) {
                        index = (index + 1) % examples.count
                    }
                }
            } catch is CancellationError {
                // Home disappeared, became inactive, or is covered by an editor.
            } catch { }
        }
    }
}

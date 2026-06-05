import SwiftUI

struct LiveValueBadgeModifier: ViewModifier {
    let trigger: Data?

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.06 : 1.0)
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(.easeOut(duration: 0.25), value: isPulsing)
            .onChange(of: trigger) { _, _ in
                isPulsing = true
                Task {
                    try? await Task.sleep(for: .milliseconds(250))
                    isPulsing = false
                }
            }
    }
}

extension View {
    func liveValueBadge(trigger: Data?) -> some View {
        modifier(LiveValueBadgeModifier(trigger: trigger))
    }
}

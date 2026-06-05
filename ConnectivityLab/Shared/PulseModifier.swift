import SwiftUI

struct PulseModifier: ViewModifier {
    let active: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(active ? (isPulsing ? 0.4 : 1.0) : 1.0)
            .scaleEffect(active ? (isPulsing ? 0.97 : 1.0) : 1.0)
            .animation(
                active ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear {
                if active { isPulsing = true }
            }
            .onChange(of: active) { _, isNowActive in
                isPulsing = isNowActive
            }
    }
}

extension View {
    func pulse(active: Bool) -> some View {
        modifier(PulseModifier(active: active))
    }
}

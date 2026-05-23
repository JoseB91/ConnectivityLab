import SwiftUI

struct WiFiStatusView: View {
    @Bindable var pinger: WiFiPinger

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Host:")
                    .foregroundStyle(.secondary)
                TextField("192.168.1.1", text: $pinger.host)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal)

            Button("Ping") {
                Task { try? await pinger.connect() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(pinger.isPinging || pinger.host.isEmpty)

            if pinger.isPinging {
                ProgressView("Pinging…")
            } else if let ms = pinger.latencyMs {
                Label(String(format: "%.1f ms", ms), systemImage: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            } else if let error = pinger.errorMessage {
                Label(error, systemImage: "xmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 24)
    }
}

import SwiftUI

struct StatusHeaderView: View {
    @ObservedObject var session: SessionManager

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.statusTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(session.statusDetail)
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(session.isActive ? Color.green : Color.secondary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: session.statusDetail)
            }
            Spacer(minLength: 12)
            Toggle("", isOn: Binding(
                get: { session.isActive },
                set: { _ in session.toggleIndefinite() }
            ))
            .toggleStyle(GreenSwitchStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(width: 270, alignment: .leading)
    }
}

struct GreenSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: configuration.isOn ? .trailing : .leading) {
            Capsule()
                .fill(configuration.isOn ? Color.green : Color.gray.opacity(0.35))
            Circle()
                .fill(.white)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                .padding(2)
        }
        .frame(width: 38, height: 22)
        .contentShape(Capsule())
        .onTapGesture { configuration.isOn.toggle() }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isOn)
    }
}

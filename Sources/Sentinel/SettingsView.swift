import AppKit
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var tab: SettingsTab = .general
    @Namespace private var tabNamespace

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(SettingsTab.allCases) { item in
                    TabButton(tab: item, isSelected: tab == item, namespace: tabNamespace) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { tab = item }
                    }
                }
            }
            .padding(3)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.bar)

            Divider()

            Group {
                switch tab {
                case .general: GeneralSettings()
                case .automatic: TriggerSettings()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 520, height: 540)
    }
}

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case automatic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "Geral"
        case .automatic: "Automático"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape.fill"
        case .automatic: "bolt.fill"
        }
    }
}

private struct TabButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(isHovering ? 1 : 0.8))
            .padding(.horizontal, 16)
            .frame(height: 28)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(0.12))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                        .matchedGeometryEffect(id: "tabHighlight", in: namespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

private struct SettingIcon: View {
    let symbol: String
    let color: Color

    static let sentinelEye = "sentinel.eye"

    var body: some View {
        glyph
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(color.gradient)
            )
    }

    @ViewBuilder
    private var glyph: some View {
        if symbol == Self.sentinelEye {
            Image(nsImage: SentinelGlyph.image(open: true, size: 18))
                .renderingMode(.template)
                .resizable()
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
        }
    }
}

private struct SettingLabel: View {
    let symbol: String
    let color: Color
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(spacing: 10) {
            SettingIcon(symbol: symbol, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

private struct GeneralSettings: View {
    @EnvironmentObject private var preferences: Preferences
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Inicialização") {
                Toggle(isOn: $launchAtLogin) {
                    SettingLabel(
                        symbol: "power",
                        color: .gray,
                        title: "Abrir junto com o Mac",
                        subtitle: "O Sentinel inicia sozinho quando você faz login."
                    )
                }
                .onChange(of: launchAtLogin) { _, enabled in updateLoginItem(enabled) }
                if let loginError {
                    Text(loginError).font(.caption).foregroundStyle(.red)
                }
                Toggle(isOn: $preferences.startSessionAtLaunch) {
                    SettingLabel(
                        symbol: SettingIcon.sentinelEye,
                        color: .green,
                        title: "Manter acordado ao abrir",
                        subtitle: "Ativa o Sentinel assim que o app é aberto."
                    )
                }
            }

            Section("Tela") {
                Toggle(isOn: $preferences.allowDisplaySleep) {
                    SettingLabel(
                        symbol: "display",
                        color: .blue,
                        title: "Deixar a tela apagar",
                        subtitle: "O Mac continua acordado, mas a tela pode desligar."
                    )
                }
            }

            Section("Bateria") {
                Toggle(isOn: $preferences.batteryGuardEnabled) {
                    SettingLabel(
                        symbol: "battery.25percent",
                        color: .orange,
                        title: "Proteger a bateria",
                        subtitle: "Deixa o Mac dormir quando a bateria ficar baixa."
                    )
                }
                Picker(selection: $preferences.batteryThreshold) {
                    ForEach(Array(stride(from: 5, through: 50, by: 5)), id: \.self) { value in
                        Text("\(value)%").tag(value)
                    }
                } label: {
                    Text("Limite de bateria")
                        .padding(.leading, 36)
                }
                .disabled(!preferences.batteryGuardEnabled)
            }
        }
        .formStyle(.grouped)
    }

    private func updateLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = "Não foi possível alterar: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

private struct TriggerSettings: View {
    @EnvironmentObject private var preferences: Preferences

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $preferences.triggersEnabled) {
                    SettingLabel(
                        symbol: "bolt.fill",
                        color: .yellow,
                        title: "Acordar automaticamente",
                        subtitle: "Mantém o Mac acordado enquanto alguma condição abaixo for verdadeira."
                    )
                }
            }

            Section("Quando") {
                Toggle(isOn: $preferences.triggerOnExternalPower) {
                    SettingLabel(symbol: "powerplug.fill", color: .green, title: "O Mac estiver na tomada")
                }
                Toggle(isOn: $preferences.triggerOnExternalDisplay) {
                    SettingLabel(symbol: "display.2", color: .blue, title: "Um monitor externo estiver conectado")
                }
            }

            Section {
                if preferences.triggerApps.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: "app.dashed")
                                .font(.system(size: 22))
                                .foregroundStyle(.tertiary)
                            Text("Nenhum app adicionado")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        Spacer()
                    }
                } else {
                    ForEach(preferences.triggerApps) { app in
                        HStack(spacing: 10) {
                            AppIconView(bundleID: app.bundleID)
                            Text(app.name)
                            Spacer()
                            Button {
                                preferences.triggerApps.removeAll { $0.id == app.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Remover \(app.name)")
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Algum destes apps estiver aberto")
                    Spacer()
                    Button(action: addApps) {
                        Label("Adicionar", systemImage: "plus")
                    }
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func addApps() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            guard
                let bundleID = Bundle(url: url)?.bundleIdentifier,
                !preferences.triggerApps.contains(where: { $0.bundleID == bundleID })
            else { continue }
            let name = url.deletingPathExtension().lastPathComponent
            preferences.triggerApps.append(WatchedApp(bundleID: bundleID, name: name))
        }
    }
}

private struct AppIconView: View {
    let bundleID: String

    var body: some View {
        Group {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 24, height: 24)
    }
}

import SwiftUI

@main
struct VigilantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private var session: SessionManager?
    private var statusBar: StatusBarController?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let session = SessionManager(preferences: preferences)
        self.session = session
        statusBar = StatusBarController(session: session, preferences: preferences) { [weak self] in
            self?.showSettings()
        }
    }

    private func showSettings() {
        if settingsWindow == nil {
            let controller = NSHostingController(rootView: SettingsView().environmentObject(preferences))
            controller.sizingOptions = []
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: Self.settingsSize),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.contentViewController = controller
            window.setContentSize(Self.settingsSize)
            window.title = "Ajustes do Vigilant"
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        guard let window = settingsWindow else { return }
        let wasVisible = window.isVisible
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        if !wasVisible {
            centerOnScreen(window)
        }
    }

    private static let settingsSize = NSSize(width: 520, height: 540)

    private func centerOnScreen(_ window: NSWindow) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else {
            window.center()
            return
        }
        let size = window.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        )
        window.setFrameOrigin(origin)
    }
}

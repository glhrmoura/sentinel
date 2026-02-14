import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let session: SessionManager
    private let preferences: Preferences
    private let openSettings: () -> Void
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let headerItem = NSMenuItem()
    private lazy var primaryItem = ActionMenuItem(title: "", keyEquivalent: "") { [weak self] in
        guard let self else { return }
        self.session.isActive ? self.session.end() : self.session.startIndefinite()
    }
    private var cancellables = Set<AnyCancellable>()

    private let durations: [(String, Int)] = [
        ("5 minutos", 5),
        ("15 minutos", 15),
        ("30 minutos", 30),
        ("1 hora", 60),
        ("2 horas", 120),
        ("4 horas", 240),
        ("8 horas", 480)
    ]

    init(session: SessionManager, preferences: Preferences, openSettings: @escaping () -> Void) {
        self.session = session
        self.preferences = preferences
        self.openSettings = openSettings
        super.init()

        let header = NSHostingView(rootView: StatusHeaderView(session: session))
        header.frame = NSRect(origin: .zero, size: header.fittingSize)
        headerItem.view = header

        menu.delegate = self
        menu.autoenablesItems = false

        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        session.$session.combineLatest(session.$activeTrigger)
            .map { current, trigger in current != nil || trigger != nil }
            .removeDuplicates()
            .sink { [weak self] active in self?.render(active: active) }
            .store(in: &cancellables)
    }

    private func render(active: Bool) {
        let image = VigilantGlyph.image(open: active, size: 18)
        image.accessibilityDescription = "Vigilant"
        statusItem.button?.image = image
        primaryItem.title = active ? "Deixar o Mac dormir" : "Manter acordado"
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isSecondary = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        if isSecondary {
            session.toggleIndefinite()
            return
        }
        statusItem.menu = menu
        sender.performClick(nil)
        statusItem.menu = nil
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(headerItem)
        menu.addItem(.separator())

        menu.addItem(primaryItem)

        menu.addItem(submenu("Manter acordado por…", items: durations.map { label, minutes in
            action(label) { [session] in session.start(minutes: minutes) }
        }))

        menu.addItem(submenu("Manter acordado até…", items: untilOptions().map { date in
            action(date.formatted(date: .omitted, time: .shortened)) { [session] in session.start(until: date) }
        }))

        let apps = SystemState.runningApps()
        let appItems = apps.isEmpty
            ? [disabled("Nenhum app aberto")]
            : apps.map { app in action(app.name) { [session] in session.start(whileRunning: app) } }
        menu.addItem(submenu("Manter acordado enquanto…", items: appItems))

        menu.addItem(.separator())
        menu.addItem(action("Ajustes") { [openSettings] in openSettings() })
        menu.addItem(action("Sair do Vigilant", key: "q") { NSApp.terminate(nil) })
    }

    private func action(_ title: String, key: String = "", handler: @escaping () -> Void) -> NSMenuItem {
        ActionMenuItem(title: title, keyEquivalent: key, handler: handler)
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func submenu(_ title: String, items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: title)
        submenu.autoenablesItems = false
        items.forEach(submenu.addItem)
        item.submenu = submenu
        return item
    }

    private func untilOptions() -> [Date] {
        let step: TimeInterval = 30 * 60
        let earliest = Date().addingTimeInterval(15 * 60).timeIntervalSinceReferenceDate
        let start = Date(timeIntervalSinceReferenceDate: (earliest / step).rounded(.up) * step)
        return (0..<8).map { start.addingTimeInterval(TimeInterval($0) * step) }
    }
}

final class ActionMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, keyEquivalent: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: keyEquivalent)
        target = self
    }

    required init(coder: NSCoder) {
        fatalError()
    }

    @objc private func run() {
        handler()
    }
}

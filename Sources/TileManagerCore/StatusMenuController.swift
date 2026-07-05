import AppKit
import Foundation

public final class StatusMenuController: NSObject {
    public var onToggleEnabled: ((Bool) -> Void)?
    public var onRequestAccessibility: (() -> Void)?
    public var onOpenAccessibilitySettings: (() -> Void)?
    public var onToggleLaunchAtLogin: ((Bool) -> Void)?
    public var onSelectTilingMode: ((TilingMode) -> Void)?

    private let settings: AppSettings
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var isEventTapRunning = false

    public init(settings: AppSettings) {
        self.settings = settings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
        rebuildMenu(eventTapRunning: false)
    }

    public func rebuildMenu(eventTapRunning: Bool) {
        isEventTapRunning = eventTapRunning
        menu.removeAllItems()

        let enabledItem = NSMenuItem(
            title: "Enabled",
            action: #selector(toggleEnabled(_:)),
            keyEquivalent: ""
        )
        enabledItem.target = self
        enabledItem.state = settings.enabled ? .on : .off
        menu.addItem(enabledItem)

        for mode in TilingMode.allCases {
            let modeItem = NSMenuItem(
                title: mode.title,
                action: #selector(selectTilingMode(_:)),
                keyEquivalent: ""
            )
            modeItem.target = self
            modeItem.representedObject = mode.rawValue
            modeItem.state = settings.tilingMode == mode ? .on : .off
            menu.addItem(modeItem)
        }

        menu.addItem(.separator())

        let eventTapTitle = isEventTapRunning ? "Event Tap: Running" : "Event Tap: Stopped"
        let eventTapItem = NSMenuItem(title: eventTapTitle, action: nil, keyEquivalent: "")
        eventTapItem.isEnabled = false
        menu.addItem(eventTapItem)

        let accessibilityTitle = AccessibilityClient.isTrusted
            ? "Accessibility: Granted"
            : "Accessibility: Missing"
        let accessibilityItem = NSMenuItem(title: accessibilityTitle, action: nil, keyEquivalent: "")
        accessibilityItem.isEnabled = false
        menu.addItem(accessibilityItem)

        if !AccessibilityClient.isTrusted {
            let requestItem = NSMenuItem(
                title: "Request Accessibility Permission",
                action: #selector(requestAccessibility(_:)),
                keyEquivalent: ""
            )
            requestItem.target = self
            menu.addItem(requestItem)
        }

        let settingsItem = NSMenuItem(
            title: "Open Accessibility Settings",
            action: #selector(openAccessibilitySettings(_:)),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login: \(LoginItemManager.statusDescription)",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit TileManager",
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    public func presentError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "TileManager"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        if let image = NSImage(
            systemSymbolName: "rectangle.split.2x1",
            accessibilityDescription: "TileManager"
        ) {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "Tile"
        }

        statusItem.menu = menu
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        let newValue = !settings.enabled
        settings.enabled = newValue
        onToggleEnabled?(newValue)
    }

    @objc private func requestAccessibility(_ sender: NSMenuItem) {
        onRequestAccessibility?()
    }

    @objc private func openAccessibilitySettings(_ sender: NSMenuItem) {
        onOpenAccessibilitySettings?()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        onToggleLaunchAtLogin?(!LoginItemManager.isEnabled)
    }

    @objc private func selectTilingMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = TilingMode(rawValue: rawValue) else {
            return
        }

        settings.tilingMode = mode
        onSelectTilingMode?(mode)
        rebuildMenu(eventTapRunning: isEventTapRunning)
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}

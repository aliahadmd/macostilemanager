import AppKit
import ApplicationServices
import Foundation

public final class TileManagerController {
    private let settings: AppSettings
    private let eventTap: MouseEventTap
    private let tiler: WindowTiler
    private let hitTester: TitleBarHitTester
    private let menuController: StatusMenuController
    private var permissionRefreshTimer: Timer?
    private var reportedEventTapStartFailure = false
    private var pendingTarget: PendingDoubleClickTarget?

    public init(
        settings: AppSettings = AppSettings(),
        eventTap: MouseEventTap = MouseEventTap(),
        tiler: WindowTiler = WindowTiler(),
        hitTester: TitleBarHitTester = TitleBarHitTester()
    ) {
        self.settings = settings
        self.eventTap = eventTap
        self.tiler = tiler
        self.hitTester = hitTester
        self.menuController = StatusMenuController(settings: settings)

        configureCallbacks()
    }

    public func start() {
        TileManagerLog.info("TileManager starting; accessibilityTrusted=\(AccessibilityClient.isTrusted)")
        refreshEventTap()

        if !AccessibilityClient.isTrusted {
            AccessibilityClient.requestTrustPrompt()
        }

        permissionRefreshTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshEventTap()
        }
    }

    public func stop() {
        permissionRefreshTimer?.invalidate()
        permissionRefreshTimer = nil
        eventTap.stop()
    }

    private func configureCallbacks() {
        eventTap.onLeftMouseDown = { [weak self] point, clickState in
            self?.handleLeftMouseDown(at: point, clickState: clickState) ?? false
        }

        menuController.onToggleEnabled = { [weak self] _ in
            self?.refreshEventTap()
        }

        menuController.onRequestAccessibility = { [weak self] in
            AccessibilityClient.requestTrustPrompt()
            self?.refreshEventTap()
        }

        menuController.onOpenAccessibilitySettings = {
            AccessibilityClient.openAccessibilitySettings()
        }

        menuController.onToggleLaunchAtLogin = { [weak self] enabled in
            do {
                try LoginItemManager.setEnabled(enabled)
                self?.settings.launchAtLogin = enabled
            } catch {
                self?.settings.launchAtLogin = LoginItemManager.isEnabled
                self?.menuController.presentError(error.localizedDescription)
            }
            self?.menuController.rebuildMenu(eventTapRunning: self?.eventTap.isRunning ?? false)
        }
    }

    private func refreshEventTap() {
        guard settings.enabled, AccessibilityClient.isTrusted else {
            eventTap.stop()
            reportedEventTapStartFailure = false
            menuController.rebuildMenu(eventTapRunning: false)
            return
        }

        let started = eventTap.start()
        if started {
            reportedEventTapStartFailure = false
            TileManagerLog.info("Event tap refresh succeeded")
        } else if !reportedEventTapStartFailure {
            reportedEventTapStartFailure = true
            TileManagerLog.error("Event tap refresh failed")
            menuController.presentError(
                "TileManager could not start its mouse event tap. Confirm Accessibility permission, then relaunch the app."
            )
        }
        menuController.rebuildMenu(eventTapRunning: started && eventTap.isRunning)
    }

    private func handleLeftMouseDown(at point: CGPoint, clickState: Int64) -> Bool {
        guard settings.enabled, AccessibilityClient.isTrusted else {
            pendingTarget = nil
            return false
        }

        if clickState >= 2, let target = pendingTarget, target.matches(point: point) {
            pendingTarget = nil
            TileManagerLog.info("Consuming double-click and tiling cached window")
            DispatchQueue.main.async { [weak self] in
                _ = self?.tiler.tile(window: target.window, clickPoint: point)
            }
            return true
        }

        pendingTarget = targetForClick(at: point).map {
            TileManagerLog.info("Primed title-bar click target")
            return PendingDoubleClickTarget(window: $0, point: point, timestamp: CFAbsoluteTimeGetCurrent())
        }
        return false
    }

    private func targetForClick(at point: CGPoint) -> AXUIElement? {
        guard let hitElement = AccessibilityClient.element(at: point),
              let window = hitTester.targetWindow(for: hitElement, at: point) else {
            return nil
        }
        return window
    }
}

private struct PendingDoubleClickTarget {
    let window: AXUIElement
    let point: CGPoint
    let timestamp: CFAbsoluteTime

    func matches(point newPoint: CGPoint) -> Bool {
        let now = CFAbsoluteTimeGetCurrent()
        guard now - timestamp <= 0.8 else {
            return false
        }

        let dx = abs(point.x - newPoint.x)
        let dy = abs(point.y - newPoint.y)
        return dx <= 12 && dy <= 12
    }
}

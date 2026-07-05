import ApplicationServices
import CoreGraphics
import Foundation

public struct TitleBarHitTester {
    public var fallbackTitleBarHeight: CGFloat

    private let interactiveRoles: Set<String> = [
        AXNames.roleButton,
        AXNames.roleCheckBox,
        AXNames.roleComboBox,
        AXNames.roleIncrementor,
        AXNames.roleLink,
        AXNames.roleMenu,
        AXNames.roleMenuButton,
        AXNames.roleMenuItem,
        AXNames.rolePopUpButton,
        AXNames.roleRadioButton,
        AXNames.roleScrollBar,
        AXNames.roleSearchField,
        AXNames.roleSlider,
        AXNames.roleTabGroup,
        AXNames.roleTextArea,
        AXNames.roleTextField,
        AXNames.roleValueIndicator
    ]

    private let contentRoles: Set<String> = [
        AXNames.roleCollection,
        AXNames.roleImage,
        AXNames.roleList,
        AXNames.roleOutline,
        AXNames.roleScrollArea,
        AXNames.roleSplitGroup,
        AXNames.roleTable,
        AXNames.roleWebArea
    ]

    public init(fallbackTitleBarHeight: CGFloat = 72) {
        self.fallbackTitleBarHeight = fallbackTitleBarHeight
    }

    public func targetWindow(for hitElement: AXUIElement, at point: CGPoint) -> AXUIElement? {
        let snapshots = AXElementReader.ancestors(startingAt: hitElement)

        guard let window = AXElementReader.firstWindow(in: snapshots) else {
            return nil
        }

        var owningProcess: pid_t = 0
        if AXUIElementGetPid(window, &owningProcess) == .success, owningProcess == getpid() {
            return nil
        }

        guard let frame = AXElementReader.frame(of: window), !frame.isEmpty else {
            return nil
        }

        let roles = snapshots.compactMap(\.role)
        if roles.contains(AXNames.roleTitleBar) {
            return window
        }

        if roles.contains(where: interactiveRoles.contains) {
            return nil
        }

        if roles.contains(where: contentRoles.contains) {
            return nil
        }

        guard pointIsInTopBand(point, of: frame) else {
            return nil
        }

        if roles.contains(AXNames.roleToolbar)
            || roles.contains(AXNames.roleGroup)
            || roles.contains(AXNames.roleWindow) {
            return window
        }

        return window
    }

    private func pointIsInTopBand(_ point: CGPoint, of windowFrame: CGRect) -> Bool {
        guard windowFrame.contains(point) else {
            return false
        }

        let height = min(fallbackTitleBarHeight, max(28, windowFrame.height * 0.2))
        return point.y >= windowFrame.minY && point.y <= windowFrame.minY + height
    }
}

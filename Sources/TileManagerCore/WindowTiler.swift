import ApplicationServices
import CoreGraphics
import Foundation

public enum TilingError: Error, LocalizedError {
    case noDisplays
    case windowFrameUnavailable
    case targetFrameUnavailable
    case accessibilitySetFailed(AXError)

    public var errorDescription: String? {
        switch self {
        case .noDisplays:
            return "No displays are available."
        case .windowFrameUnavailable:
            return "The selected window did not expose its frame through Accessibility."
        case .targetFrameUnavailable:
            return "TileManager could not find a target display for this window."
        case .accessibilitySetFailed(let error):
            return "Accessibility refused to move or resize the window: \(error)."
        }
    }
}

public final class WindowTiler {
    private let displayProvider: () -> [DisplayFrame]

    public init(displayProvider: @escaping () -> [DisplayFrame] = DisplayGeometry.currentDisplays) {
        self.displayProvider = displayProvider
    }

    public func targetFrame(forWindowFrame windowFrame: CGRect, clickPoint: CGPoint) -> CGRect? {
        let displays = displayProvider()
        guard !displays.isEmpty else {
            return nil
        }

        let windowCenter = windowFrame.center
        guard let display = DisplayGeometry.display(containing: windowCenter, from: displays)
            ?? DisplayGeometry.display(containing: clickPoint, from: displays)
            ?? DisplayGeometry.nearestDisplay(to: windowCenter, from: displays) else {
            return nil
        }

        let region = Self.region(forWindowCenter: windowCenter, in: display)
        return Self.targetFrame(for: region, in: display)
    }

    public func tile(window: AXUIElement, clickPoint: CGPoint) -> Result<CGRect, TilingError> {
        guard !displayProvider().isEmpty else {
            return .failure(.noDisplays)
        }

        guard let windowFrame = AXElementReader.frame(of: window) else {
            return .failure(.windowFrameUnavailable)
        }

        guard let targetFrame = targetFrame(forWindowFrame: windowFrame, clickPoint: clickPoint) else {
            return .failure(.targetFrameUnavailable)
        }

        let error = AXElementReader.setFrame(targetFrame, on: window)
        guard error == .success else {
            TileManagerLog.error("Failed to tile window to \(targetFrame): \(error)")
            return .failure(.accessibilitySetFailed(error))
        }

        TileManagerLog.info("Tiled window to \(targetFrame)")
        return .success(targetFrame)
    }

    public static func region(
        forWindowCenter windowCenter: CGPoint,
        in display: DisplayFrame
    ) -> TileRegion {
        windowCenter.y < display.visibleFrame.midY ? .topHalf : .bottomHalf
    }

    public static func targetFrame(for region: TileRegion, in display: DisplayFrame) -> CGRect {
        let visibleFrame = display.visibleFrame
        let topHeight = floor(visibleFrame.height / 2)
        let bottomHeight = visibleFrame.height - topHeight

        switch region {
        case .topHalf:
            return CGRect(
                x: visibleFrame.minX,
                y: visibleFrame.minY,
                width: visibleFrame.width,
                height: topHeight
            ).roundedForAccessibility
        case .bottomHalf:
            return CGRect(
                x: visibleFrame.minX,
                y: visibleFrame.minY + topHeight,
                width: visibleFrame.width,
                height: bottomHeight
            ).roundedForAccessibility
        }
    }
}

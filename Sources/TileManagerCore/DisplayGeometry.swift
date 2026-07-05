import AppKit
import CoreGraphics
import Foundation

public enum TileRegion: Equatable {
    case topHalf
    case bottomHalf
}

public enum TilingMode: String, CaseIterable, Equatable {
    case normal
    case screenRecorder

    public var title: String {
        switch self {
        case .normal:
            return "Normal Mode"
        case .screenRecorder:
            return "Screen Recorder Mode"
        }
    }
}

public struct DisplayFrame: Equatable {
    public let id: CGDirectDisplayID
    public let name: String
    public let frame: CGRect
    public let visibleFrame: CGRect

    public init(
        id: CGDirectDisplayID,
        name: String,
        frame: CGRect,
        visibleFrame: CGRect
    ) {
        self.id = id
        self.name = name
        self.frame = frame
        self.visibleFrame = visibleFrame
    }
}

public enum DisplayGeometry {
    public static func currentDisplays() -> [DisplayFrame] {
        let screens = NSScreen.screens
        let menuBarScreenMaxY = screens.first?.frame.maxY ?? NSScreen.main?.frame.maxY ?? 0

        return screens.map { screen in
            let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            return DisplayFrame(
                id: id,
                name: screen.localizedName,
                frame: accessibilityRect(fromAppKitRect: screen.frame, menuBarScreenMaxY: menuBarScreenMaxY),
                visibleFrame: accessibilityRect(fromAppKitRect: screen.visibleFrame, menuBarScreenMaxY: menuBarScreenMaxY)
            )
        }
    }

    public static func accessibilityRect(
        fromAppKitRect rect: CGRect,
        menuBarScreenMaxY: CGFloat
    ) -> CGRect {
        CGRect(
            x: rect.minX,
            y: menuBarScreenMaxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    public static func display(
        containing point: CGPoint,
        from displays: [DisplayFrame]
    ) -> DisplayFrame? {
        displays.first { $0.frame.contains(point) }
    }

    public static func nearestDisplay(
        to point: CGPoint,
        from displays: [DisplayFrame]
    ) -> DisplayFrame? {
        displays.min { lhs, rhs in
            squaredDistance(from: lhs.frame.center, to: point) < squaredDistance(from: rhs.frame.center, to: point)
        }
    }

    private static func squaredDistance(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    var roundedForAccessibility: CGRect {
        CGRect(
            x: origin.x.rounded(),
            y: origin.y.rounded(),
            width: size.width.rounded(),
            height: size.height.rounded()
        )
    }
}

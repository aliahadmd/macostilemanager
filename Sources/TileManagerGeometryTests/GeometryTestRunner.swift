import CoreGraphics
import Foundation
import TileManagerCore

@main
struct GeometryTestRunner {
    static func main() {
        testConvertsMainPortraitVisibleFrameToAccessibilityCoordinates()
        testConvertsSecondaryLandscapeFrameToAccessibilityCoordinates()
        testTargetFramesSplitVisibleFrameIntoTopAndBottomHalves()
        testScreenRecorderModeUsesBottomSixteenByNineAreaOnPortraitDisplay()
        testScreenRecorderModeUsesRecorderSplitForRegionInference()
        testScreenRecorderModeFallsBackToNormalHalvesOnLandscapeDisplay()
        testRegionUsesTopLeftCoordinateMidpoint()
        testTilerSelectsDisplayFromWindowCenterBeforeClickPoint()

        print("TileManagerGeometryTests passed")
    }

    private static func testConvertsMainPortraitVisibleFrameToAccessibilityCoordinates() {
        let appKitRect = CGRect(x: 0, y: 62, width: 1440, height: 2468)
        let converted = DisplayGeometry.accessibilityRect(
            fromAppKitRect: appKitRect,
            menuBarScreenMaxY: 2560
        )

        assertEqual(converted, CGRect(x: 0, y: 30, width: 1440, height: 2468))
    }

    private static func testConvertsSecondaryLandscapeFrameToAccessibilityCoordinates() {
        let appKitRect = CGRect(x: 1440, y: 0, width: 1280, height: 720)
        let converted = DisplayGeometry.accessibilityRect(
            fromAppKitRect: appKitRect,
            menuBarScreenMaxY: 2560
        )

        assertEqual(converted, CGRect(x: 1440, y: 1840, width: 1280, height: 720))
    }

    private static func testTargetFramesSplitVisibleFrameIntoTopAndBottomHalves() {
        let display = DisplayFrame(
            id: 1,
            name: "Portrait",
            frame: CGRect(x: 0, y: 0, width: 1440, height: 2560),
            visibleFrame: CGRect(x: 0, y: 30, width: 1440, height: 2468)
        )

        assertEqual(
            WindowTiler.targetFrame(for: .topHalf, in: display),
            CGRect(x: 0, y: 30, width: 1440, height: 1234)
        )
        assertEqual(
            WindowTiler.targetFrame(for: .bottomHalf, in: display),
            CGRect(x: 0, y: 1264, width: 1440, height: 1234)
        )
    }

    private static func testScreenRecorderModeUsesBottomSixteenByNineAreaOnPortraitDisplay() {
        let display = DisplayFrame(
            id: 1,
            name: "Portrait",
            frame: CGRect(x: 0, y: 0, width: 1440, height: 2560),
            visibleFrame: CGRect(x: 0, y: 30, width: 1440, height: 2468)
        )

        assertEqual(
            WindowTiler.targetFrame(for: .topHalf, in: display, mode: .screenRecorder),
            CGRect(x: 0, y: 30, width: 1440, height: 1658)
        )
        assertEqual(
            WindowTiler.targetFrame(for: .bottomHalf, in: display, mode: .screenRecorder),
            CGRect(x: 0, y: 1688, width: 1440, height: 810)
        )
    }

    private static func testScreenRecorderModeUsesRecorderSplitForRegionInference() {
        let display = DisplayFrame(
            id: 1,
            name: "Portrait",
            frame: CGRect(x: 0, y: 0, width: 1440, height: 2560),
            visibleFrame: CGRect(x: 0, y: 30, width: 1440, height: 2468)
        )

        assertEqual(
            WindowTiler.region(
                forWindowCenter: CGPoint(x: 720, y: 1600),
                in: display,
                mode: .screenRecorder
            ),
            .topHalf
        )
        assertEqual(
            WindowTiler.region(
                forWindowCenter: CGPoint(x: 720, y: 1800),
                in: display,
                mode: .screenRecorder
            ),
            .bottomHalf
        )
    }

    private static func testScreenRecorderModeFallsBackToNormalHalvesOnLandscapeDisplay() {
        let display = DisplayFrame(
            id: 2,
            name: "Landscape",
            frame: CGRect(x: 1440, y: 1840, width: 1280, height: 720),
            visibleFrame: CGRect(x: 1440, y: 1840, width: 1280, height: 720)
        )

        assertEqual(
            WindowTiler.targetFrame(for: .topHalf, in: display, mode: .screenRecorder),
            CGRect(x: 1440, y: 1840, width: 1280, height: 360)
        )
        assertEqual(
            WindowTiler.targetFrame(for: .bottomHalf, in: display, mode: .screenRecorder),
            CGRect(x: 1440, y: 2200, width: 1280, height: 360)
        )
    }

    private static func testRegionUsesTopLeftCoordinateMidpoint() {
        let display = DisplayFrame(
            id: 1,
            name: "Portrait",
            frame: CGRect(x: 0, y: 0, width: 1440, height: 2560),
            visibleFrame: CGRect(x: 0, y: 30, width: 1440, height: 2468)
        )

        assertEqual(
            WindowTiler.region(forWindowCenter: CGPoint(x: 720, y: 600), in: display),
            .topHalf
        )
        assertEqual(
            WindowTiler.region(forWindowCenter: CGPoint(x: 720, y: 2000), in: display),
            .bottomHalf
        )
    }

    private static func testTilerSelectsDisplayFromWindowCenterBeforeClickPoint() {
        let portrait = DisplayFrame(
            id: 1,
            name: "Portrait",
            frame: CGRect(x: 0, y: 0, width: 1440, height: 2560),
            visibleFrame: CGRect(x: 0, y: 30, width: 1440, height: 2468)
        )
        let landscape = DisplayFrame(
            id: 2,
            name: "Landscape",
            frame: CGRect(x: 1440, y: 1840, width: 1280, height: 720),
            visibleFrame: CGRect(x: 1440, y: 1840, width: 1280, height: 720)
        )
        let tiler = WindowTiler(displayProvider: { [portrait, landscape] })

        let target = tiler.targetFrame(
            forWindowFrame: CGRect(x: 1500, y: 1900, width: 600, height: 300),
            clickPoint: CGPoint(x: 100, y: 100)
        )

        assertEqual(target, CGRect(x: 1440, y: 1840, width: 1280, height: 360))
    }

    private static func assertEqual(
        _ actual: CGRect?,
        _ expected: CGRect,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let actual else {
            fatalError("Expected \(expected), got nil", file: file, line: line)
        }
        assertEqual(actual, expected, file: file, line: line)
    }

    private static func assertEqual(
        _ actual: CGRect,
        _ expected: CGRect,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard actual == expected else {
            fatalError("Expected \(expected), got \(actual)", file: file, line: line)
        }
    }

    private static func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard actual == expected else {
            fatalError("Expected \(expected), got \(actual)", file: file, line: line)
        }
    }
}

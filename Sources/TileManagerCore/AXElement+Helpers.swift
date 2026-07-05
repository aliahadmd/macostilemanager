import ApplicationServices
import CoreGraphics
import Foundation

enum AXNames {
    static let roleButton = "AXButton"
    static let roleCheckBox = "AXCheckBox"
    static let roleCollection = "AXCollection"
    static let roleComboBox = "AXComboBox"
    static let roleGroup = "AXGroup"
    static let roleImage = "AXImage"
    static let roleIncrementor = "AXIncrementor"
    static let roleLink = "AXLink"
    static let roleList = "AXList"
    static let roleMenu = "AXMenu"
    static let roleMenuButton = "AXMenuButton"
    static let roleMenuItem = "AXMenuItem"
    static let roleOutline = "AXOutline"
    static let rolePopUpButton = "AXPopUpButton"
    static let roleRadioButton = "AXRadioButton"
    static let roleScrollArea = "AXScrollArea"
    static let roleScrollBar = "AXScrollBar"
    static let roleSearchField = "AXSearchField"
    static let roleSlider = "AXSlider"
    static let roleSplitGroup = "AXSplitGroup"
    static let roleTabGroup = "AXTabGroup"
    static let roleTable = "AXTable"
    static let roleTextArea = "AXTextArea"
    static let roleTextField = "AXTextField"
    static let roleTitleBar = "AXTitleBar"
    static let roleToolbar = "AXToolbar"
    static let roleValueIndicator = "AXValueIndicator"
    static let roleWebArea = "AXWebArea"
    static let roleWindow = "AXWindow"
}

struct AXElementSnapshot {
    let element: AXUIElement
    let role: String?
}

enum AXElementReader {
    static func stringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard error == .success else {
            return nil
        }
        return value as? String
    }

    static func elementAttribute(_ attribute: CFString, from element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard error == .success else {
            return nil
        }
        return (value as! AXUIElement)
    }

    static func role(of element: AXUIElement) -> String? {
        stringAttribute(kAXRoleAttribute as CFString, from: element)
    }

    static func parent(of element: AXUIElement) -> AXUIElement? {
        elementAttribute(kAXParentAttribute as CFString, from: element)
    }

    static func window(from element: AXUIElement) -> AXUIElement? {
        if role(of: element) == AXNames.roleWindow {
            return element
        }
        if let window = elementAttribute(kAXWindowAttribute as CFString, from: element) {
            return window
        }
        return nil
    }

    static func ancestors(startingAt element: AXUIElement, maxDepth: Int = 12) -> [AXElementSnapshot] {
        var snapshots: [AXElementSnapshot] = []
        var current: AXUIElement? = element
        var depth = 0

        while let element = current, depth < maxDepth {
            snapshots.append(AXElementSnapshot(element: element, role: role(of: element)))

            if role(of: element) == AXNames.roleWindow {
                break
            }

            current = parent(of: element)
            depth += 1
        }

        return snapshots
    }

    static func firstWindow(in snapshots: [AXElementSnapshot]) -> AXUIElement? {
        for snapshot in snapshots {
            if snapshot.role == AXNames.roleWindow {
                return snapshot.element
            }
            if let window = window(from: snapshot.element) {
                return window
            }
        }
        return nil
    }

    static func frame(of element: AXUIElement) -> CGRect? {
        guard let position = pointAttribute(kAXPositionAttribute as CFString, from: element),
              let size = sizeAttribute(kAXSizeAttribute as CFString, from: element) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    static func setFrame(_ frame: CGRect, on element: AXUIElement) -> AXError {
        var position = frame.origin
        var size = frame.size

        guard let positionValue = AXValueCreate(.cgPoint, &position),
              let sizeValue = AXValueCreate(.cgSize, &size) else {
            return .failure
        }

        let positionError = AXUIElementSetAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            positionValue
        )

        let sizeError = AXUIElementSetAttributeValue(
            element,
            kAXSizeAttribute as CFString,
            sizeValue
        )

        guard positionError == .success else {
            return positionError
        }
        return sizeError
    }

    private static func pointAttribute(_ attribute: CFString, from element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard error == .success, let axValue = value else {
            return nil
        }

        var point = CGPoint.zero
        guard AXValueGetType(axValue as! AXValue) == .cgPoint,
              AXValueGetValue(axValue as! AXValue, .cgPoint, &point) else {
            return nil
        }
        return point
    }

    private static func sizeAttribute(_ attribute: CFString, from element: AXUIElement) -> CGSize? {
        var value: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard error == .success, let axValue = value else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetType(axValue as! AXValue) == .cgSize,
              AXValueGetValue(axValue as! AXValue, .cgSize, &size) else {
            return nil
        }
        return size
    }
}

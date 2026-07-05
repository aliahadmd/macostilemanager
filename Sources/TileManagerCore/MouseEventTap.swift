import ApplicationServices
import CoreGraphics
import Foundation

public final class MouseEventTap {
    public var onLeftMouseDown: ((_ point: CGPoint, _ clickState: Int64) -> Bool)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var shouldSwallowNextLeftMouseUp = false

    public init() {}

    deinit {
        stop()
    }

    public var isRunning: Bool {
        eventTap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false
    }

    @discardableResult
    public func start() -> Bool {
        guard eventTap == nil else {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return true
        }

        let mask = (CGEventMask(1) << CGEventType.leftMouseDown.rawValue)
            | (CGEventMask(1) << CGEventType.leftMouseUp.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: mouseEventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            TileManagerLog.error("Failed to create CGEvent tap")
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        TileManagerLog.info("CGEvent tap started")
        return true
    }

    public func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            TileManagerLog.info("CGEvent tap stopped")
        }

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        shouldSwallowNextLeftMouseUp = false
        runLoopSource = nil
        eventTap = nil
    }

    fileprivate func handle(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                TileManagerLog.info("CGEvent tap was disabled by macOS and re-enabled")
            }
            return Unmanaged.passUnretained(event)

        case .leftMouseUp:
            if shouldSwallowNextLeftMouseUp {
                shouldSwallowNextLeftMouseUp = false
                return nil
            }
            return Unmanaged.passUnretained(event)

        case .leftMouseDown:
            let clickState = event.getIntegerValueField(.mouseEventClickState)
            let shouldConsume = onLeftMouseDown?(event.location, clickState) ?? false
            if shouldConsume {
                shouldSwallowNextLeftMouseUp = true
                return nil
            }
            return Unmanaged.passUnretained(event)

        default:
            return Unmanaged.passUnretained(event)
        }
    }
}

private let mouseEventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let eventTap = Unmanaged<MouseEventTap>.fromOpaque(userInfo).takeUnretainedValue()
    return eventTap.handle(proxy: proxy, type: type, event: event)
}

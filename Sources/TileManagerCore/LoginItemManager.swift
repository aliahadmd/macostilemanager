import Foundation
import ServiceManagement

public enum LoginItemManager {
    public static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public static var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "On"
        case .notRegistered:
            return "Off"
        case .requiresApproval:
            return "Needs Approval"
        case .notFound:
            return "Unavailable"
        @unknown default:
            return "Unknown"
        }
    }

    public static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
            try SMAppService.mainApp.unregister()
        }
    }
}

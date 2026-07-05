import AppKit
import TileManagerCore

@main
struct TileManagerMain {
    private static var delegate: TileManagerAppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = TileManagerAppDelegate()
        self.delegate = delegate

        app.setActivationPolicy(.accessory)
        app.delegate = delegate
        app.run()
    }
}

final class TileManagerAppDelegate: NSObject, NSApplicationDelegate {
    private var controller: TileManagerController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = TileManagerController()
        self.controller = controller
        controller.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }
}

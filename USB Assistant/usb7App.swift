import SwiftUI

@main
struct usb7App: App {
    @StateObject private var usbMonitor = USBMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView(usbMonitor: usbMonitor)
        }
    }
}


import Foundation
import Combine
import IOKit
import IOKit.usb

struct USBEvent {
    let id: UUID
    let icon: String
    let description: String
    let timestamp: Date

    init(icon: String, description: String, timestamp: Date) {
        self.id = UUID() // 自动生成唯一标识符
        self.icon = icon
        self.description = description
        self.timestamp = timestamp
    }
}



class USBMonitor: ObservableObject {
   
    
    //添加通知变量
    @Published var deviceConnected: Bool = false {
        didSet {
//            print("deviceConnected changed to \(deviceConnected)")
        }
    }
    
    private var notifyPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0

    
    @Published var usbEvents: [USBEvent] = []
    
    init() {
        notifyPort = IONotificationPortCreate(kIOMasterPortDefault)
        guard let notifyPort = notifyPort else { return }
        
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
        let runLoopSource = IONotificationPortGetRunLoopSource(notifyPort).takeRetainedValue()
         
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        
        let selfRef = Unmanaged.passUnretained(self).toOpaque()

        let addedCallback: IOServiceMatchingCallback = { (userData, iterator) in
            let mySelf = Unmanaged<USBMonitor>.fromOpaque(userData!).takeUnretainedValue()
            // 在设备添加的逻辑中设置deviceConnected为true
            mySelf.deviceConnected = true
            while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
                var deviceNameCString = [CChar](repeating: 0, count: 256)
                IORegistryEntryGetName(usbDevice, &deviceNameCString)
                let deviceName = String(cString: &deviceNameCString)

                let event = USBEvent(icon: "usb_stick", description: "Device Added: \(deviceName)", timestamp: Date())
                mySelf.usbEvents.append(event)
                IOObjectRelease(usbDevice)
                

            }
        }

        
        
        let removedCallback: IOServiceMatchingCallback = { (userData, iterator) in
            let mySelf = Unmanaged<USBMonitor>.fromOpaque(userData!).takeUnretainedValue()
            while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
                var deviceNameCString = [CChar](repeating: 0, count: 256)
                IORegistryEntryGetName(usbDevice, &deviceNameCString)
                let deviceName = String(cString: &deviceNameCString)
                let event = USBEvent(icon: "usb_delete", description: "Device Removed: \(deviceName)", timestamp: Date())
                mySelf.usbEvents.append(event)
                IOObjectRelease(usbDevice)
            }
        }
        
        IOServiceAddMatchingNotification(notifyPort, kIOMatchedNotification, matchingDict, addedCallback, selfRef, &addedIterator)
        addedCallback(selfRef, addedIterator)
        
        IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification, matchingDict, removedCallback, selfRef, &removedIterator)
        removedCallback(selfRef, removedIterator)
    }
    
    deinit {
        if addedIterator != 0 {
            IOObjectRelease(addedIterator)
        }
        if removedIterator != 0 {
            IOObjectRelease(removedIterator)
        }
        if let notifyPort = notifyPort {
            IONotificationPortDestroy(notifyPort)
        }
    }
}

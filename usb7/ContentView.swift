import SwiftUI

struct ContentView: View {
    @ObservedObject var usbMonitor: USBMonitor
    @State private var filterOption: FilterOption = .lastMinute
    @State private var timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    @State private var showDeviceConnectedMessage = false
    @State private var usbKeyOffset = CGSize(width: -50, height: -50)
    @State private var animateImage = false

    @State private var backgroundOpacity = 0.2 // 添加一个状态变量来控制背景透明度

    var body: some View {
        NavigationSplitView {
            VStack {
                Picker("", selection: $filterOption) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List(filteredEvents, id: \.id) { event in
                    HStack {
                        Image(event.icon)
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text(event.description)
                            .foregroundColor(isRecent(event: event) ? .red : .black)
                            .bold()
                    }
                }
                .onReceive(timer) { _ in
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        // Action for scanning USB devices
                    }) {
                        // Uncomment and use the label if needed
                        // Label("Scan USB", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .background(Color.gray.opacity(0.2))
        } detail: {
            VStack {
                Spacer()
                ZStack(alignment: .center) {
                    Image("macbook3")
                    if showDeviceConnectedMessage {
                        Image("usbkey")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(96))
                            .offset(x: -75, y: -28)
                    }
                }
                Spacer()
//                if showDeviceConnectedMessage {
//                    Text("Detect USB device connected")
//                        .padding()
//                        .background(Color.green)
//                        .foregroundColor(.white)
//                        .cornerRadius(5)
//                        .transition(.opacity)
//                        .onAppear {
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                                self.showDeviceConnectedMessage = false
//                            }
//                        }
//                        .padding(.bottom)
//                }
            }
//            .background(Image("hex").opacity(0.5))
            .background(Image("hex").opacity(backgroundOpacity)) // 使用状态变量作为透明度值
                        .onAppear {
                            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                                backgroundOpacity = 0.8
                            }
                        }
            .overlay(
                    Group {
                        if showDeviceConnectedMessage {
                            Text("Detect USB device connected")
                                .font(.title3)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(5)
                                .transition(.opacity)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        self.showDeviceConnectedMessage = false
                                    }
                                }
                                .padding(20)
                        }
                            
                    },
                    alignment: .bottom
                )
            .onReceive(usbMonitor.$deviceConnected) { deviceConnected in
                if deviceConnected {
                    self.showDeviceConnectedMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showDeviceConnectedMessage = false
                        self.usbMonitor.deviceConnected = false
                    }
                }
            }
        }
    }

    private var filteredEvents: [USBEvent] {
        switch filterOption {
        case .lastMinute:
            return usbMonitor.usbEvents.filter { $0.timestamp > Date().addingTimeInterval(-60) }
        case .lastTenMinutes:
            return usbMonitor.usbEvents.filter { $0.timestamp > Date().addingTimeInterval(-600) }
        case .lastHour:
            return usbMonitor.usbEvents.filter { $0.timestamp > Date().addingTimeInterval(-3600) }
        case .all:
            return usbMonitor.usbEvents
        }
    }

    private func isRecent(event: USBEvent) -> Bool {
        return event.timestamp > Date().addingTimeInterval(-5)
    }

    enum FilterOption: String, CaseIterable {
        case lastMinute = "1 Minute"
        case lastTenMinutes = "10 Minutes"
        case lastHour = "1 Hour"
        case all = "All"
    }
}

//
//  ContentView.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var manager: DeviceManager
    
    var body: some View {
        NavigationView {
            if let device = manager.myDevice {
                DeviceView(manager: manager, device: device)
            } else {
                ProgressView()
            }
        }
    }
}

struct FireAlertView: View {
    @State private var blinking: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "light.beacon.max")
                .imageScale(.large)
                .symbolEffect(.pulse, options: .repeating, value: blinking)
                .onAppear {
                    blinking = true
                }
            VStack(alignment: .leading) {
                Text("Fire Detected")
                    .font(.headline)
                Text("Alarm is sounding. Heater is disabled.")
            }
        }
        .listRowBackground(Color(red: 1, green: 0.27, blue: 0))
        .foregroundColor(.white)
    }
}

struct DeviceView: View {
    @ObservedObject var manager: DeviceManager
    var device: Device
    
    var body: some View {
        Form {
            if device.fire {
                FireAlertView()
            }
            DeviceStatusView(manager: manager, device: device)
            TemperatureView(manager: manager, device: device)
            BuzzerSettingsView(manager: manager, device: device)
            Section {
                Text("Last movement: \(device.lastMovement, style: .relative) ago")
            }
        }
        .navigationTitle(manager.documentId)
    }
}

#Preview {
//    DeviceView(manager: DeviceManager, device: Device(id: nil, currentTemp: 20, setTemp: 21, lastMovement: Date(timeIntervalSinceNow: 310), mode: .enabled, lastUpdate: Date(), heating: false))
}

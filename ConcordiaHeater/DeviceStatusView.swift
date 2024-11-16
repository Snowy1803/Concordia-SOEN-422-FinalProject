//
//  DeviceStatusView.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import SwiftUI

struct DeviceStatusView: View {
    @ObservedObject var manager: DeviceManager
    var device: Device
    
    var body: some View {
        Section {
            Toggle(isOn: Binding { device.mode != .disabled } set: { value in
                manager.setMode(value ? .enabled : .disabled)
            }) {
                Label("Enable Heater", systemImage: "heat.waves")
            }
            if device.mode != .disabled {
                Toggle(isOn: Binding { device.mode == .heat } set: { value in
                    manager.setMode(value ? .heat : .enabled)
                }) {
                    Label("Heat When Room Empty", systemImage: "person.fill.checkmark")
                }
            }
        } header: {
            Text("Mode")
        } footer: {
            switch (device.mode, device.heating) {
            case (.disabled, true):
                Text("Heater is disabled and will stop heating shortly")
            case (.disabled, false):
                Text("Heater is disabled and will not heat")
            case (.enabled, true):
                if device.lastMovement.timeIntervalSinceNow < -45 {
                    Text("Heater will stop shortly as no movement is detected")
                } else {
                    Text("Heater is heating as movement was detected")
                }
            case (.enabled, false):
                if device.lastMovement.timeIntervalSinceNow < -30 {
                    Text("Heater will heat once someone enters the room")
                } else if device.currentTemp < device.setTemp {
                    Text("Heater will start shortly as movement was detected")
                } else {
                    Text("Heater is enabled as movement was detected, temperature is stable")
                }
            case (.heat, true):
                Text("Heater is enabled and heating")
            case (.heat, false):
                if device.currentTemp < device.setTemp {
                    Text("Heater will start shortly")
                } else {
                    Text("Heater is enabled and temperature is stable")
                }
            }
        }
    }
}

#Preview {
//    DeviceView(manager: DeviceManager, device: Device(id: nil, currentTemp: 20, setTemp: 21, lastMovement: Date(timeIntervalSinceNow: 310), mode: .enabled, lastUpdate: Date(), heating: false))
}

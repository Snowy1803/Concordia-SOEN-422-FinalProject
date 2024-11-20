//
//  BuzzerSettingsView.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import SwiftUI

struct BuzzerSettingsView: View {
    @ObservedObject var manager: DeviceManager
    var device: Device
    
    var body: some View {
        Section {
            Slider(value: Binding {
                Double(device.buzzer.rawValue)
            } set: { value in
                if let setting = BuzzerSetting(rawValue: Int(value)) {
                    manager.setBuzzerSetting(setting)
                }
            }, in: Double(BuzzerSetting.silent.rawValue) ... Double(BuzzerSetting.heating.rawValue)) {
                Text("Sound level")
            } minimumValueLabel: {
                Text("Silent")
            } maximumValueLabel: {
                Text("All")
            }
        } header: {
            Text("Sounds")
        } footer: {
            switch device.buzzer {
            case .silent:
                Text("Heater is silent")
            case .mode:
                Text("Heater will sound for mode changes")
            case .heating:
                Text("Heater will sound when heating changes, even when it is due to a temperature change")
            }
        }
    }
}

#Preview {
//    DeviceView(manager: DeviceManager, device: Device(id: nil, currentTemp: 20, setTemp: 21, lastMovement: Date(timeIntervalSinceNow: 310), mode: .enabled, lastUpdate: Date(), heating: false))
}

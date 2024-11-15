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

struct DeviceView: View {
    @ObservedObject var manager: DeviceManager
    var device: Device
    
    var body: some View {
        Form {
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
            } footer: {
                switch device.mode {
                case .disabled:
                    Text("Heater is disabled and will not heat")
                case .enabled:
                    if device.heating {
                        Text("Heater is heating, as someone is in the room")
                    } else {
                        Text("Heater will heat once someone will be in the room")
                    }
                case .heat:
                    Text("Heater is heating")
                }
            }
            TemperatureView(manager: manager, device: device)
            Section {
                Text("Last movement: \(device.lastMovement, style: .relative) ago")
            }
        }
        .navigationTitle(device.id ?? "Unknown")
    }
}

struct TemperatureView: View {
    static let tempFormatter = Measurement<UnitTemperature>.FormatStyle.measurement(width: .narrow, numberFormatStyle: .number.precision(.fractionLength(1)))
    @ObservedObject var manager: DeviceManager
    var device: Device
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    manager.incrementSetTemp(by: -0.5)
                } label: {
                    Label("Decrease", systemImage: "minus")
                        .frame(width: 36, height: 40)
                }
                Circle()
                    .fill(LinearGradient(colors: [colorTemp(temp: device.currentTemp), colorTemp(temp: device.setTemp)], startPoint: .top, endPoint: .bottom) )
                    .stroke(.black)
                    .aspectRatio(1, contentMode: .fill)
                    .overlay {
                        VStack {
                            Text("\(Measurement(value: device.currentTemp, unit: .celsius), format: TemperatureView.tempFormatter)")
                                .font(.title)
                            Label("\(Measurement(value: device.setTemp, unit: .celsius), format: TemperatureView.tempFormatter)", systemImage: "heat.waves")
                                .foregroundStyle(device.heating ? .red : .gray)
                                .labelStyle(.titleAndIcon)
                                .padding()
                                .background(Capsule().fill(.thinMaterial))
                        }
                    }
                Button {
                    manager.incrementSetTemp(by: 0.5)
                } label: {
                    Label("Increase", systemImage: "plus")
                        .frame(width: 36, height: 40)
                }
            }.buttonStyle(BorderedButtonStyle())
                .labelStyle(.iconOnly)
                .padding(.bottom)
            Text("Last updated \(device.lastUpdate, style: .relative) ago")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }
    
    func colorTemp(temp: Double) -> Color {
        let hue = (1 - max(0, min(1, (temp - 10) / 25))) * 0.67
        return Color(hue: hue, saturation: 0.5, brightness: 0.8)
    }
}

#Preview {
//    DeviceView(manager: DeviceManager, device: Device(id: nil, currentTemp: 20, setTemp: 21, lastMovement: Date(timeIntervalSinceNow: 310), mode: .enabled, lastUpdate: Date(), heating: false))
}

//
//  ContentView.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import SwiftUI

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
            HStack {
                if device.lastUpdate.timeIntervalSinceNow < -60 {
                    Image(systemName: "wifi.exclamationmark")
                }
                Text("Last updated \(device.lastUpdate, style: .relative) ago")
            }
            .font(.caption)
            .foregroundStyle(device.lastUpdate.timeIntervalSinceNow < -60 ? .red : .secondary)
        }
        .padding(.vertical)
    }
    
    func colorTemp(temp: Double) -> Color {
        let hue = (1 - max(0, min(1, (temp - 10) / 25))) * 0.67
        return Color(hue: hue, saturation: 0.5, brightness: 0.8)
    }
}

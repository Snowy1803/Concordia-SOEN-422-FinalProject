//
//  Device.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import Foundation

enum Mode: Int, Codable {
    /// The device is disabled
    case disabled
    /// The device is enabled when movement is detected
    case enabled
    /// The device is enabled unconditionally
    case heat
}

enum BuzzerSetting: Int, Codable {
    /// The buzzer is silent / disabled
    case silent
    /// The buzzer signals mode changes
    case mode
    /// The buzzer signals mode changes, and when heating changes for any reason
    case heating
}

struct Device: Codable {
    var currentTemp: Double
    var setTemp: Double
    var lastMovement: Date
    var mode: Mode
    var lastUpdate: Date
    var heating: Bool
    var buzzer: BuzzerSetting
}

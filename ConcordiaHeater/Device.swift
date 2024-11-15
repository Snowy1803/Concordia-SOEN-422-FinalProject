//
//  Device.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import Foundation

enum Mode: Int, Codable {
    case disabled
    case enabled
    case heat
}

struct Device: Codable {
    var currentTemp: Double
    var setTemp: Double
    var lastMovement: Date
    var mode: Mode
    var lastUpdate: Date
    var heating: Bool
}

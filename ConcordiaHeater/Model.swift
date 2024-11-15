//
//  Model.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import Foundation
import FirebaseDatabase

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

class DeviceManager: ObservableObject {
    let base = Database.database()
    let documentId = "H968"
    @Published var myDevice: Device?
    
    init() {
        initListener()
    }
    
    func initListener() {
        base.reference().child(documentId).observe(.value) { snapshot in
            Task { @MainActor in
                let decoder = Database.Decoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                self.myDevice = try snapshot.data(as: Device.self, decoder: decoder)
            }
        }
    }
    
    func incrementSetTemp(by value: Double) {
        myDevice?.setTemp += value
        Task {
            if let myDevice {
                base.reference().child(documentId).child("setTemp").setValue(myDevice.setTemp)
            }
        }
    }
    
    func setMode(_ mode: Mode) {
        myDevice?.mode = mode
        Task {
            if let myDevice {
                base.reference().child(documentId).child("mode").setValue(myDevice.mode.rawValue)
            }
        }
    }
}

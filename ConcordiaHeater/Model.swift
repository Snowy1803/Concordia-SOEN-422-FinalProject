//
//  Model.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import Foundation
import FirebaseFirestore

enum Mode: Int, Codable {
    case disabled
    case enabled
    case heat
}

struct Device: Codable {
    @DocumentID var id: String?
    var currentTemp: Double
    var setTemp: Double
    var lastMovement: Date
    var mode: Mode
    var lastUpdate: Date
    var heating: Bool
}

class DeviceManager: ObservableObject {
    let db = Firestore.firestore()
    @Published var myDevice: Device?
    
    func fetch() async throws {
        let device = try await fetchDevice(documentId: "H968")
        Task { @MainActor in
            myDevice = device
        }
    }
    
    private func fetchDevice(documentId: String) async throws -> Device {
        try await db.collection("heater").document(documentId).getDocument(as: Device.self)
    }
    
    func incrementSetTemp(by value: Double) {
        guard let id = myDevice?.id else { return }
        myDevice?.setTemp += value
        Task {
            if let myDevice {
                try await db.collection("heater").document(id).updateData(["setTemp": myDevice.setTemp])
            }
        }
    }
    
    func setMode(_ mode: Mode) {
        guard let id = myDevice?.id else { return }
        myDevice?.mode = mode
        Task {
            if let myDevice {
                try await db.collection("heater").document(id).updateData(["mode": myDevice.mode.rawValue])
            }
        }
    }
}

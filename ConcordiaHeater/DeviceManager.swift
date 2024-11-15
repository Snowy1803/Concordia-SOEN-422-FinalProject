//
//  DeviceManager.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import Foundation
import FirebaseDatabase

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
                // update last update to red
                self.updateAfter(self.myDevice!.lastUpdate.timeIntervalSinceNow + 60)
                // update status explanation text
                self.updateAfter(self.myDevice!.lastMovement.timeIntervalSinceNow + 30)
                self.updateAfter(self.myDevice!.lastMovement.timeIntervalSinceNow + 45)
            }
        }
    }
    
    private func updateAfter(_ delay: Double) {
        if delay <= 0 { return }
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + .milliseconds(Int(1000 * delay))) {
            self.objectWillChange.send()
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

//
//  ConcordiaHeaterApp.swift
//  ConcordiaHeater
//
//  Created by Emil Pedersen on 14/11/2024.
//

import SwiftUI
import FirebaseCore

#if os(iOS)
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}
#endif


@main
struct ConcordiaHeaterApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif
    
    @StateObject var manager = DeviceManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
        }
    }
}

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
    
    @State var shownError: Error?
    @State var hasError: Bool = false
    @StateObject var manager = DeviceManager()
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
                .environment(\.locale, Locale.init(identifier: "en-CA"))
                .onReceive(timer) { _ in
                    Task {
                        await load()
                    }
                }
                .alert("Error", isPresented: $hasError, presenting: shownError) {
                    error in
                    Button {
                        Task {
                            await load()
                        }
                    } label: {
                        Text("Retry")
                    }
                } message: { error in
                    Text(error.localizedDescription)
                }
        }
    }
    
    func load() async {
        do {
            try await manager.fetch()
        } catch let error {
            shownError = error
            hasError = true
        }
    }
}

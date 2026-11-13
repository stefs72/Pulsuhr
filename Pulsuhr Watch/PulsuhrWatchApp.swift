//
//  PulsuhrWatchApp.swift
//  Pulsuhr Watch
//
//  Misst den Puls und gibt ihn ans iPhone weiter, das ihn als Bluetooth-Pulsgurt freigibt.
//

import SwiftUI

@main
struct PulsuhrWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchAnsicht()
        }
    }
}

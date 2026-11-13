//
//  PulsuhrApp.swift
//  Pulsuhr
//
//  Gibt den Puls der Apple Watch als Bluetooth-Pulsgurt frei, damit Apps auf dem Mac ihn
//  lesen können (MyWhoosh und alles andere, was einen Brustgurt erwartet).
//
//  Die Uhr misst, das iPhone funkt — die Uhr selbst darf das nicht, Apple sperrt den
//  Peripheral-Betrieb auf watchOS.
//

import SwiftUI

@main
struct PulsuhrApp: App {
    var body: some Scene {
        WindowGroup {
            Ansicht()
        }
    }
}

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
    @UIApplicationDelegateAdaptor(Delegierter.self) private var delegierter

    var body: some Scene {
        WindowGroup {
            Ansicht()
        }
    }
}

/// Wirft die Brücke beim Programmstart an, nicht erst wenn jemand hinschaut.
///
/// Das ist kein Zierrat. Startet iOS die App im Hintergrund neu, weil der Mac sich wieder
/// verbindet, wird keine Ansicht sichtbar — an `onAppear` gehängt käme der Bluetooth-Dienst
/// nie wieder hoch, und der ganze Wiederanlauf im `PulsSender` wäre wertlos.
final class Delegierter: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MainActor.assumeIsolated { Bruecke.geteilt.start() }
        return true
    }
}

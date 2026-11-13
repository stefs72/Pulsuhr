//
//  Bruecke.swift
//  Pulsuhr
//
//  Nimmt den Puls von der Uhr entgegen und reicht ihn an den Sender weiter, der ihn als
//  Bluetooth-Pulsgurt freigibt. Das ist die ganze Aufgabe des iPhones.
//

import Foundation
import WatchConnectivity

@MainActor
final class Bruecke: NSObject, ObservableObject {

    @Published private(set) var puls: Int?
    @Published private(set) var verbunden = false      // hört eine Mac-App zu?
    @Published private(set) var funkt = false          // ist die Freigabe aktiv?
    @Published private(set) var hinweis: String?

    private let sender = PulsSender()
    private var beobachter: [NSObjectProtocol] = []

    func start() {
        sender.start()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        // Zustand des Senders durchreichen, damit die Ansicht nur eine Quelle kennt.
        sender.$funkt.assign(to: &$funkt)
        sender.$zuhoerer.map { $0 > 0 }.assign(to: &$verbunden)
        sender.$hinweis.assign(to: &$hinweis)
    }

    /// Zustandszeile in Worten.
    var zustand: String {
        if let hinweis { return hinweis }
        if verbunden { return "Mac liest mit" }
        if funkt { return "freigegeben – wartet auf den Mac" }
        return "startet …"
    }
}

extension Bruecke: WCSessionDelegate {

    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Nach einem Uhrenwechsel muss neu aktiviert werden, sonst kommt nichts mehr an.
        WCSession.default.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let bpm = message["bpm"] as? Int else { return }
        Task { @MainActor in
            puls = bpm
            sender.sende(bpm)
        }
    }
}

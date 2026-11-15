//
//  Funk.swift
//  Pulsuhr Watch
//
//  Schickt den gemessenen Puls ans iPhone. Mehr nicht.
//
//  Warum der Umweg: Die Uhr darf selbst kein Bluetooth-Peripheral sein — Apple sperrt
//  `CBPeripheralManager` dort ausdrücklich (`API_UNAVAILABLE(watchos)` im Header). Also misst
//  die Uhr, und das iPhone gibt den Wert als Pulsgurt frei.
//

import Foundation
import WatchConnectivity

final class Funk: NSObject, WCSessionDelegate {

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Einen Wert ans iPhone geben.
    ///
    /// Bewusst `sendMessage` ohne Antwort und ohne Fehlerbehandlung: Es geht um den Puls von
    /// jetzt. Kommt einer nicht an, folgt in einer Sekunde der nächste — nachliefern wäre
    /// falsch, ein alter Wert ist schlechter als gar keiner.
    ///
    /// **Nicht auf `isReachable` prüfen.** Genau das war der Grund für die abreissende
    /// Verbindung: Sobald das iPhone den Bildschirm sperrte oder eine andere App nach vorn
    /// kam, stand `isReachable` auf `false` — und wir warfen jeden Wert selbst weg. Dabei
    /// ist `sendMessage` von der Uhr aus das Mittel, das die iPhone-App im Hintergrund
    /// überhaupt erst aufweckt. Die Prüfung verhinderte also das, wofür sie gedacht war.
    func sende(_ bpm: Int) {
        let s = WCSession.default
        guard s.activationState == .activated else { return }
        s.sendMessage(["bpm": bpm], replyHandler: nil, errorHandler: nil)
    }

    /// Dem iPhone sagen, dass Schluss ist.
    ///
    /// Ohne diese Nachricht bliebe dort der letzte Wert stehen und würde weiter an den Mac
    /// gehen — eine eingefrorene Zahl ist schlechter als gar keine. Das iPhone merkt es zwar
    /// auch von allein (es verfällt nach zehn Sekunden), aber nur so geht es sofort.
    func sendeStop() {
        let s = WCSession.default
        guard s.activationState == .activated else { return }
        s.sendMessage(["stop": true], replyHandler: nil, errorHandler: nil)
    }

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
}

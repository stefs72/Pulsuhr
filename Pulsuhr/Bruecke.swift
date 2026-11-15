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

    /// Es gibt genau eine Brücke, und sie gehört dem Programm, nicht der Ansicht.
    ///
    /// Startet iOS die App im Hintergrund neu, weil der Mac sich wieder verbindet, gibt es
    /// keine sichtbare Ansicht — eine Brücke, die erst beim Hinschauen entsteht, käme nie
    /// zustande. Angeworfen wird sie deshalb im `Delegierten` beim Programmstart.
    static let geteilt = Bruecke()

    private let sender = PulsSender()
    private var angeworfen = false

    /// Nach so langer Stille gilt der Wert als veraltet.
    ///
    /// Zehn Sekunden sind grosszügig: HealthKit liefert beim Training im Sekundentakt, in Ruhe
    /// aber auch mal spärlicher. Lieber einmal zu spät verfallen als bei jedem Schluckauf der
    /// Verbindung die Anzeige leeren.
    private let frisch: TimeInterval = 10
    private var letzterWert: Date?
    private var wache: Timer?

    func start() {
        guard !angeworfen else { return }      // zweimal anwerfen hiesse zwei Wachen und zwei Takte
        angeworfen = true
        sender.start()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        // Zustand des Senders durchreichen, damit die Ansicht nur eine Quelle kennt.
        sender.$funkt.assign(to: &$funkt)
        sender.$zuhoerer.map { $0 > 0 }.assign(to: &$verbunden)
        sender.$hinweis.assign(to: &$hinweis)

        // Wache gegen stehengebliebene Werte: Schaltet die Uhr ab, geht sie ausser Reichweite
        // oder stürzt sie ab, kommt einfach nichts mehr — ohne diese Prüfung stünde die letzte
        // Zahl für immer da und ginge weiter an den Mac.
        wache = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pruefeFrische() }
        }
    }

    /// Zustandszeile in Worten.
    var zustand: String {
        if let hinweis { return hinweis }
        if puls == nil && funkt { return "warte auf die Uhr" }
        if verbunden { return "Mac liest mit" }
        if funkt { return "freigegeben – wartet auf den Mac" }
        return "startet …"
    }

    private func pruefeFrische() {
        guard let letzter = letzterWert, Date().timeIntervalSince(letzter) > frisch else { return }
        verfallen()
    }

    /// Kein gültiger Puls mehr: Anzeige leeren und dem Mac Null schicken.
    ///
    /// Die Null ist kein Pfusch, sondern das Übliche — ein Brustgurt, den man abnimmt, sendet
    /// ebenfalls 0. Damit weiss die Gegenstelle, dass kein Kontakt besteht, statt eine alte
    /// Zahl für bare Münze zu nehmen.
    private func verfallen() {
        letzterWert = nil
        guard puls != nil else { return }
        puls = nil
        sender.sende(0)
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
        if message["stop"] != nil {
            Task { @MainActor in verfallen() }      // Uhr hat abgeschaltet: sofort, nicht erst nach zehn Sekunden
            return
        }
        guard let bpm = message["bpm"] as? Int else { return }
        Task { @MainActor in
            puls = bpm
            letzterWert = Date()
            sender.sende(bpm)
        }
    }
}

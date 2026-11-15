//
//  PulsSender.swift
//  Pulsuhr
//
//  Funkt den Puls als **Standard-Pulsgurt**: Bluetooth-Dienst „Heart Rate" (0x180D).
//  Damit muss die Gegenstelle nichts über uns wissen — MyWhoosh, Zwift und alles andere
//  sucht genau diesen Dienst und sieht das iPhone wie einen Brustgurt.
//
//  Zwei Dinge entscheiden hier über eine stabile Verbindung:
//
//  1. **Sofort senden, Takt nur als Lückenfüller.** Jeder Wert der Uhr geht beim Eintreffen
//     hinaus — im Hintergrund ist das der einzige Moment, in dem die App überhaupt läuft.
//     Solange sie wach ist, füllt ein 1-s-Takt zusätzlich Lücken, wenn die Uhr stockt.
//
//  2. **Wiederanlauf.** Mit der Kennung unten darf iOS die App im Hintergrund neu starten,
//     sobald der Mac sich wieder meldet. Ohne sie wäre nach einem Abräumen durch das System
//     endgültig Schluss, bis jemand die App von Hand öffnet.
//

import Foundation
import CoreBluetooth

@MainActor
final class PulsSender: NSObject, ObservableObject {

    /// Wie viele Gegenstellen gerade zuhören (0 = niemand verbunden).
    @Published private(set) var zuhoerer = 0
    /// Funkt das iPhone gerade? (Bluetooth an, Dienst veröffentlicht, Werbung läuft.)
    @Published private(set) var funkt = false
    /// Klartext für die Anzeige, wenn etwas im Weg steht (Bluetooth aus, keine Erlaubnis …).
    @Published private(set) var hinweis: String?

    // Die Kennungen sind von der Bluetooth-SIG vergeben und nicht verhandelbar.
    private let dienst = CBUUID(string: "180D")        // Heart Rate Service
    private let messwert = CBUUID(string: "2A37")      // Heart Rate Measurement
    private let ort = CBUUID(string: "2A38")           // Body Sensor Location

    /// Erlaubt iOS den Wiederanlauf im Hintergrund. Der Text ist frei wählbar, muss über
    /// Programmstarts hinweg aber derselbe bleiben — daran erkennt das System den Dienst.
    private let wiederanlauf = "Moveaware.Pulsuhr.Sender"

    private var manager: CBPeripheralManager?
    private var messwertMerkmal: CBMutableCharacteristic?
    /// Kam der Dienst aus einem Wiederanlauf? Dann darf er nicht neu angelegt werden — er
    /// läuft bereits, samt bestehender Verbindung zum Mac.
    private var ausWiederanlauf = false

    /// Der Wert, der gerade gilt.
    private var aktuell: UInt8?
    private var takt: Timer?
    /// Wann zuletzt etwas hinausging — damit der Takt nicht gleich nochmals sendet.
    private var letzterVersand = Date.distantPast

    func start() {
        guard manager == nil else { return }
        // Eigene Queue wäre schneller, aber hier zählt Einfachheit: ein Wert pro Sekunde
        // ist für den Hauptthread nichts.
        manager = CBPeripheralManager(delegate: self, queue: .main, options: [
            CBPeripheralManagerOptionRestoreIdentifierKey: wiederanlauf,
        ])
        takt = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.schlag() }
        }
    }

    func stop() {
        takt?.invalidate()
        takt = nil
        manager?.stopAdvertising()
        manager?.removeAllServices()
        manager = nil
        messwertMerkmal = nil
        aktuell = nil
        zuhoerer = 0
        funkt = false
    }

    /// Einen neuen Wert übernehmen und **sofort** hinausschicken.
    ///
    /// Sofort, nicht erst im Takt — das ist entscheidend für den Hintergrund. Dort friert iOS
    /// die App ein und weckt sie nur kurz, wenn von der Uhr etwas eintrifft. Timer laufen in
    /// der eingefrorenen Zeit nicht. Wer hier nur speichert und aufs Senden im Takt wartet,
    /// sendet im Hintergrund nie (so war es kurz am 15.11.2026: Verbindung stand, Puls kam
    /// keiner).
    func sende(_ bpm: Int) {
        aktuell = UInt8(clamping: bpm)
        hinaus()
    }

    /// Einmal pro Sekunde, **nur solange die App wach ist**: Lücken füllen, wenn die Uhr
    /// gerade nichts liefert, Zuhörer zählen, notfalls wieder werben.
    private func schlag() {
        guard let manager, manager.state == .poweredOn else { return }
        zaehleZuhoerer()

        if zuhoerer == 0, messwertMerkmal != nil, !manager.isAdvertising {
            werben(manager)
        }

        // Kam eben erst ein Wert der Uhr durch, nicht doppelt senden.
        guard Date().timeIntervalSince(letzterVersand) >= 0.9 else { return }
        hinaus()
    }

    /// Den geltenden Wert an alle Zuhörer schicken.
    private func hinaus() {
        guard let manager, manager.state == .poweredOn,
              let merkmal = messwertMerkmal, let wert = aktuell else { return }
        zaehleZuhoerer()
        guard zuhoerer > 0 else { return }
        // Format nach Bluetooth-Spezifikation: erstes Byte sind Flags, zweites der Wert.
        // Flag-Bit 0 = 0 heisst „Puls passt in ein Byte" — bis 255 Schläge, das reicht.
        // Misslingt es (Warteschlange voll), kommt mit dem nächsten Wert der nächste Versuch.
        if manager.updateValue(Data([0x00, wert]), for: merkmal, onSubscribedCentrals: nil) {
            letzterVersand = Date()
        }
    }

    /// Die Wahrheit steht im Merkmal selbst. Mitzählen über die Delegate-Rückrufe wäre nach
    /// einem Wiederanlauf falsch: Dort meldet niemand die schon bestehenden Verbindungen an.
    private func zaehleZuhoerer() {
        let n = messwertMerkmal?.subscribedCentrals?.count ?? 0
        if n != zuhoerer { zuhoerer = n }
    }

    private func werben(_ peripheral: CBPeripheralManager) {
        // Die Dienstkennung MUSS in der Werbung stehen, sonst findet die Gegenstelle uns
        // beim Suchen nach Pulsgurten nicht — sie filtert genau danach.
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [dienst],
            CBAdvertisementDataLocalNameKey: "Pulsuhr",
        ])
    }

    private func dienstVeroeffentlichen(_ peripheral: CBPeripheralManager) {
        let messung = CBMutableCharacteristic(type: messwert,
                                              properties: [.notify],
                                              value: nil,
                                              permissions: [.readable])
        // Fester Wert 0x02 = Handgelenk. Manche Gegenstellen fragen ihn ab; weil er sich nie
        // ändert, darf er direkt im Merkmal stehen (dann ist er automatisch nur lesbar).
        let sitz = CBMutableCharacteristic(type: ort,
                                           properties: [.read],
                                           value: Data([0x02]),
                                           permissions: [.readable])
        let hrs = CBMutableService(type: dienst, primary: true)
        hrs.characteristics = [messung, sitz]

        messwertMerkmal = messung
        peripheral.removeAllServices()
        peripheral.add(hrs)
    }
}

extension PulsSender: CBPeripheralManagerDelegate {

    /// iOS hat die App im Hintergrund neu gestartet und reicht den alten Dienst zurück.
    ///
    /// Wird **vor** `peripheralManagerDidUpdateState` gerufen. Hier nur übernehmen, nichts
    /// neu anlegen: Ein zweiter Dienst würde den bestehenden ersetzen und die Verbindung zum
    /// Mac genau in dem Moment kappen, in dem sie gerettet werden soll.
    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       willRestoreState dict: [String: Any]) {
        let dienste = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService]
        Task { @MainActor in
            for d in dienste ?? [] where d.uuid == dienst {
                messwertMerkmal = d.characteristics?
                    .first { $0.uuid == messwert } as? CBMutableCharacteristic
            }
            ausWiederanlauf = messwertMerkmal != nil
        }
    }

    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in
            switch peripheral.state {
            case .poweredOn:
                hinweis = nil
                if ausWiederanlauf {
                    funkt = true
                    if !peripheral.isAdvertising { werben(peripheral) }
                } else {
                    dienstVeroeffentlichen(peripheral)
                }
            case .poweredOff:
                funkt = false
                hinweis = "Bluetooth ist aus"
            case .unauthorized:
                funkt = false
                hinweis = "Bluetooth nicht erlaubt"
            case .unsupported:
                funkt = false
                hinweis = "Bluetooth nicht verfügbar"
            default:
                funkt = false
            }
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       didAdd service: CBService,
                                       error: Error?) {
        Task { @MainActor in
            if let error {
                hinweis = "Dienst abgelehnt: \(error.localizedDescription)"
                return
            }
            werben(peripheral)
        }
    }

    nonisolated func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager,
                                                          error: Error?) {
        Task { @MainActor in
            if let error {
                funkt = false
                hinweis = "Senden abgelehnt: \(error.localizedDescription)"
            } else {
                funkt = true
                hinweis = nil
            }
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       central: CBCentral,
                                       didSubscribeTo characteristic: CBCharacteristic) {
        Task { @MainActor in zuhoerer = messwertMerkmal?.subscribedCentrals?.count ?? 0 }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       central: CBCentral,
                                       didUnsubscribeFrom characteristic: CBCharacteristic) {
        Task { @MainActor in zuhoerer = messwertMerkmal?.subscribedCentrals?.count ?? 0 }
    }
}

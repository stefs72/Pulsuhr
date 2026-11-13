//
//  PulsSender.swift
//  Pulsuhr
//
//  Funkt den Puls als **Standard-Pulsgurt**: Bluetooth-Dienst „Heart Rate" (0x180D).
//  Damit muss die Gegenstelle nichts über uns wissen — MyWhoosh, Zwift und alles andere
//  sucht genau diesen Dienst und sieht die Uhr wie einen Brustgurt.
//
//  Warum das auf der Uhr überhaupt geht: `CBPeripheralManager` ist im watchOS-SDK vorhanden
//  (geprüft am 13.11.2026 im Stub der WatchOS27.2.sdk). Die Uhr darf also selbst als
//  Peripheral auftreten, nicht nur als Zentrale.
//

import Foundation
import CoreBluetooth

@MainActor
final class PulsSender: NSObject, ObservableObject {

    /// Wie viele Gegenstellen gerade zuhören (0 = niemand verbunden).
    @Published private(set) var zuhoerer = 0
    /// Funkt die Uhr gerade? (Bluetooth an, Dienst veröffentlicht, Werbung läuft.)
    @Published private(set) var funkt = false
    /// Klartext für die Anzeige, wenn etwas im Weg steht (Bluetooth aus, keine Erlaubnis …).
    @Published private(set) var hinweis: String?

    // Die Kennungen sind von der Bluetooth-SIG vergeben und nicht verhandelbar.
    private let dienst = CBUUID(string: "180D")        // Heart Rate Service
    private let messwert = CBUUID(string: "2A37")      // Heart Rate Measurement
    private let ort = CBUUID(string: "2A38")           // Body Sensor Location

    private var manager: CBPeripheralManager?
    private var messwertMerkmal: CBMutableCharacteristic?
    /// Letzter Wert, der nicht durchging — die Warteschlange war voll. Wird nachgereicht,
    /// sobald CoreBluetooth wieder bereit meldet. Ohne das bliebe die Anzeige stehen.
    private var liegengeblieben: Data?

    func start() {
        guard manager == nil else { return }
        // Eigene Queue wäre schneller, aber hier zählt Einfachheit: ein Wert pro Sekunde
        // ist für den Hauptthread nichts.
        manager = CBPeripheralManager(delegate: self, queue: .main)
    }

    func stop() {
        manager?.stopAdvertising()
        manager?.removeAllServices()
        manager = nil
        messwertMerkmal = nil
        liegengeblieben = nil
        zuhoerer = 0
        funkt = false
    }

    /// Einen Pulswert senden.
    ///
    /// Format nach Bluetooth-Spezifikation: erstes Byte sind Flags, zweites der Wert.
    /// Flag-Bit 0 = 0 heisst „Puls passt in ein Byte" — bis 255 Schläge, das reicht.
    func sende(_ bpm: Int) {
        guard let merkmal = messwertMerkmal, let manager, zuhoerer > 0 else { return }
        let wert = Data([0x00, UInt8(clamping: bpm)])
        if !manager.updateValue(wert, for: merkmal, onSubscribedCentrals: nil) {
            liegengeblieben = wert
        }
    }
}

extension PulsSender: CBPeripheralManagerDelegate {

    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in
            switch peripheral.state {
            case .poweredOn:
                hinweis = nil
                dienstVeroeffentlichen(peripheral)
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

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       didAdd service: CBService,
                                       error: Error?) {
        Task { @MainActor in
            if let error {
                hinweis = "Dienst abgelehnt: \(error.localizedDescription)"
                return
            }
            // Die Dienstkennung MUSS in der Werbung stehen, sonst findet die Gegenstelle
            // uns beim Suchen nach Pulsgurten nicht — sie filtert genau danach.
            peripheral.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: [dienst],
                CBAdvertisementDataLocalNameKey: "Pulsuhr",
            ])
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
        Task { @MainActor in zuhoerer += 1 }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager,
                                       central: CBCentral,
                                       didUnsubscribeFrom characteristic: CBCharacteristic) {
        Task { @MainActor in zuhoerer = max(0, zuhoerer - 1) }
    }

    nonisolated func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        Task { @MainActor in
            guard let wert = liegengeblieben, let merkmal = messwertMerkmal else { return }
            if peripheral.updateValue(wert, for: merkmal, onSubscribedCentrals: nil) {
                liegengeblieben = nil
            }
        }
    }
}

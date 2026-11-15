//
//  PulsQuelle.swift
//  Pulsuhr
//
//  Liefert den Puls fortlaufend — und das geht auf der Uhr NUR mit einer laufenden
//  Trainingseinheit. Ohne sie misst die Uhr im Ruhezustand nur alle paar Minuten; es gäbe
//  schlicht nichts zu senden. Die Session ist also kein Trick für Rechenzeit, sie schaltet
//  den Sensor auf Dauermessung.
//
//  **Nichts landet in Health.** Die Einheit wird am Ende verworfen (`discardWorkout`), nie
//  gesichert. Dasselbe Muster läuft seit 1.5 in FlyMagic Hike (`WatchWorkout.swift`).
//  Wer hier `finishWorkout` einbaut, verfälscht Stefans Ringe und Statistiken.
//

import Foundation
import HealthKit

@MainActor
final class PulsQuelle: NSObject, ObservableObject {

    /// Letzter gemessener Puls in Schlägen pro Minute (nil = noch keiner).
    @Published private(set) var puls: Int?
    /// Läuft die Messung?
    @Published private(set) var laeuft = false
    /// Klartext, wenn etwas im Weg steht.
    @Published private(set) var hinweis: String?

    /// Wird bei jedem neuen Wert gerufen — hier hängt der Sender dran.
    var beiNeuemWert: ((Int) -> Void)?

    private let speicher = HKHealthStore()
    private var session: HKWorkoutSession?
    private var sammler: HKLiveWorkoutBuilder?

    private let pulsTyp = HKQuantityType(.heartRate)
    private let einheit = HKUnit.count().unitDivided(by: .minute())

    /// Soll gemessen werden? Bleibt `true`, bis jemand „Beenden" drückt.
    ///
    /// Nicht dasselbe wie `laeuft`: Räumt watchOS die Trainingseinheit ab, ist `laeuft`
    /// falsch, obwohl der Benutzer weitermessen will. Genau dann fahren wir wieder hoch.
    private var gewollt = false

    func start() async {
        gewollt = true
        guard !laeuft else { return }
        guard HKHealthStore.isHealthDataAvailable() else {
            hinweis = "HealthKit nicht verfügbar"; return
        }

        // Lesen reicht für den Puls; die Schreib-Erlaubnis für „Workout" braucht es, um die
        // Einheit überhaupt starten zu dürfen — gespeichert wird trotzdem nichts.
        do {
            try await speicher.requestAuthorization(toShare: [HKQuantityType.workoutType()],
                                                    read: [pulsTyp])
        } catch {
            hinweis = "Keine Health-Erlaubnis"; return
        }

        let konfiguration = HKWorkoutConfiguration()
        // Radfahren drinnen: Das ist der Fall, für den die App gebaut ist (MyWhoosh am Mac).
        // Der Typ ist kein Etikett, er entscheidet mit, welche Sensor-Algorithmen laufen.
        konfiguration.activityType = .cycling
        konfiguration.locationType = .indoor

        do {
            let s = try HKWorkoutSession(healthStore: speicher, configuration: konfiguration)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: speicher,
                                                   workoutConfiguration: konfiguration)
            b.delegate = self
            // Ohne diese Zeile erfahren wir NIE, dass die Einheit beendet wurde oder
            // gescheitert ist: Die Anzeige behielte ihre letzte Zahl, die Uhr schickte
            // nichts mehr, und niemand merkte es. Sie hat bis jetzt gefehlt.
            s.delegate = self
            session = s
            sammler = b

            let jetzt = Date()
            s.startActivity(with: jetzt)
            try await b.beginCollection(at: jetzt)
            laeuft = true
            hinweis = nil
        } catch {
            hinweis = "Start fehlgeschlagen: \(error.localizedDescription)"
            session = nil
            sammler = nil
        }
    }

    func stop() {
        gewollt = false
        guard let s = session, let b = sammler else { return }
        session = nil
        sammler = nil
        laeuft = false
        puls = nil

        s.end()
        Task {
            // Erst die Sammlung schliessen, dann WEGWERFEN. Kein `finishWorkout` — genau
            // hier entscheidet sich, ob ein Pseudo-Training in Health landet.
            try? await b.endCollection(at: Date())
            b.discardWorkout()
        }
    }

    /// Die Einheit ist weg, ohne dass wir sie beendet hätten.
    ///
    /// Das kommt vor: watchOS räumt Trainingseinheiten ab, wenn ihm die Ressourcen knapp
    /// werden, und ein Fehler im Sensor beendet sie ebenfalls. Vorher blieb die App dann
    /// stumm stehen — Knopf auf „Beenden", Zahl eingefroren, nichts ging mehr ans iPhone.
    /// Jetzt fährt sie von selbst wieder hoch, solange der Benutzer nicht gestoppt hat.
    private func verloren(_ grund: String?) async {
        guard laeuft else { return }        // unser eigenes `stop()` hat das schon erledigt
        laeuft = false
        session = nil
        sammler = nil
        puls = nil
        hinweis = grund

        guard gewollt else { return }
        try? await Task.sleep(for: .seconds(2))
        guard gewollt, !laeuft else { return }
        await start()
    }
}

extension PulsQuelle: HKLiveWorkoutBuilderDelegate {

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        guard collectedTypes.contains(where: { $0 == HKQuantityType(.heartRate) }) else { return }
        // Der Statistikwert ist der zuletzt gemessene — nicht der Durchschnitt.
        let wert = workoutBuilder.statistics(for: HKQuantityType(.heartRate))?
            .mostRecentQuantity()?
            .doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        guard let wert else { return }
        Task { @MainActor in
            let bpm = Int(wert.rounded())
            puls = bpm
            beiNeuemWert?(bpm)
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

extension PulsQuelle: HKWorkoutSessionDelegate {

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        guard toState == .ended || toState == .stopped else { return }
        Task { @MainActor in await verloren(nil) }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didFailWithError error: Error) {
        Task { @MainActor in await verloren("Messung abgebrochen – versuche es erneut") }
    }
}

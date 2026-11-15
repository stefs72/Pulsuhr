//
//  WatchAnsicht.swift
//  Pulsuhr Watch
//
//  Eine Zahl und ein Knopf. Die Messung startet beim Öffnen von selbst — manuell starten
//  muss man sie ohnehin (watchOS lässt keine stille Dauermessung zu), ein zweiter Tipp im
//  Inneren wäre einer zu viel.
//

import SwiftUI

struct WatchAnsicht: View {
    @StateObject private var quelle = PulsQuelle()
    private let funk = Funk()

    var body: some View {
        VStack(spacing: 4) {
            // Messwert in EINEM Text mit fester Zeile: eine zusammengesetzte Anzeige kann
            // mitten in der Zahl umbrechen.
            Text(quelle.puls.map(String.init) ?? "--")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(quelle.puls == nil ? .secondary : .primary)

            Text("bpm")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let hinweis = quelle.hinweis {
                Text(hinweis)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }

            Button(quelle.laeuft ? "Beenden" : "Starten") {
                Task {
                    if quelle.laeuft {
                        quelle.stop()
                        funk.sendeStop()      // sonst steht die Zahl auf dem iPhone weiter
                    } else {
                        await quelle.start()
                    }
                }
            }
            .font(.caption)
            .tint(quelle.laeuft ? .red : .green)
            .padding(.top, 4)
        }
        .task {
            quelle.beiNeuemWert = { funk.sende($0) }
            quelle.beiEnde = { funk.sendeStop() }
            await quelle.start()
        }
        // Kein Stop beim Verschwinden: Die Uhr soll weitermessen, wenn der Arm sinkt und der
        // Bildschirm ausgeht. Schluss ist über den Knopf.
    }
}

//
//  Ansicht.swift
//  Pulsuhr
//
//  Zeigt, was gerade durchgeht. Bedienen muss man hier nichts — die App gibt frei, solange
//  sie offen ist.
//

import SwiftUI

struct Ansicht: View {
    @StateObject private var bruecke = Bruecke()

    var body: some View {
        VStack(spacing: 10) {
            Text(bruecke.puls.map(String.init) ?? "--")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(bruecke.puls == nil ? .secondary : .primary)

            Text("bpm")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Circle()
                    .fill(bruecke.verbunden ? .green : (bruecke.funkt ? .orange : .gray))
                    .frame(width: 10, height: 10)
                Text(bruecke.zustand)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            Text("Starte die Messung auf der Uhr. Das iPhone muss offen bleiben.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .padding(.horizontal, 24)
        }
        .onAppear { bruecke.start() }
    }
}

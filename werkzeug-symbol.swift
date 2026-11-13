// App-Symbol: Gesicht, bei dem die EKG-Linie der Mund ist — und zwar ein lachender.
//
// Aufruf: swift werkzeug-symbol.swift <ziel.png>
// Ergebnis in beide Kataloge kopieren:
//   Pulsuhr/Assets.xcassets/AppIcon.appiconset/icon-1024.png
//   Pulsuhr Watch/Assets.xcassets/AppIcon.appiconset/icon-1024.png

import Foundation
import CoreGraphics
import ImageIO

let size = 1024
let w = CGFloat(size)
let raum = CGColorSpaceCreateDeviceRGB()

// Ohne Alpha-Kanal: App-Store-Symbole dürfen keinen haben, und zu sehen gäbe es ohnehin
// nichts — der Verlauf füllt die ganze Fläche.
guard let ctx = CGContext(data: nil, width: size, height: size,
                          bitsPerComponent: 8, bytesPerRow: 0, space: raum,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
    fatalError("Kein Zeichenkontext")
}

let farben = [
    CGColor(red: 0.84, green: 0.16, blue: 0.24, alpha: 1),
    CGColor(red: 0.45, green: 0.05, blue: 0.13, alpha: 1),
] as CFArray
if let verlauf = CGGradient(colorsSpace: raum, colors: farben, locations: [0, 1]) {
    ctx.drawLinearGradient(verlauf, start: CGPoint(x: 0, y: w), end: CGPoint(x: 0, y: 0), options: [])
}

let weiss = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
let schatten = CGColor(red: 0, green: 0, blue: 0, alpha: 0.22)

// Augen. Alles bleibt innerhalb des einbeschriebenen Kreises — watchOS beschneidet rund.
func auge(x: CGFloat, y: CGFloat, r: CGFloat, farbe: CGColor) {
    ctx.setFillColor(farbe)
    ctx.fillEllipse(in: CGRect(x: x * w - r * w, y: y * w - r * w, width: 2 * r * w, height: 2 * r * w))
}

// Der Mund als EKG-Form: flach, ein Ausschlag, flach.
let roh: [(CGFloat, CGFloat)] = [
    (0.190, 0.370),
    (0.330, 0.370),
    (0.385, 0.455),
    (0.455, 0.240),
    (0.525, 0.490),
    (0.585, 0.370),
    (0.810, 0.370),
]

// Das Lachen: eine Parabel, die an den Mundwinkeln steigt. Der Ausschlag bleibt unangetastet
// und reitet auf der Kurve mit — so bleibt die Herzkurve lesbar, und der Mund lacht trotzdem.
let halb: CGFloat = 0.31                       // halbe Mundbreite
let hub: CGFloat = 0.9 * 0.075                 // wie hoch die Mundwinkel steigen
func biegung(_ x: CGFloat) -> CGFloat {
    let d = (x - 0.5) / halb
    return hub * d * d - hub / 2               // halb nach unten geschoben, damit der Mund mittig bleibt
}

// Die waagrechten Stücke dicht abtasten, sonst liefen sie als gerade Sehne über die Kurve.
func abtasten(_ punkte: [(CGFloat, CGFloat)]) -> [(CGFloat, CGFloat)] {
    var aus: [(CGFloat, CGFloat)] = []
    for i in 0 ..< punkte.count - 1 {
        let a = punkte[i], b = punkte[i + 1]
        let flach = abs(a.1 - b.1) < 0.001
        let schritte = flach ? max(2, Int((b.0 - a.0) / 0.012)) : 1
        for s in 0 ..< schritte {
            let t = CGFloat(s) / CGFloat(schritte)
            aus.append((a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t))
        }
    }
    aus.append(punkte.last!)
    return aus
}

let mund = abtasten(roh).map { ($0.0, $0.1 + biegung($0.0)) }

func linie(punkte: [(CGFloat, CGFloat)], versatz: CGFloat, farbe: CGColor, breite: CGFloat) {
    ctx.setStrokeColor(farbe)
    ctx.setLineWidth(w * breite)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.beginPath()
    for (i, p) in punkte.enumerated() {
        let pt = CGPoint(x: p.0 * w, y: p.1 * w - versatz)
        if i == 0 { ctx.move(to: pt) } else { ctx.addLine(to: pt) }
    }
    ctx.strokePath()
}

let augenY: CGFloat = 0.640
let augenR: CGFloat = 0.086

auge(x: 0.355, y: augenY - 0.016, r: augenR, farbe: schatten)
auge(x: 0.645, y: augenY - 0.016, r: augenR, farbe: schatten)
auge(x: 0.355, y: augenY, r: augenR, farbe: weiss)
auge(x: 0.645, y: augenY, r: augenR, farbe: weiss)

linie(punkte: mund, versatz: w * 0.016, farbe: schatten, breite: 0.062)
linie(punkte: mund, versatz: 0, farbe: weiss, breite: 0.060)

guard let bild = ctx.makeImage() else { fatalError("Kein Bild") }
let ziel = URL(fileURLWithPath: CommandLine.arguments[1])
guard let schreiber = CGImageDestinationCreateWithURL(ziel as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("Kein Schreiber")
}
CGImageDestinationAddImage(schreiber, bild, nil)
CGImageDestinationFinalize(schreiber)
print("geschrieben:", ziel.lastPathComponent)

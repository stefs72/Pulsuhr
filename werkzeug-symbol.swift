// App-Symbol: Gesicht, bei dem die EKG-Linie der Mund ist.
// Aufruf: swift gesicht.swift <ziel.png>

import Foundation
import CoreGraphics
import ImageIO

let size = 1024
let w = CGFloat(size)
let raum = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: size, height: size,
                          bitsPerComponent: 8, bytesPerRow: 0, space: raum,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("Kein Zeichenkontext")
}

// Hintergrund wie gehabt.
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

// Mund: dieselbe EKG-Form wie bisher, nur schmaler und tiefer gesetzt.
let mund: [(CGFloat, CGFloat)] = [
    (0.190, 0.370),
    (0.330, 0.370),
    (0.385, 0.455),
    (0.455, 0.240),
    (0.525, 0.490),
    (0.585, 0.370),
    (0.810, 0.370),
]

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

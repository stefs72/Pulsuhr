import AppKit
let a = CommandLine.arguments
let quelle = NSImage(contentsOfFile: a[1])!
let ziel = a[2]
let mitTitel = a[3] == "titel"
let W = 1290, H = 2796
// Kein Alpha-Kanal (noneSkipLast), wie beim App-Symbol.
let cg = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: false)
NSGraphicsContext.current!.imageInterpolation = .high
NSColor.black.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
if !mitTitel {
    quelle.draw(in: NSRect(x: 0, y: 0, width: W, height: H))
} else {
    let mitte = NSMutableParagraphStyle(); mitte.alignment = .center
    func text(_ s: String, _ f: NSFont, _ c: NSColor, _ y: CGFloat) {
        (s as NSString).draw(in: NSRect(x: 60, y: y, width: CGFloat(W) - 120, height: 200),
            withAttributes: [.font: f, .foregroundColor: c, .paragraphStyle: mitte])
    }
    text("Apple Watch als Pulsgurt", .systemFont(ofSize: 92, weight: .bold), .white, CGFloat(H) - 290)
    text("Für Zwift, MyWhoosh und jeden Bluetooth-Empfänger", .systemFont(ofSize: 46, weight: .medium),
         NSColor(white: 0.65, alpha: 1), CGFloat(H) - 420)
    // Bild ohne Hochskalieren: Quelle ist 960 px breit
    let bw: CGFloat = 1060, bh = bw * quelle.size.height / quelle.size.width
    let r = NSRect(x: (CGFloat(W) - bw) / 2, y: 60, width: bw, height: bh)
    let pfad = NSBezierPath(roundedRect: r, xRadius: 70, yRadius: 70)
    NSColor(white: 0.28, alpha: 1).setStroke(); pfad.lineWidth = 6
    NSGraphicsContext.saveGraphicsState(); pfad.addClip(); quelle.draw(in: r); NSGraphicsContext.restoreGraphicsState()
    pfad.stroke()
}
NSGraphicsContext.restoreGraphicsState()
let rep = NSBitmapImageRep(cgImage: cg.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: ziel))

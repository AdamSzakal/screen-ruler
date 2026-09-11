#!/usr/bin/env swift
//
// Draws the app icon. build.sh makes AppIcon.icns from the result.
//
//   swift Tools/MakeArtwork.swift docs
//
import AppKit

func srgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

func makeRep(width: CGFloat, height: CGFloat, scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                               pixelsWide: Int(width * scale),
                               pixelsHigh: Int(height * scale),
                               bitsPerSample: 8,
                               samplesPerPixel: 4,
                               hasAlpha: true,
                               isPlanar: false,
                               colorSpaceName: .deviceRGB,
                               bytesPerRow: 0,
                               bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    return rep
}

func draw(into rep: NSBitmapImageRep, _ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    body()
    NSGraphicsContext.current?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
}

func save(_ rep: NSBitmapImageRep, to path: String) {
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)  \(rep.pixelsWide)×\(rep.pixelsHigh)")
}

func rounded(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

/// A dark square with the bright slit of the app across it, and the ticks of
/// a ruler below the slit.
func makeIcon(path: String, size: CGFloat = 1024) {
    let rep = makeRep(width: size, height: size, scale: 1)
    draw(into: rep) {
        let unit = size / 1024
        let body = NSRect(x: 92 * unit, y: 92 * unit, width: 840 * unit, height: 840 * unit)
        NSGradient(starting: srgb(0x0C0E13), ending: srgb(0x242A38))!
            .draw(in: rounded(body, 188 * unit), angle: 90)

        NSGraphicsContext.saveGraphicsState()
        rounded(body, 188 * unit).setClip()

        let slit = NSRect(x: body.minX, y: body.midY - 96 * unit, width: body.width, height: 192 * unit)
        let beam = NSGradient(colors: [srgb(0xFFC36B, 0), srgb(0xFFD79A, 0.95), srgb(0xFFFFFF, 1),
                                       srgb(0xFFD79A, 0.95), srgb(0xFFC36B, 0)],
                              atLocations: [0, 0.28, 0.5, 0.72, 1], colorSpace: .sRGB)!
        beam.draw(in: slit, angle: 90)

        srgb(0x14171E, 0.85).setStroke()
        let ticks = NSBezierPath()
        ticks.lineWidth = 14 * unit
        ticks.lineCapStyle = .round
        for step in 1...7 {
            let x = body.minX + body.width * CGFloat(step) / 8
            let long = step % 2 == 1
            ticks.move(to: NSPoint(x: x, y: slit.minY + 20 * unit))
            ticks.line(to: NSPoint(x: x, y: slit.minY + (long ? 74 : 46) * unit))
        }
        ticks.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }
    save(rep, to: path)
}

let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"
makeIcon(path: "\(outputDirectory)/icon.png")

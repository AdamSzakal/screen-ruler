#!/usr/bin/env swift
//
// Makes the pictures of the project: the app icon and the hero picture of the
// README. The hero picture is a drawing of the effect, not a screen capture.
//
//   swift Tools/MakeArtwork.swift docs
//
import AppKit

// MARK: - Palette

func srgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

enum Palette {
    static let backdropTop = srgb(0x191D26)
    static let backdropBottom = srgb(0x0B0D12)
    static let glow = srgb(0xFFC36B, 0.16)
    static let paper = srgb(0xF7F6F3)
    static let menuBar = srgb(0xE9E8E4)
    static let bodyBar = srgb(0x33322C)
    static let headingBar = srgb(0x131210)
    static let accent = srgb(0xFFC36B)
    static let menuBackground = srgb(0x2C2C2E, 0.97)
    static let menuLine = srgb(0xFFFFFF, 0.12)
    static let menuText = srgb(0xF2F2F2)
    static let menuDimText = srgb(0xFFFFFF, 0.5)
}

// MARK: - Drawing helpers

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

func fill(_ rect: NSRect, _ color: NSColor, radius: CGFloat = 0) {
    color.setFill()
    if radius > 0 { rounded(rect, radius).fill() } else { rect.fill() }
}

func linearGradient(_ rect: NSRect, from: NSColor, to: NSColor, angle: CGFloat = 90, radius: CGFloat = 0) {
    let gradient = NSGradient(starting: from, ending: to)!
    if radius > 0 {
        gradient.draw(in: rounded(rect, radius), angle: angle)
    } else {
        gradient.draw(in: rect, angle: angle)
    }
}

func write(_ string: String,
           at point: NSPoint,
           font: NSFont,
           color: NSColor,
           width: CGFloat? = nil,
           align: NSTextAlignment = .left) {
    let style = NSMutableParagraphStyle()
    style.alignment = align
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
    if let width {
        let rect = NSRect(x: point.x, y: point.y, width: width, height: font.pointSize * 1.6)
        (string as NSString).draw(in: rect, withAttributes: attributes)
    } else {
        (string as NSString).draw(at: point, withAttributes: attributes)
    }
}

/// The dim of the app: dark above and below the slit, with a soft edge.
func drawDim(in area: NSRect, slitCenterY: CGFloat, slitHeight: CGFloat, feather: CGFloat, opacity: CGFloat) {
    let solid = NSColor.black.withAlphaComponent(opacity)
    let clear = NSColor.black.withAlphaComponent(0)
    let slitBottom = slitCenterY - slitHeight / 2
    let slitTop = slitCenterY + slitHeight / 2

    let top = NSRect(x: area.minX, y: slitTop, width: area.width, height: area.maxY - slitTop)
    let bottom = NSRect(x: area.minX, y: area.minY, width: area.width, height: slitBottom - area.minY)

    for (rect, solidAtTop) in [(top, true), (bottom, false)] where rect.height > 0 {
        let fade = min(feather / rect.height, 0.5)
        let gradient = NSGradient(colors: [solid, solid, clear],
                                  atLocations: [0, 1 - fade, 1],
                                  colorSpace: .sRGB)!
        // Angle 270 starts at the top edge of the rectangle, 90 at the bottom.
        gradient.draw(in: rect, angle: solidAtTop ? 270 : 90)
    }
}

/// The pointer of macOS, in the middle of the slit.
func drawCursor(at point: NSPoint, scale: CGFloat = 1) {
    let path = NSBezierPath()
    let outline: [(CGFloat, CGFloat)] = [(0, 0), (0, -20), (4.6, -15.6), (7.4, -21.4),
                                         (10.8, -19.8), (8, -14.2), (14, -13.6)]
    path.move(to: point)
    for (dx, dy) in outline.dropFirst() {
        path.line(to: NSPoint(x: point.x + dx * scale, y: point.y + dy * scale))
    }
    path.close()

    NSColor.black.withAlphaComponent(0.35).setStroke()
    path.lineWidth = 3 * scale
    path.stroke()
    NSColor.white.setFill()
    path.fill()
    NSColor.black.withAlphaComponent(0.8).setStroke()
    path.lineWidth = 1 * scale
    path.stroke()
}

/// The icon of the app in the menu bar: a line between two short ticks.
func drawRulerGlyph(in rect: NSRect, color: NSColor) {
    color.setStroke()
    let line = NSBezierPath()
    line.lineWidth = max(1, rect.height * 0.1)
    line.move(to: NSPoint(x: rect.minX, y: rect.midY))
    line.line(to: NSPoint(x: rect.maxX, y: rect.midY))
    line.stroke()

    let tick = NSBezierPath()
    tick.lineWidth = line.lineWidth
    for fraction in [0.18, 0.5, 0.82] {
        let x = rect.minX + rect.width * CGFloat(fraction)
        tick.move(to: NSPoint(x: x, y: rect.midY))
        tick.line(to: NSPoint(x: x, y: rect.midY + rect.height * 0.3))
    }
    tick.stroke()
}

// MARK: - The page below the ruler

/// Bars that stand for the lines of a document. Abstract bars are used, so
/// that the picture shows the effect and not invented text.
func drawDocument(in area: NSRect) {
    let left = area.minX + 96
    let columnWidth = area.width - 192
    var y = area.maxY - 78

    func bar(width: CGFloat, height: CGFloat, color: NSColor) {
        fill(NSRect(x: left, y: y - height, width: width, height: height), color, radius: height / 2)
        y -= height + 15
    }

    bar(width: columnWidth * 0.52, height: 22, color: Palette.headingBar)
    y -= 16

    let paragraphs: [[CGFloat]] = [
        [1.00, 0.96, 0.99, 0.62],
        [1.00, 0.93, 0.97, 1.00, 0.71],
        [0.98, 1.00, 0.89, 0.94, 0.45],
        [1.00, 0.95, 0.99, 0.83],
    ]
    for paragraph in paragraphs {
        for fraction in paragraph {
            bar(width: columnWidth * fraction, height: 13, color: Palette.bodyBar)
        }
        y -= 22
    }
}

/// The menu bar at the top of the screen, with the icon of the app.
func drawMenuBar(in rect: NSRect, iconCenterX: CGFloat) {
    fill(rect, Palette.menuBar)
    fill(NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: 1), srgb(0x000000, 0.08))

    let dark = srgb(0x3A3A3C)
    write("\u{F8FF}", at: NSPoint(x: rect.minX + 20, y: rect.midY - 9), font: .systemFont(ofSize: 15), color: dark)
    for (offset, title) in [(46, "Finder"), (108, "File"), (150, "Edit"), (192, "View")] {
        let font = title == "Finder" ? NSFont.boldSystemFont(ofSize: 13) : NSFont.systemFont(ofSize: 13)
        write(title, at: NSPoint(x: rect.minX + CGFloat(offset), y: rect.midY - 8), font: font, color: dark)
    }

    // The icon of the app, with the grey box that macOS shows for an open menu.
    let iconBox = NSRect(x: iconCenterX - 17, y: rect.minY + 2, width: 34, height: rect.height - 4)
    fill(iconBox, srgb(0x000000, 0.10), radius: 5)
    drawRulerGlyph(in: NSRect(x: iconCenterX - 9, y: rect.midY - 7, width: 18, height: 14), color: dark)

    write("100%", at: NSPoint(x: rect.maxX - 150, y: rect.midY - 8), font: .systemFont(ofSize: 12), color: dark)
    write("Fri 12:41", at: NSPoint(x: rect.maxX - 92, y: rect.midY - 8), font: .systemFont(ofSize: 12), color: dark)
}

// MARK: - The menu of the app

func drawMenu(at origin: NSPoint, width: CGFloat) -> NSRect {
    let rows = 11
    let height: CGFloat = 356
    let frame = NSRect(x: origin.x, y: origin.y - height, width: width, height: height)
    _ = rows

    NSColor.black.withAlphaComponent(0.45).setFill()
    rounded(frame.offsetBy(dx: 0, dy: -6).insetBy(dx: -10, dy: -10), 22).fill()
    fill(frame, Palette.menuBackground, radius: 11)
    srgb(0xFFFFFF, 0.09).setStroke()
    rounded(frame.insetBy(dx: 0.5, dy: 0.5), 11).stroke()

    let left = frame.minX + 14
    let right = frame.maxX - 14
    var y = frame.maxY - 26

    func line() {
        fill(NSRect(x: frame.minX + 10, y: y + 8, width: frame.width - 20, height: 1), Palette.menuLine)
        y -= 10
    }

    write("Screen Ruler 1.0.0", at: NSPoint(x: left, y: y), font: .boldSystemFont(ofSize: 13), color: Palette.menuText)
    y -= 19
    write("On — 1 screen dimmed", at: NSPoint(x: left, y: y), font: .systemFont(ofSize: 11), color: Palette.menuDimText)
    y -= 22
    line()

    write("Switch Ruler Off", at: NSPoint(x: left, y: y), font: .systemFont(ofSize: 13), color: Palette.menuText)
    write("⌃⌥⌘R", at: NSPoint(x: left, y: y), font: .systemFont(ofSize: 13), color: Palette.menuDimText,
          width: right - left, align: .right)
    y -= 26
    line()

    // The three sliders of the menu.
    for (title, value, fraction) in [("Slit height", "96 px", 0.31),
                                     ("Dim amount", "62 %", 0.62),
                                     ("Edge softness", "16 px", 0.20)] {
        write(title, at: NSPoint(x: left, y: y), font: .systemFont(ofSize: 12), color: Palette.menuText)
        write(value, at: NSPoint(x: left, y: y + 1), font: .monospacedDigitSystemFont(ofSize: 11, weight: .regular),
              color: Palette.menuDimText, width: right - left, align: .right)
        y -= 18

        let track = NSRect(x: left, y: y + 4, width: right - left, height: 4)
        fill(track, srgb(0xFFFFFF, 0.18), radius: 2)
        fill(NSRect(x: track.minX, y: track.minY, width: track.width * CGFloat(fraction), height: track.height),
             Palette.accent, radius: 2)
        let knob = NSRect(x: track.minX + track.width * CGFloat(fraction) - 7, y: track.midY - 7, width: 14, height: 14)
        NSColor.black.withAlphaComponent(0.35).setFill()
        NSBezierPath(ovalIn: knob.offsetBy(dx: 0, dy: -1)).fill()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: knob).fill()
        y -= 24
    }
    line()

    for hint in ["⌃⌥⌘,  ⌃⌥⌘.   change the slit height", "Height Shortcut  ▸"] {
        write(hint, at: NSPoint(x: left, y: y), font: .systemFont(ofSize: 11), color: Palette.menuDimText)
        y -= 20
    }
    line()

    for (title, key) in [("Open at Login", ""), ("Quit Screen Ruler", "⌘Q")] {
        write(title, at: NSPoint(x: left, y: y), font: .systemFont(ofSize: 13), color: Palette.menuText)
        if !key.isEmpty {
            write(key, at: NSPoint(x: left, y: y), font: .systemFont(ofSize: 13), color: Palette.menuDimText,
                  width: right - left, align: .right)
        }
        y -= 22
    }
    return frame
}

// MARK: - Hero picture

func makeHero(path: String) {
    let size = NSSize(width: 1280, height: 800)
    let rep = makeRep(width: size.width, height: size.height, scale: 1.6)

    draw(into: rep) {
        let full = NSRect(origin: .zero, size: size)
        linearGradient(full, from: Palette.backdropBottom, to: Palette.backdropTop)

        let card = NSRect(x: 64, y: 72, width: size.width - 128, height: size.height - 144)
        let slitCenterY = card.minY + card.height * 0.46
        let slitHeight: CGFloat = 84

        // A warm glow behind the card, in the height of the slit.
        let glow = NSGradient(colors: [Palette.glow, srgb(0xFFC36B, 0)], atLocations: [0, 1], colorSpace: .sRGB)!
        glow.draw(in: NSRect(x: 0, y: slitCenterY - 260, width: size.width, height: 520), relativeCenterPosition: .zero)

        // Shadow of the card.
        NSColor.black.withAlphaComponent(0.55).setFill()
        rounded(card.insetBy(dx: -1, dy: -1).offsetBy(dx: 0, dy: -14), 22).fill()

        NSGraphicsContext.saveGraphicsState()
        rounded(card, 20).setClip()

        fill(card, Palette.paper)
        let menuBarRect = NSRect(x: card.minX, y: card.maxY - 32, width: card.width, height: 32)
        let iconCenterX = card.maxX - 232
        drawDocument(in: NSRect(x: card.minX, y: card.minY, width: card.width, height: card.height - 32))
        drawMenuBar(in: menuBarRect, iconCenterX: iconCenterX)

        drawDim(in: card, slitCenterY: slitCenterY, slitHeight: slitHeight, feather: 12, opacity: 0.68)
        drawCursor(at: NSPoint(x: card.minX + card.width * 0.63, y: slitCenterY + 8), scale: 1.6)

        // The menu stays bright: the app puts the dim below the menus while
        // the menu is open.
        _ = drawMenu(at: NSPoint(x: iconCenterX - 118, y: menuBarRect.minY - 6), width: 250)

        NSGraphicsContext.restoreGraphicsState()
        srgb(0xFFFFFF, 0.10).setStroke()
        rounded(card.insetBy(dx: 0.5, dy: 0.5), 20).stroke()
    }
    save(rep, to: path)
}

// MARK: - App icon

func makeIcon(path: String, size: CGFloat = 1024) {
    let rep = makeRep(width: size, height: size, scale: 1)
    draw(into: rep) {
        let unit = size / 1024
        let body = NSRect(x: 92 * unit, y: 92 * unit, width: 840 * unit, height: 840 * unit)

        linearGradient(body, from: srgb(0x0C0E13), to: srgb(0x242A38), angle: 90, radius: 188 * unit)

        NSGraphicsContext.saveGraphicsState()
        rounded(body, 188 * unit).setClip()

        // The bright slit, with a soft edge above and below.
        let slit = NSRect(x: body.minX, y: body.midY - 96 * unit, width: body.width, height: 192 * unit)
        let beam = NSGradient(colors: [srgb(0xFFC36B, 0), srgb(0xFFD79A, 0.95), srgb(0xFFFFFF, 1),
                                       srgb(0xFFD79A, 0.95), srgb(0xFFC36B, 0)],
                              atLocations: [0, 0.28, 0.5, 0.72, 1], colorSpace: .sRGB)!
        beam.draw(in: slit, angle: 90)

        // Ticks of a ruler along the slit.
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

// MARK: - Run

let outputDirectory = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"
makeHero(path: "\(outputDirectory)/hero.png")
makeIcon(path: "\(outputDirectory)/icon.png")

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsURL = root.appending(path: "Sources/NekoPixelMedic/Resources/Assets.xcassets", directoryHint: .isDirectory)
let iconsetURL = assetsURL.appending(path: "AppIcon.appiconset", directoryHint: .isDirectory)

let iconSpecs: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let masterImage = drawMasterIcon(size: 1024)

for (filename, pixelSize) in iconSpecs {
    let outputURL = iconsetURL.appending(path: filename)
    let pngData = try renderPNG(from: masterImage, pixelSize: pixelSize)
    try pngData.write(to: outputURL, options: .atomic)
}

func drawMasterIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let context = NSGraphicsContext.current?.cgContext
    context?.setShouldAntialias(true)
    context?.interpolationQuality = .high

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)

    NSColor.clear.setFill()
    bounds.fill()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = 44
    shadow.shadowOffset = NSSize(width: 0, height: -20)
    shadow.set()

    let basePath = NSBezierPath(roundedRect: NSRect(x: 56, y: 56, width: 912, height: 912), xRadius: 220, yRadius: 220)
    let baseGradient = makeGradient(
        stops: [
            (color(hex: 0x1B1530), 0.0),
            (color(hex: 0x263A53), 0.38),
            (color(hex: 0xF07A49), 1.0),
        ]
    )
    baseGradient.draw(in: basePath, angle: -52)

    drawGlow(center: CGPoint(x: 238, y: 794), radius: 360, color: color(hex: 0x33D2C1), alpha: 0.22)
    drawGlow(center: CGPoint(x: 782, y: 250), radius: 320, color: color(hex: 0xFFBF73), alpha: 0.26)
    drawGlow(center: CGPoint(x: 760, y: 754), radius: 240, color: color(hex: 0xFF6A74), alpha: 0.12)

    NSGraphicsContext.saveGraphicsState()
    basePath.addClip()

    let photoRect = NSRect(x: 190, y: 156, width: 644, height: 646)
    let photoPanel = NSBezierPath(roundedRect: photoRect, xRadius: 138, yRadius: 138)
    let photoGradient = makeGradient(
        stops: [
            (color(hex: 0xFFF8EE).withAlphaComponent(0.94), 0.0),
            (color(hex: 0xF0E7DB).withAlphaComponent(0.98), 1.0),
        ]
    )
    photoGradient.draw(in: photoPanel, angle: 90)

    let photoStroke = NSBezierPath(roundedRect: photoRect.insetBy(dx: 5, dy: 5), xRadius: 132, yRadius: 132)
    color(hex: 0xFFFFFF).withAlphaComponent(0.30).setStroke()
    photoStroke.lineWidth = 4
    photoStroke.stroke()

    drawPixelStrip()
    drawCatHead()
    drawRepairBadge()
    drawSparkles()

    NSGraphicsContext.restoreGraphicsState()

    let outerStroke = NSBezierPath(roundedRect: NSRect(x: 56, y: 56, width: 912, height: 912), xRadius: 220, yRadius: 220)
    color(hex: 0xFFF7EE).withAlphaComponent(0.14).setStroke()
    outerStroke.lineWidth = 5
    outerStroke.stroke()

    image.unlockFocus()
    return image
}

func drawPixelStrip() {
    let squares: [(CGRect, NSColor)] = [
        (CGRect(x: 174, y: 550, width: 72, height: 72), color(hex: 0xF07A49).withAlphaComponent(0.86)),
        (CGRect(x: 136, y: 484, width: 58, height: 58), color(hex: 0xFFB46B).withAlphaComponent(0.84)),
        (CGRect(x: 228, y: 466, width: 48, height: 48), color(hex: 0x33D2C1).withAlphaComponent(0.72)),
        (CGRect(x: 112, y: 420, width: 42, height: 42), color(hex: 0xFFF2D8).withAlphaComponent(0.92)),
        (CGRect(x: 192, y: 392, width: 34, height: 34), color(hex: 0xF6D7B3).withAlphaComponent(0.78)),
    ]

    for (rect, fillColor) in squares {
        let square = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        fillColor.setFill()
        square.fill()
    }
}

func drawCatHead() {
    let cream = color(hex: 0xFFF5E8)
    let ink = color(hex: 0x2B3040)
    let accent = color(hex: 0xF07A49)

    let faceRect = NSRect(x: 280, y: 230, width: 460, height: 438)
    let facePath = NSBezierPath(ovalIn: faceRect)
    cream.setFill()
    facePath.fill()

    let leftEar = NSBezierPath()
    leftEar.move(to: CGPoint(x: 338, y: 612))
    leftEar.line(to: CGPoint(x: 418, y: 840))
    leftEar.line(to: CGPoint(x: 540, y: 646))
    leftEar.close()
    cream.setFill()
    leftEar.fill()

    let rightEar = NSBezierPath()
    rightEar.move(to: CGPoint(x: 610, y: 646))
    rightEar.line(to: CGPoint(x: 724, y: 836))
    rightEar.line(to: CGPoint(x: 796, y: 604))
    rightEar.close()
    cream.setFill()
    rightEar.fill()

    let leftInnerEar = NSBezierPath()
    leftInnerEar.move(to: CGPoint(x: 402, y: 666))
    leftInnerEar.line(to: CGPoint(x: 446, y: 790))
    leftInnerEar.line(to: CGPoint(x: 518, y: 670))
    leftInnerEar.close()
    accent.withAlphaComponent(0.86).setFill()
    leftInnerEar.fill()

    let rightInnerEar = NSBezierPath()
    rightInnerEar.move(to: CGPoint(x: 640, y: 670))
    rightInnerEar.line(to: CGPoint(x: 706, y: 792))
    rightInnerEar.line(to: CGPoint(x: 756, y: 652))
    rightInnerEar.close()
    accent.withAlphaComponent(0.72).setFill()
    rightInnerEar.fill()

    let faceShade = makeGradient(
        stops: [
            (color(hex: 0xFFFFFF).withAlphaComponent(0.22), 0.0),
            (color(hex: 0xFFFFFF).withAlphaComponent(0.0), 1.0),
        ]
    )
    faceShade.draw(
        fromCenter: CGPoint(x: 500, y: 604),
        radius: 12,
        toCenter: CGPoint(x: 500, y: 604),
        radius: 276,
        options: []
    )

    ink.setFill()
    NSBezierPath(ovalIn: NSRect(x: 408, y: 470, width: 46, height: 62)).fill()
    NSBezierPath(ovalIn: NSRect(x: 570, y: 470, width: 46, height: 62)).fill()

    let nose = NSBezierPath()
    nose.move(to: CGPoint(x: 512, y: 410))
    nose.line(to: CGPoint(x: 544, y: 376))
    nose.line(to: CGPoint(x: 576, y: 410))
    nose.close()
    accent.setFill()
    nose.fill()

    let mouth = NSBezierPath()
    mouth.move(to: CGPoint(x: 544, y: 376))
    mouth.curve(to: CGPoint(x: 514, y: 338), controlPoint1: CGPoint(x: 528, y: 364), controlPoint2: CGPoint(x: 516, y: 350))
    mouth.move(to: CGPoint(x: 544, y: 376))
    mouth.curve(to: CGPoint(x: 574, y: 338), controlPoint1: CGPoint(x: 560, y: 364), controlPoint2: CGPoint(x: 572, y: 350))
    ink.setStroke()
    mouth.lineWidth = 10
    mouth.lineCapStyle = .round
    mouth.stroke()

    for whisker in whiskers() {
        let path = NSBezierPath()
        path.move(to: whisker.start)
        path.line(to: whisker.end)
        ink.withAlphaComponent(0.88).setStroke()
        path.lineWidth = 8
        path.lineCapStyle = .round
        path.stroke()
    }

    let faceOutline = NSBezierPath()
    faceOutline.append(leftEar)
    faceOutline.append(rightEar)
    faceOutline.append(facePath)
    ink.withAlphaComponent(0.09).setStroke()
    faceOutline.lineWidth = 8
    faceOutline.stroke()
}

func drawRepairBadge() {
    let badgeRect = NSRect(x: 694, y: 672, width: 190, height: 190)
    let badgeShadow = NSShadow()
    badgeShadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    badgeShadow.shadowBlurRadius = 18
    badgeShadow.shadowOffset = NSSize(width: 0, height: -8)
    badgeShadow.set()

    let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 74, yRadius: 74)
    let badgeGradient = makeGradient(
        stops: [
            (color(hex: 0x27D4C0), 0.0),
            (color(hex: 0x168C9D), 1.0),
        ]
    )
    badgeGradient.draw(in: badgePath, angle: -58)

    let badgeStroke = NSBezierPath(roundedRect: badgeRect.insetBy(dx: 4, dy: 4), xRadius: 68, yRadius: 68)
    color(hex: 0xFFFFFF).withAlphaComponent(0.26).setStroke()
    badgeStroke.lineWidth = 4
    badgeStroke.stroke()

    color(hex: 0xFFFFFF).setFill()
    NSBezierPath(roundedRect: NSRect(x: 760, y: 724, width: 58, height: 102), xRadius: 18, yRadius: 18).fill()
    NSBezierPath(roundedRect: NSRect(x: 738, y: 746, width: 102, height: 58), xRadius: 18, yRadius: 18).fill()
}

func drawSparkles() {
    let sparkA = sparklePath(center: CGPoint(x: 690, y: 824), radius: 30)
    color(hex: 0xFFF7E2).withAlphaComponent(0.85).setFill()
    sparkA.fill()

    let sparkB = sparklePath(center: CGPoint(x: 858, y: 620), radius: 18)
    color(hex: 0xFFF7E2).withAlphaComponent(0.68).setFill()
    sparkB.fill()
}

func sparklePath(center: CGPoint, radius: CGFloat) -> NSBezierPath {
    let points = [
        CGPoint(x: center.x, y: center.y + radius),
        CGPoint(x: center.x + radius * 0.28, y: center.y + radius * 0.28),
        CGPoint(x: center.x + radius, y: center.y),
        CGPoint(x: center.x + radius * 0.28, y: center.y - radius * 0.28),
        CGPoint(x: center.x, y: center.y - radius),
        CGPoint(x: center.x - radius * 0.28, y: center.y - radius * 0.28),
        CGPoint(x: center.x - radius, y: center.y),
        CGPoint(x: center.x - radius * 0.28, y: center.y + radius * 0.28),
    ]

    let path = NSBezierPath()
    path.move(to: points[0])
    for point in points.dropFirst() {
        path.line(to: point)
    }
    path.close()
    return path
}

func whiskers() -> [(start: CGPoint, end: CGPoint)] {
    [
        (CGPoint(x: 398, y: 392), CGPoint(x: 282, y: 416)),
        (CGPoint(x: 412, y: 358), CGPoint(x: 288, y: 350)),
        (CGPoint(x: 398, y: 328), CGPoint(x: 298, y: 290)),
        (CGPoint(x: 692, y: 392), CGPoint(x: 806, y: 416)),
        (CGPoint(x: 676, y: 358), CGPoint(x: 800, y: 350)),
        (CGPoint(x: 692, y: 328), CGPoint(x: 790, y: 292)),
    ]
}

func drawGlow(center: CGPoint, radius: CGFloat, color: NSColor, alpha: CGFloat) {
    let glow = makeGradient(
        stops: [
            (color.withAlphaComponent(alpha), 0.0),
            (color.withAlphaComponent(0.0), 1.0),
        ]
    )
    glow.draw(
        fromCenter: center,
        radius: 0,
        toCenter: center,
        radius: radius,
        options: []
    )
}

func color(hex: Int) -> NSColor {
    NSColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255.0,
        green: CGFloat((hex >> 8) & 0xFF) / 255.0,
        blue: CGFloat(hex & 0xFF) / 255.0,
        alpha: 1.0
    )
}

func makeGradient(stops: [(NSColor, CGFloat)]) -> NSGradient {
    var locations = stops.map(\.1)
    return NSGradient(colors: stops.map(\.0), atLocations: &locations, colorSpace: .deviceRGB)!
}

func renderPNG(from image: NSImage, pixelSize: Int) throws -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    bitmap.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current = graphicsContext
    graphicsContext.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconRender", code: 1)
    }

    return pngData
}

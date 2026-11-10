import AppKit

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func gradient(_ colors: [CGColor], _ locations: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: locations)!
}

func helmetPath() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 268, y: 540))
    path.addCurve(to: CGPoint(x: 512, y: 850), control1: CGPoint(x: 268, y: 760), control2: CGPoint(x: 380, y: 850))
    path.addCurve(to: CGPoint(x: 756, y: 540), control1: CGPoint(x: 644, y: 850), control2: CGPoint(x: 756, y: 760))
    path.addLine(to: CGPoint(x: 720, y: 330))
    path.addLine(to: CGPoint(x: 620, y: 190))
    path.addLine(to: CGPoint(x: 404, y: 190))
    path.addLine(to: CGPoint(x: 304, y: 330))
    path.closeSubpath()
    return path
}

func facePath() -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 344, y: 600))
    path.addLine(to: CGPoint(x: 680, y: 600))
    path.addLine(to: CGPoint(x: 652, y: 340))
    path.addLine(to: CGPoint(x: 584, y: 236))
    path.addLine(to: CGPoint(x: 440, y: 236))
    path.addLine(to: CGPoint(x: 372, y: 340))
    path.closeSubpath()
    return path
}

func eyeSlit(mirrored: Bool) -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: 388, y: 538))
    path.addLine(to: CGPoint(x: 488, y: 512))
    path.addLine(to: CGPoint(x: 488, y: 466))
    path.addLine(to: CGPoint(x: 398, y: 486))
    path.closeSubpath()
    if mirrored {
        var flip = CGAffineTransform(translationX: 1024, y: 0).scaledBy(x: -1, y: 1)
        return path.copy(using: &flip)!
    }
    return path
}

func drawMark(in context: CGContext) {
    let canvas = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    let tilePath = CGPath(roundedRect: canvas, cornerWidth: 230, cornerHeight: 230, transform: nil)
    context.saveGState()
    context.addPath(tilePath)
    context.clip()
    context.drawLinearGradient(
        gradient([color(0x1A1A1A), color(0x000000)], [0, 1]),
        start: CGPoint(x: 512, y: 1024),
        end: CGPoint(x: 512, y: 0),
        options: []
    )
    context.restoreGState()

    context.setLineJoin(.round)
    context.setLineCap(.round)

    let helmet = helmetPath()
    context.addPath(helmet)
    context.setFillColor(color(0xF5F5F4))
    context.fillPath()

    let face = facePath()
    context.addPath(face)
    context.setFillColor(color(0x000000))
    context.fillPath()

    for mirrored in [false, true] {
        context.addPath(eyeSlit(mirrored: mirrored))
        context.setFillColor(color(0xFBBF24))
        context.fillPath()
    }
}

func draw(in context: CGContext) {
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: color(0x000000, 0.35))
    context.addPath(tilePath)
    context.setFillColor(color(0x0C0A09))
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.translateBy(x: tile.minX, y: tile.minY)
    context.scaleBy(x: tile.width / 1024, y: tile.height / 1024)
    drawMark(in: context)
    context.restoreGState()
}

func render(pixels: Int, full: Bool = false) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let graphics = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = graphics
    let context = graphics.cgContext
    let scale = CGFloat(pixels) / 1024
    context.scaleBy(x: scale, y: scale)
    if full {
        drawMark(in: context)
    } else {
        draw(in: context)
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

if CommandLine.arguments.count > 2 {
    try render(pixels: 1920, full: true).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
}

for base in [16, 32, 128, 256, 512] {
    try render(pixels: base).write(to: outputDirectory.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(pixels: base * 2).write(to: outputDirectory.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

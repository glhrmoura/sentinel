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

func lidPoint(_ p0: CGPoint, _ control: CGPoint, _ p1: CGPoint, _ t: CGFloat) -> (point: CGPoint, normal: CGVector) {
    let u = 1 - t
    let point = CGPoint(
        x: u * u * p0.x + 2 * u * t * control.x + t * t * p1.x,
        y: u * u * p0.y + 2 * u * t * control.y + t * t * p1.y
    )
    let tangent = CGVector(
        dx: 2 * u * (control.x - p0.x) + 2 * t * (p1.x - control.x),
        dy: 2 * u * (control.y - p0.y) + 2 * t * (p1.y - control.y)
    )
    let length = sqrt(tangent.dx * tangent.dx + tangent.dy * tangent.dy)
    var normal = CGVector(dx: -tangent.dy / length, dy: tangent.dx / length)
    if normal.dy < 0 {
        normal = CGVector(dx: -normal.dx, dy: -normal.dy)
    }
    return (point, normal)
}

func drawMark(in context: CGContext) {
    let tilePath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: 1024, height: 1024), cornerWidth: 230, cornerHeight: 230, transform: nil)
    context.saveGState()
    context.addPath(tilePath)
    context.clip()
    context.drawLinearGradient(
        gradient([color(0x292524), color(0x0C0A09)], [0, 1]),
        start: CGPoint(x: 512, y: 1024),
        end: CGPoint(x: 512, y: 0),
        options: []
    )
    context.restoreGState()

    let p0 = CGPoint(x: 222, y: 460)
    let control = CGPoint(x: 512, y: 760)
    let p1 = CGPoint(x: 802, y: 460)
    let stroke: CGFloat = 50

    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setStrokeColor(color(0xF5F5F4))

    let lid = CGMutablePath()
    lid.move(to: p0)
    lid.addQuadCurve(to: p1, control: control)
    context.addPath(lid)
    context.setLineWidth(stroke)
    context.strokePath()

    for index in 0..<5 {
        let t = 0.5 + (CGFloat(index) - 2) * 0.17
        let (point, normal) = lidPoint(p0, control, p1, t)
        let lash = CGMutablePath()
        lash.move(to: CGPoint(x: point.x + normal.dx * 10, y: point.y + normal.dy * 10))
        lash.addLine(to: CGPoint(x: point.x + normal.dx * 110, y: point.y + normal.dy * 110))
        context.addPath(lash)
        context.setLineWidth(stroke * 0.85)
        context.strokePath()
    }

    let center = CGPoint(x: 512, y: 430)
    let radius: CGFloat = 104
    context.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    context.setFillColor(color(0xFBBF24))
    context.fillPath()
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
    try render(pixels: 240, full: true).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
}

for base in [16, 32, 128, 256, 512] {
    try render(pixels: base).write(to: outputDirectory.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(pixels: base * 2).write(to: outputDirectory.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

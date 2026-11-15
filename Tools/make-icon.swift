import AppKit

let side: CGFloat = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func makeContext() -> CGContext {
    let context = CGContext(
        data: nil,
        width: Int(side),
        height: Int(side),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.interpolationQuality = .high
    return context
}

func lensPath(center: CGPoint, halfWidth: CGFloat, halfHeight: CGFloat) -> CGPath {
    let radius = (halfWidth * halfWidth + halfHeight * halfHeight) / (2 * halfHeight)
    let angle = asin(halfWidth / radius)
    let path = CGMutablePath()
    path.addArc(
        center: CGPoint(x: center.x, y: center.y + halfHeight - radius),
        radius: radius,
        startAngle: .pi / 2 + angle,
        endAngle: .pi / 2 - angle,
        clockwise: true
    )
    path.addArc(
        center: CGPoint(x: center.x, y: center.y - halfHeight + radius),
        radius: radius,
        startAngle: -.pi / 2 + angle,
        endAngle: -.pi / 2 - angle,
        clockwise: true
    )
    path.closeSubpath()
    return path
}

func render() -> CGImage {
    let context = makeContext()
    let center = CGPoint(x: side / 2, y: side / 2)

    context.setFillColor(color(0x1C1C1E))
    context.fill(CGRect(x: 0, y: 0, width: side, height: side))

    let rounding: CGFloat = 64
    let eye = lensPath(center: center, halfWidth: 384 - rounding / 2, halfHeight: 236 - rounding / 2)
    context.setAlpha(0.7)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    context.setFillColor(color(0xF5F5F7))
    context.setStrokeColor(color(0xF5F5F7))
    context.setLineWidth(rounding)
    context.setLineJoin(.round)
    context.addPath(eye)
    context.drawPath(using: .fillStroke)
    context.endTransparencyLayer()
    context.setAlpha(1)

    let pupilRadius: CGFloat = 148
    context.setFillColor(color(0xF5F5F7))
    context.fillEllipse(in: CGRect(x: center.x - pupilRadius, y: center.y - pupilRadius, width: pupilRadius * 2, height: pupilRadius * 2))

    return context.makeImage()!
}

func roundedLogo(from art: CGImage) -> CGImage {
    let context = makeContext()
    let rect = CGRect(x: 0, y: 0, width: side, height: side)
    let radius = side * 0.2237
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.clip()
    context.draw(art, in: rect)
    return context.makeImage()!
}

func writePNG(_ image: CGImage, to path: String) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

let art = render()
try writePNG(art, to: CommandLine.arguments[1])
try writePNG(roundedLogo(from: art), to: CommandLine.arguments[2])

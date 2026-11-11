import AppKit

let canvasSize: CGFloat = 1024
let tileRect = CGRect(x: 100, y: 100, width: 824, height: 824)

func loadSource(_ path: String) -> CGImage {
    guard
        let image = NSImage(contentsOfFile: path),
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
        fatalError("Unable to load image at \(path)")
    }
    return cgImage
}

func aspectFit(_ size: CGSize, in rect: CGRect) -> CGRect {
    let scale = min(rect.width / size.width, rect.height / size.height)
    let width = size.width * scale
    let height = size.height * scale
    return CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height)
}

func render(_ source: CGImage, pixels: Int) -> Data {
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
    context.interpolationQuality = .high
    let scale = CGFloat(pixels) / canvasSize
    context.scaleBy(x: scale, y: scale)
    let sourceSize = CGSize(width: source.width, height: source.height)
    context.draw(source, in: aspectFit(sourceSize, in: tileRect))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let source = loadSource(CommandLine.arguments[1])
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    try render(source, pixels: base).write(to: outputDirectory.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(source, pixels: base * 2).write(to: outputDirectory.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}

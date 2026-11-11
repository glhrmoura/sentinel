import AppKit
import CoreImage

let canvasSize = 1024
let logoScale: CGFloat = 1.02
let maskInset: CGFloat = 70
let maskRadius: CGFloat = 230
let maskFeather: CGFloat = 28
let topColor = CGColor(srgbRed: 0.150, green: 0.150, blue: 0.162, alpha: 1)
let bottomColor = CGColor(srgbRed: 0.016, green: 0.020, blue: 0.035, alpha: 1)

func loadSource(_ path: String) -> CGImage {
    guard
        let image = NSImage(contentsOfFile: path),
        let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else {
        fatalError("Unable to load image at \(path)")
    }
    return cgImage
}

func makeContext(_ side: Int) -> CGContext {
    CGContext(
        data: nil,
        width: side,
        height: side,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
}

func featheredMask(side: Int, rect: CGRect) -> CGImage {
    let context = makeContext(side)
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: side, height: side))
    context.addPath(CGPath(roundedRect: rect, cornerWidth: maskRadius, cornerHeight: maskRadius, transform: nil))
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fillPath()
    let extent = CGRect(x: 0, y: 0, width: side, height: side)
    let blurred = CIImage(cgImage: context.makeImage()!)
        .clampedToExtent()
        .applyingGaussianBlur(sigma: Double(maskFeather))
        .cropped(to: extent)
    let ciContext = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])
    let rendered = ciContext.createCGImage(blurred, from: extent)!
    return CGImage(
        maskWidth: side,
        height: side,
        bitsPerComponent: 8,
        bitsPerPixel: 8,
        bytesPerRow: side,
        provider: grayProvider(rendered, side: side),
        decode: nil,
        shouldInterpolate: true
    )!
}

func grayProvider(_ image: CGImage, side: Int) -> CGDataProvider {
    let context = CGContext(
        data: nil,
        width: side,
        height: side,
        bitsPerComponent: 8,
        bytesPerRow: side,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    )!
    context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
    var bytes = [UInt8](UnsafeBufferPointer(start: context.data!.assumingMemoryBound(to: UInt8.self), count: side * side))
    for index in bytes.indices {
        bytes[index] = 255 - bytes[index]
    }
    return CGDataProvider(data: Data(bytes) as CFData)!
}

func render(_ source: CGImage) -> Data {
    let side = CGFloat(canvasSize)
    let context = makeContext(canvasSize)
    context.interpolationQuality = .high

    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [topColor, bottomColor] as CFArray,
        locations: [0, 1]
    )!
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: side), end: CGPoint(x: 0, y: 0), options: [])

    let scale = side * logoScale / CGFloat(max(source.width, source.height))
    let width = CGFloat(source.width) * scale
    let height = CGFloat(source.height) * scale
    let logoRect = CGRect(x: (side - width) / 2, y: (side - height) / 2, width: width, height: height)
    let mask = featheredMask(side: canvasSize, rect: logoRect.insetBy(dx: maskInset, dy: maskInset))

    context.saveGState()
    context.clip(to: CGRect(x: 0, y: 0, width: side, height: side), mask: mask)
    context.draw(source, in: logoRect)
    context.restoreGState()

    let rep = NSBitmapImageRep(cgImage: context.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

let source = loadSource(CommandLine.arguments[1])
try render(source).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))

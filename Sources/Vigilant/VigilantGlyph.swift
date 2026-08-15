import AppKit

enum VigilantGlyph {
    static func image(open: Bool, size: CGFloat, lashes: Int = 5, lineWidth: CGFloat = 64) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            let box = CGRect(x: 182, y: open ? 275 : 230, width: 660, height: 520)
            let scale = rect.width / box.width
            context.translateBy(x: 0, y: (rect.height - box.height * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -box.minX, y: -box.minY)
            draw(open: open, lashes: lashes, lineWidth: lineWidth, in: context)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func draw(open: Bool, lashes: Int, lineWidth: CGFloat, in context: CGContext) {
        let p0 = CGPoint(x: 222, y: open ? 460 : 620)
        let p1 = CGPoint(x: 802, y: open ? 460 : 620)
        let control = CGPoint(x: 512, y: open ? 760 : 320)

        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(NSColor.black.cgColor)
        context.setFillColor(NSColor.black.cgColor)

        let lid = CGMutablePath()
        lid.move(to: p0)
        lid.addQuadCurve(to: p1, control: control)
        context.addPath(lid)
        context.setLineWidth(lineWidth)
        context.strokePath()

        let spacing: CGFloat = lashes > 3 ? 0.17 : 0.24
        for index in 0..<lashes {
            let t = 0.5 + (CGFloat(index) - CGFloat(lashes - 1) / 2) * spacing
            let (point, normal) = lidPoint(p0, control, p1, t, upward: open)
            let lash = CGMutablePath()
            lash.move(to: CGPoint(x: point.x + normal.dx * 10, y: point.y + normal.dy * 10))
            lash.addLine(to: CGPoint(x: point.x + normal.dx * 110, y: point.y + normal.dy * 110))
            context.addPath(lash)
            context.setLineWidth(lineWidth * 0.85)
            context.strokePath()
        }

        if open {
            let radius: CGFloat = 104
            context.fillEllipse(in: CGRect(x: 512 - radius, y: 430 - radius, width: radius * 2, height: radius * 2))
        }
    }

    private static func lidPoint(
        _ p0: CGPoint,
        _ control: CGPoint,
        _ p1: CGPoint,
        _ t: CGFloat,
        upward: Bool
    ) -> (CGPoint, CGVector) {
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
        if (normal.dy < 0) == upward {
            normal = CGVector(dx: -normal.dx, dy: -normal.dy)
        }
        return (point, normal)
    }
}

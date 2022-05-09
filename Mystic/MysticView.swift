//
//  MysticView.swift
//  Mystic
//
//  Created by Eric Baker on 29.Apr.2022.
//

import ScreenSaver

final class MysticView: ScreenSaverView {
    static let tailCount = 5

    var figure1: [Figure] = []
    var figure2: [Figure] = []

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setUp()
    }

    private func setUp() {
        animationTimeInterval = TimeInterval(0.05)
    }

    override func draw(_ rect: NSRect) {
        super.draw(rect)

        figure1.forEach(drawFigure(_:))
        figure2.forEach(drawFigure(_:))
    }

    func drawFigure(_ figure: Figure) {
        let color = NSColor(red: figure.rgb.r,
                            green: figure.rgb.g,
                            blue: figure.rgb.b,
                            alpha: 1.0)

        color.setStroke()

        let path = NSBezierPath()
        path.move(to: NSPoint(x: figure.corners[0].point.x,
                              y: figure.corners[0].point.y))
        figure.corners.forEach { corner in
            path.line(to: NSPoint(x: corner.point.x, y: corner.point.y))
        }
        path.line(to: NSPoint(x: figure.corners[0].point.x,
                              y: figure.corners[0].point.y))
        path.stroke()
    }

    override func animateOneFrame() {
        super.animateOneFrame()

        figure1 = step(figure: figure1, boundaries: visibleRect.size)
        figure2 = step(figure: figure2, boundaries: visibleRect.size)

        needsDisplay = true
    }

    override var hasConfigureSheet: Bool { false }

    private func step(figure: [Figure], boundaries: CGSize) -> [Figure] {
        var first = figure.first ?? .createFigure(numberOfCorners: Figure.corners, boundaries: boundaries)
        first.step(boundaries: boundaries)

        return [Figure](([first] + figure).prefix(Self.tailCount))
    }
}

struct Figure {
    static let corners = UInt(4)
    static let rgbStep: CGFloat = 0.001

    struct RGB {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat

        static func random() -> RGB {
            RGB(r: .random(in: 0.0 ... 1.0),
                g: .random(in: 0.0 ... 1.0),
                b: .random(in: 0.0 ... 1.0))
        }

        var color: NSColor {
            NSColor(red: r, green: g, blue: b, alpha: 1.0)
        }

        func closeEnough(to other: RGB) -> Bool {
            other.r.closeEnough(to: r, tolerance: Figure.rgbStep) &&
            other.g.closeEnough(to: g, tolerance: Figure.rgbStep) &&
            other.b.closeEnough(to: b, tolerance: Figure.rgbStep)
        }
    }

    typealias Corner = (point: CGPoint, direction: CGPoint)

    var corners: [Corner]
    var rgb: RGB
    var targetRGB: RGB

    static func createFigure(numberOfCorners: UInt, boundaries: CGSize) -> Figure {
        let corners: [Corner] = (0 ..< numberOfCorners).map { index in
            Corner(point: CGPoint(x: CGFloat.random(in: 0.0 ..< boundaries.width),
                                  y: CGFloat.random(in: 0.0 ..< boundaries.height)),
                   direction: CGPoint(x: CGFloat.random(in: boundaries.minStep ... boundaries.maxStep),
                                      y: CGFloat.random(in: boundaries.minStep ... boundaries.maxStep)))
        }

        return Figure(corners: corners, rgb: .random(), targetRGB: .random())
    }

    mutating func step(boundaries: CGSize) {
        corners.enumerated().forEach { index, corner in
            let point = corner.point
            var direction = corner.direction

            // Check boundaries. If reached, then change direction.
            var x = point.x + direction.x
            if x < 0 {
                direction.x = .random(in: boundaries.minStep ... boundaries.maxStep)
            }
            else if x > boundaries.width {
                direction.x = .random(in: boundaries.minStep ... boundaries.maxStep) * -1
            }
            x = point.x + direction.x

            var y = point.y + direction.y
            if y < 0 {
                direction.y = .random(in: boundaries.minStep ... boundaries.maxStep)
            }
            else if y > boundaries.height {
                direction.y = .random(in: boundaries.minStep ... boundaries.maxStep) * -1
            }
            y = point.y + direction.y

            corners[index] = Corner(point: CGPoint(x: x, y: y), direction: direction)
        }

        if rgb.closeEnough(to: targetRGB) {
            targetRGB = .random()
        }

        func stepColorComponent(_ c: CGFloat, target: CGFloat, step: CGFloat) -> CGFloat {
            if c.closeEnough(to: target, tolerance: step) { return c }

            return min(max(
                c + (c < target ? step : -step)
                , 0.0), 1.0)
        }

        let r = stepColorComponent(rgb.r, target: targetRGB.r, step: Self.rgbStep)
        let g = stepColorComponent(rgb.g, target: targetRGB.g, step: Self.rgbStep)
        let b = stepColorComponent(rgb.b, target: targetRGB.b, step: Self.rgbStep)

        rgb = RGB(r: r, g: g, b: b)
    }
}

extension CGFloat {
    func closeEnough(to other: CGFloat, tolerance: CGFloat) -> Bool {
        (other - tolerance ... other + tolerance).contains(self)
    }
}

extension CGSize {
    var minStep: CGFloat { width * 0.0008 }
    var maxStep: CGFloat { width * 0.008 }
}

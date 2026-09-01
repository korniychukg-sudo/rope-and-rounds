import SwiftUI

struct BellWheelView: View {
    let angle: Double
    let voice: BellVoice
    var striking: Double = 0

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height * 0.46
            let R = min(size.width, size.height) * 0.36

            var frame = Path()
            frame.addRoundedRect(in: CGRect(x: cx - R * 1.28, y: cy - R * 1.14,
                                            width: R * 2.56, height: R * 2.3),
                                 cornerSize: CGSize(width: 8, height: 8))
            ctx.stroke(frame, with: .color(Belfry.oak.opacity(0.7)), lineWidth: 10)

            var wheel = Path()
            wheel.addEllipse(in: CGRect(x: cx - R, y: cy - R, width: R * 2, height: R * 2))
            ctx.stroke(wheel, with: .color(Belfry.oak), lineWidth: R * 0.10)
            ctx.stroke(wheel, with: .color(Belfry.oak.opacity(0.5)), lineWidth: R * 0.04)

            var spokes = Path()
            var i = 0
            while i < 8 {
                let a = Double(i) / 8.0 * 6.283185307 + angle
                spokes.move(to: CGPoint(x: cx + CGFloat(cos(a)) * R * 0.12,
                                        y: cy + CGFloat(sin(a)) * R * 0.12))
                spokes.addLine(to: CGPoint(x: cx + CGFloat(cos(a)) * R * 0.95,
                                           y: cy + CGFloat(sin(a)) * R * 0.95))
                i += 1
            }
            ctx.stroke(spokes, with: .color(Belfry.oak.opacity(0.85)), lineWidth: R * 0.05)

            let bellAngle = angle
            let mouthR = R * 0.66
            let stops: [(Double, Double)] = [(0.00, 0.16), (0.14, 0.32), (0.30, 0.50),
                                             (0.50, 0.55), (0.70, 0.62), (0.86, 0.78), (1.00, 1.00)]
            func halfW(_ t: Double) -> Double {
                var i = 0
                while i < stops.count - 1 {
                    if t >= stops[i].0 && t <= stops[i + 1].0 {
                        let span = stops[i + 1].0 - stops[i].0
                        let k = span > 0 ? (t - stops[i].0) / span : 0
                        let e = k * k * (3 - 2 * k)
                        return stops[i].1 + (stops[i + 1].1 - stops[i].1) * e
                    }
                    i += 1
                }
                return 1.0
            }
            let ca = CGFloat(cos(bellAngle + 1.5707963))
            let sa = CGFloat(sin(bellAngle + 1.5707963))
            func bp(_ hx: Double, _ t: Double) -> CGPoint {
                let lx = CGFloat(hx) * mouthR
                let ly = CGFloat(t) * mouthR * 1.34
                return CGPoint(x: cx + lx * ca - ly * sa, y: cy + lx * sa + ly * ca)
            }
            var bell = Path()
            var k = 0
            while k <= 22 {
                let t = Double(k) / 22.0
                let q = bp(halfW(t), t)
                if k == 0 { bell.move(to: q) } else { bell.addLine(to: q) }
                k += 1
            }
            k = 22
            while k >= 0 {
                let t = Double(k) / 22.0
                bell.addLine(to: bp(-halfW(t), t))
                k -= 1
            }
            bell.closeSubpath()
            ctx.fill(bell, with: .linearGradient(
                Gradient(colors: [Belfry.bellLit, Belfry.bell, Belfry.bellDeep]),
                startPoint: CGPoint(x: cx - R, y: cy - R),
                endPoint: CGPoint(x: cx + R, y: cy + R)))
            ctx.stroke(bell, with: .color(Color.black.opacity(0.55)), lineWidth: 1.6)
            var wire = Path()
            for t in [0.42, 0.56, 0.90] {
                wire.move(to: bp(-halfW(t), t))
                wire.addLine(to: bp(halfW(t), t))
            }
            ctx.stroke(wire, with: .color(Belfry.bellDeep.opacity(0.7)), lineWidth: 1.6)
            if striking > 0.01 {
                ctx.stroke(bell, with: .color(Belfry.amber.opacity(striking)), lineWidth: 4.0)
            }

            var hub = Path()
            hub.addEllipse(in: CGRect(x: cx - R * 0.13, y: cy - R * 0.13,
                                      width: R * 0.26, height: R * 0.26))
            ctx.fill(hub, with: .color(Belfry.oak))
            ctx.stroke(hub, with: .color(Color.black.opacity(0.5)), lineWidth: 1.4)

            var rope = Path()
            let ra = angle + 1.5707963
            let rx = cx + CGFloat(cos(ra)) * R
            let ry = cy + CGFloat(sin(ra)) * R
            rope.move(to: CGPoint(x: rx, y: ry))
            rope.addQuadCurve(to: CGPoint(x: cx + R * 0.10, y: size.height),
                              control: CGPoint(x: rx + (cx - rx) * 0.4, y: cy + R * 1.5))
            ctx.stroke(rope, with: .color(Belfry.ropeTone),
                       style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        }
    }
}

struct RopeView: View {
    let pull: Double
    let atHandstroke: Bool

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let top: CGFloat = 0
            let slack = CGFloat(pull) * size.height * 0.32

            var rope = Path()
            rope.move(to: CGPoint(x: cx, y: top))
            rope.addQuadCurve(to: CGPoint(x: cx, y: size.height * 0.92 - slack),
                              control: CGPoint(x: cx + 14, y: size.height * 0.45))
            ctx.stroke(rope, with: .color(Belfry.ropeTone),
                       style: StrokeStyle(lineWidth: 6, lineCap: .round))
            var twist = Path()
            var i = 0
            while i < 40 {
                let t = CGFloat(i) / 40.0
                let y = top + (size.height * 0.92 - slack - top) * t
                twist.move(to: CGPoint(x: cx - 3, y: y))
                twist.addLine(to: CGPoint(x: cx + 3, y: y + 4))
                i += 1
            }
            ctx.stroke(twist, with: .color(Color.black.opacity(0.20)), lineWidth: 1.2)

            if atHandstroke {
                let sy = size.height * 0.62 - slack
                var sally = Path()
                sally.addRoundedRect(in: CGRect(x: cx - 13, y: sy, width: 26, height: 120),
                                     cornerSize: CGSize(width: 13, height: 13))
                ctx.fill(sally, with: .linearGradient(
                    Gradient(colors: [Belfry.sally, Belfry.bone, Belfry.sally, Belfry.bone]),
                    startPoint: CGPoint(x: cx, y: sy),
                    endPoint: CGPoint(x: cx, y: sy + 120)))
                ctx.stroke(sally, with: .color(Color.black.opacity(0.35)), lineWidth: 1.2)
                var tuft = Path()
                tuft.move(to: CGPoint(x: cx - 10, y: sy + 120))
                tuft.addLine(to: CGPoint(x: cx, y: sy + 140))
                tuft.addLine(to: CGPoint(x: cx + 10, y: sy + 120))
                ctx.stroke(tuft, with: .color(Belfry.sally), lineWidth: 3)
            } else {
                var tail = Path()
                let ty = size.height * 0.92 - slack
                tail.move(to: CGPoint(x: cx, y: ty))
                tail.addQuadCurve(to: CGPoint(x: cx - 26, y: ty + 60),
                                  control: CGPoint(x: cx - 20, y: ty + 26))
                ctx.stroke(tail, with: .color(Belfry.ropeTone),
                           style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }
        }
    }
}

struct BlueLineView: View {
    let method: RingingMethod
    let bell: Int
    var highlightRow: Int = -1
    var rowsToShow: Int = 34

    var body: some View {
        Canvas { ctx, size in
            let run = generateRows(method, leads: 12)
            let n = method.bells
            let count = min(rowsToShow, run.rows.count)
            let rowH = size.height / CGFloat(max(1, count))
            let colW = size.width / CGFloat(n)

            var grid = Path()
            var c = 0
            while c <= n {
                let x = CGFloat(c) * colW
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
                c += 1
            }
            ctx.stroke(grid, with: .color(Belfry.hairline), lineWidth: 0.8)

            var r = 0
            while r < count {
                let row = run.rows[r]
                var b = 0
                while b < n {
                    let x = (CGFloat(b) + 0.5) * colW
                    let y = (CGFloat(r) + 0.5) * rowH
                    let isMine = row[b] == bell
                    let isTreble = row[b] == 1
                    ctx.draw(Text("\(row[b])")
                                .font(Cut.figure(min(13, rowH * 0.72)))
                                .foregroundColor(isMine ? Belfry.paper
                                                 : (isTreble ? Belfry.rust : Belfry.inkPale)),
                             at: CGPoint(x: x, y: y))
                    if isMine {
                        var dot = Path()
                        dot.addEllipse(in: CGRect(x: x - rowH * 0.42, y: y - rowH * 0.42,
                                                  width: rowH * 0.84, height: rowH * 0.84))
                        ctx.fill(dot, with: .color(Belfry.slate))
                        ctx.draw(Text("\(row[b])")
                                    .font(Cut.figure(min(13, rowH * 0.72)))
                                    .foregroundColor(Belfry.paper),
                                 at: CGPoint(x: x, y: y))
                    }
                    b += 1
                }
                if r == highlightRow {
                    var bar = Path()
                    bar.addRect(CGRect(x: 0, y: CGFloat(r) * rowH, width: size.width, height: rowH))
                    ctx.stroke(bar, with: .color(Belfry.amber), lineWidth: 2)
                }
                r += 1
            }

            var line = Path()
            r = 0
            while r < count {
                let place = (run.rows[r].firstIndex(of: bell) ?? 0)
                let x = (CGFloat(place) + 0.5) * colW
                let y = (CGFloat(r) + 0.5) * rowH
                if r == 0 { line.move(to: CGPoint(x: x, y: y)) } else { line.addLine(to: CGPoint(x: x, y: y)) }
                r += 1
            }
            ctx.stroke(line, with: .color(Belfry.slate.opacity(0.75)),
                       style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))

            var treble = Path()
            r = 0
            while r < count {
                let place = (run.rows[r].firstIndex(of: 1) ?? 0)
                let x = (CGFloat(place) + 0.5) * colW
                let y = (CGFloat(r) + 0.5) * rowH
                if r == 0 { treble.move(to: CGPoint(x: x, y: y)) } else { treble.addLine(to: CGPoint(x: x, y: y)) }
                r += 1
            }
            ctx.stroke(treble, with: .color(Belfry.rust.opacity(0.55)),
                       style: StrokeStyle(lineWidth: 1.8, dash: [4, 3]))
        }
    }
}

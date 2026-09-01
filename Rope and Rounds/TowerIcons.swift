import SwiftUI

struct BellGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var body = Path()
            body.move(to: CGPoint(x: w * 0.50, y: h * 0.10))
            body.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.62),
                          control1: CGPoint(x: w * 0.62, y: h * 0.30),
                          control2: CGPoint(x: w * 0.78, y: h * 0.46))
            body.addArc(center: CGPoint(x: w * 0.50, y: h * 0.62),
                        radius: w * 0.28, startAngle: .degrees(0),
                        endAngle: .degrees(180), clockwise: false)
            body.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.10),
                          control1: CGPoint(x: w * 0.22, y: h * 0.46),
                          control2: CGPoint(x: w * 0.38, y: h * 0.30))
            ctx.fill(body, with: .color(color.opacity(0.30)))
            ctx.stroke(body, with: .color(color), lineWidth: max(1.3, w * 0.062))
            var ring = Path()
            ring.addEllipse(in: CGRect(x: w * 0.34, y: h * 0.52, width: w * 0.32, height: h * 0.20))
            ctx.stroke(ring, with: .color(color.opacity(0.75)), lineWidth: max(1.0, w * 0.042))
        }
        .frame(width: size, height: size)
    }
}

struct RopeGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var back = Path()
            back.addRoundedRect(in: CGRect(x: w * 0.10, y: h * 0.20, width: w * 0.80, height: h * 0.18),
                                cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(back, with: .color(color.opacity(0.28)))
            ctx.stroke(back, with: .color(color), lineWidth: max(1.2, w * 0.055))
            var i = 0
            while i < 7 {
                let frac: CGFloat = 0.16 + 0.68 * CGFloat(i) / 6.0
                let x: CGFloat = w * frac
                var tine = Path()
                tine.move(to: CGPoint(x: x, y: h * 0.38))
                tine.addLine(to: CGPoint(x: x, y: h * 0.84))
                ctx.stroke(tine, with: .color(color),
                           style: StrokeStyle(lineWidth: max(1.0, w * 0.042), lineCap: .round))
                i += 1
            }
        }
        .frame(width: size, height: size)
    }
}

struct LineGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var shaft = Path()
            shaft.move(to: CGPoint(x: w * 0.24, y: h * 0.80))
            shaft.addLine(to: CGPoint(x: w * 0.70, y: h * 0.22))
            ctx.stroke(shaft, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.7, w * 0.085), lineCap: .round))
            var tip = Path()
            tip.move(to: CGPoint(x: w * 0.14, y: h * 0.90))
            tip.addLine(to: CGPoint(x: w * 0.30, y: h * 0.74))
            tip.addLine(to: CGPoint(x: w * 0.22, y: h * 0.86))
            tip.closeSubpath()
            ctx.fill(tip, with: .color(color))
            var cap = Path()
            cap.addRoundedRect(in: CGRect(x: w * 0.62, y: h * 0.10, width: w * 0.24, height: h * 0.20),
                               cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.stroke(cap, with: .color(color), lineWidth: max(1.1, w * 0.050))
        }
        .frame(width: size, height: size)
    }
}

struct BookGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var back = Path()
            back.addRoundedRect(in: CGRect(x: w * 0.22, y: h * 0.14, width: w * 0.60, height: h * 0.68),
                                cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.stroke(back, with: .color(color.opacity(0.55)), lineWidth: max(1.0, w * 0.045))
            var front = Path()
            front.addRoundedRect(in: CGRect(x: w * 0.12, y: h * 0.22, width: w * 0.60, height: h * 0.68),
                                 cornerSize: CGSize(width: w * 0.04, height: w * 0.04))
            ctx.fill(front, with: .color(color.opacity(0.22)))
            ctx.stroke(front, with: .color(color), lineWidth: max(1.2, w * 0.055))
            var i = 0
            while i < 3 {
                let frac: CGFloat = 0.38 + CGFloat(i) * 0.16
                var line = Path()
                line.move(to: CGPoint(x: w * 0.22, y: h * frac))
                line.addLine(to: CGPoint(x: w * 0.62, y: h * frac))
                ctx.stroke(line, with: .color(color.opacity(0.65)), lineWidth: max(0.9, w * 0.038))
                i += 1
            }
        }
        .frame(width: size, height: size)
    }
}

struct BoardGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var box = Path()
            box.addRoundedRect(in: CGRect(x: w * 0.12, y: h * 0.34, width: w * 0.76, height: h * 0.50),
                               cornerSize: CGSize(width: w * 0.05, height: w * 0.05))
            ctx.fill(box, with: .color(color.opacity(0.20)))
            ctx.stroke(box, with: .color(color), lineWidth: max(1.2, w * 0.058))
            var lid = Path()
            lid.move(to: CGPoint(x: w * 0.06, y: h * 0.34))
            lid.addLine(to: CGPoint(x: w * 0.34, y: h * 0.14))
            lid.addLine(to: CGPoint(x: w * 0.94, y: h * 0.14))
            lid.addLine(to: CGPoint(x: w * 0.88, y: h * 0.34))
            ctx.stroke(lid, with: .color(color), lineWidth: max(1.1, w * 0.050))
            var sheet = Path()
            sheet.move(to: CGPoint(x: w * 0.30, y: h * 0.44))
            sheet.addLine(to: CGPoint(x: w * 0.70, y: h * 0.44))
            ctx.stroke(sheet, with: .color(color.opacity(0.75)), lineWidth: max(1.0, w * 0.044))
        }
        .frame(width: size, height: size)
    }
}

struct TowerGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var shade = Path()
            shade.move(to: CGPoint(x: w * 0.20, y: h * 0.46))
            shade.addLine(to: CGPoint(x: w * 0.50, y: h * 0.14))
            shade.addLine(to: CGPoint(x: w * 0.80, y: h * 0.46))
            shade.closeSubpath()
            ctx.fill(shade, with: .color(color.opacity(0.26)))
            ctx.stroke(shade, with: .color(color), lineWidth: max(1.2, w * 0.055))
            var i = 0
            while i < 3 {
                let frac: CGFloat = 0.32 + CGFloat(i) * 0.18
                var ray = Path()
                ray.move(to: CGPoint(x: w * frac, y: h * 0.58))
                ray.addLine(to: CGPoint(x: w * (frac + 0.06), y: h * 0.86))
                ctx.stroke(ray, with: .color(color.opacity(0.70)),
                           style: StrokeStyle(lineWidth: max(1.0, w * 0.044), lineCap: .round))
                i += 1
            }
        }
        .frame(width: size, height: size)
    }
}

struct ChevronGlyph: View {
    var size: CGFloat
    var color: Color
    var facing: Double = 0
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.38, y: h * 0.26))
            p.addLine(to: CGPoint(x: w * 0.66, y: h * 0.50))
            p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.74))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.6, w * 0.085), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .rotationEffect(.radians(facing))
    }
}

struct CrossGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.28, y: h * 0.28))
            p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.72))
            p.move(to: CGPoint(x: w * 0.72, y: h * 0.28))
            p.addLine(to: CGPoint(x: w * 0.28, y: h * 0.72))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.6, w * 0.088), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct CheckGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.24, y: h * 0.52))
            p.addLine(to: CGPoint(x: w * 0.43, y: h * 0.72))
            p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.29))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.7, w * 0.095), lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct FlameGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, rect in
            let w = rect.width, h = rect.height
            var p = Path()
            p.move(to: CGPoint(x: w * 0.5, y: h * 0.14))
            p.addCurve(to: CGPoint(x: w * 0.80, y: h * 0.60),
                       control1: CGPoint(x: w * 0.66, y: h * 0.30),
                       control2: CGPoint(x: w * 0.80, y: h * 0.42))
            p.addCurve(to: CGPoint(x: w * 0.20, y: h * 0.60),
                       control1: CGPoint(x: w * 0.80, y: h * 0.92),
                       control2: CGPoint(x: w * 0.20, y: h * 0.92))
            p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.14),
                       control1: CGPoint(x: w * 0.20, y: h * 0.40),
                       control2: CGPoint(x: w * 0.38, y: h * 0.32))
            ctx.fill(p, with: .color(color.opacity(0.28)))
            ctx.stroke(p, with: .color(color), lineWidth: max(1.3, w * 0.062))
        }
        .frame(width: size, height: size)
    }
}

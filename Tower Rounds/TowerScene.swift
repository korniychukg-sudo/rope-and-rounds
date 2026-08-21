import SwiftUI

struct TowerLight {
    var skyTop: Color
    var skyLow: Color
    var stoneLit: Color
    var stoneShade: Color
    var louvre: Color
    var glow: Color
    var starAlpha: Double
    var name: String
}

private func mixT(_ a: Color, _ b: Color, _ t: Double) -> Color {
    let ua = UIColor(a), ub = UIColor(b)
    var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
    var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
    ua.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
    ub.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
    let k = CGFloat(min(1, max(0, t)))
    return Color(red: Double(r1 + (r2 - r1) * k), green: Double(g1 + (g2 - g1) * k),
                 blue: Double(b1 + (b2 - b1) * k))
}

func towerLight(hour: Double) -> TowerLight {
    let keys: [(Double, TowerLight)] = [
        (0, TowerLight(skyTop: Color(red: 0.043, green: 0.055, blue: 0.098),
                       skyLow: Color(red: 0.098, green: 0.114, blue: 0.161),
                       stoneLit: Color(red: 0.204, green: 0.208, blue: 0.216),
                       stoneShade: Color(red: 0.106, green: 0.110, blue: 0.122),
                       louvre: Color(red: 0.055, green: 0.055, blue: 0.063),
                       glow: Color(red: 0.847, green: 0.804, blue: 0.706),
                       starAlpha: 0.95, name: "Night")),
        (6, TowerLight(skyTop: Color(red: 0.235, green: 0.263, blue: 0.322),
                       skyLow: Color(red: 0.588, green: 0.494, blue: 0.427),
                       stoneLit: Color(red: 0.443, green: 0.427, blue: 0.400),
                       stoneShade: Color(red: 0.267, green: 0.259, blue: 0.251),
                       louvre: Color(red: 0.129, green: 0.118, blue: 0.106),
                       glow: Color(red: 0.949, green: 0.804, blue: 0.612),
                       starAlpha: 0.25, name: "Dawn")),
        (11, TowerLight(skyTop: Color(red: 0.478, green: 0.600, blue: 0.706),
                        skyLow: Color(red: 0.788, green: 0.816, blue: 0.816),
                        stoneLit: Color(red: 0.729, green: 0.706, blue: 0.659),
                        stoneShade: Color(red: 0.478, green: 0.463, blue: 0.435),
                        louvre: Color(red: 0.239, green: 0.204, blue: 0.169),
                        glow: Color(red: 1.0, green: 0.980, blue: 0.918),
                        starAlpha: 0, name: "Morning")),
        (16, TowerLight(skyTop: Color(red: 0.463, green: 0.549, blue: 0.635),
                        skyLow: Color(red: 0.855, green: 0.804, blue: 0.706),
                        stoneLit: Color(red: 0.769, green: 0.722, blue: 0.639),
                        stoneShade: Color(red: 0.494, green: 0.463, blue: 0.416),
                        louvre: Color(red: 0.243, green: 0.204, blue: 0.161),
                        glow: Color(red: 1.0, green: 0.949, blue: 0.847),
                        starAlpha: 0, name: "Afternoon")),
        (20, TowerLight(skyTop: Color(red: 0.239, green: 0.235, blue: 0.290),
                        skyLow: Color(red: 0.694, green: 0.451, blue: 0.322),
                        stoneLit: Color(red: 0.541, green: 0.451, blue: 0.376),
                        stoneShade: Color(red: 0.290, green: 0.251, blue: 0.220),
                        louvre: Color(red: 0.129, green: 0.106, blue: 0.086),
                        glow: Color(red: 0.976, green: 0.769, blue: 0.494),
                        starAlpha: 0.20, name: "Evening")),
        (24, TowerLight(skyTop: Color(red: 0.043, green: 0.055, blue: 0.098),
                        skyLow: Color(red: 0.098, green: 0.114, blue: 0.161),
                        stoneLit: Color(red: 0.204, green: 0.208, blue: 0.216),
                        stoneShade: Color(red: 0.106, green: 0.110, blue: 0.122),
                        louvre: Color(red: 0.055, green: 0.055, blue: 0.063),
                        glow: Color(red: 0.847, green: 0.804, blue: 0.706),
                        starAlpha: 0.95, name: "Night"))
    ]
    for i in 0..<(keys.count - 1) {
        if hour >= keys[i].0 && hour <= keys[i + 1].0 {
            let span = keys[i + 1].0 - keys[i].0
            let t = span > 0 ? (hour - keys[i].0) / span : 0
            let a = keys[i].1, b = keys[i + 1].1
            return TowerLight(skyTop: mixT(a.skyTop, b.skyTop, t),
                              skyLow: mixT(a.skyLow, b.skyLow, t),
                              stoneLit: mixT(a.stoneLit, b.stoneLit, t),
                              stoneShade: mixT(a.stoneShade, b.stoneShade, t),
                              louvre: mixT(a.louvre, b.louvre, t),
                              glow: mixT(a.glow, b.glow, t),
                              starAlpha: a.starAlpha + (b.starAlpha - a.starAlpha) * t,
                              name: t < 0.5 ? a.name : b.name)
        }
    }
    return keys[0].1
}

struct TowerHeaderScene: View {
    let hour: Double
    let bells: Int

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { tl in
            let t = tl.date.timeIntervalSince1970
            Canvas { ctx, size in
                let L = towerLight(hour: hour)
                let w = size.width, h = size.height

                var sky = Path()
                sky.addRect(CGRect(origin: .zero, size: size))
                ctx.fill(sky, with: .linearGradient(
                    Gradient(colors: [L.skyTop, L.skyLow]),
                    startPoint: CGPoint(x: w / 2, y: 0), endPoint: CGPoint(x: w / 2, y: h)))

                if L.starAlpha > 0.02 {
                    var rng = TowerDice(5521)
                    var i = 0
                    while i < 60 {
                        let x = CGFloat(rng.unit()) * w
                        let y = CGFloat(rng.unit()) * h * 0.7
                        let tw = 0.55 + 0.45 * sin(t * (0.5 + rng.unit()) + rng.unit() * 6)
                        let r = CGFloat(0.6 + rng.unit() * 1.1)
                        var dot = Path()
                        dot.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                        ctx.fill(dot, with: .color(Color.white.opacity(L.starAlpha * tw * 0.85)))
                        i += 1
                    }
                }

                let towerW = w * 0.46
                let tx = w * 0.5 - towerW / 2
                var body = Path()
                body.addRect(CGRect(x: tx, y: h * 0.16, width: towerW, height: h))
                ctx.fill(body, with: .linearGradient(
                    Gradient(colors: [L.stoneLit, L.stoneShade]),
                    startPoint: CGPoint(x: tx, y: 0), endPoint: CGPoint(x: tx + towerW, y: 0)))

                var course = Path()
                var y = h * 0.20
                while y < h {
                    course.move(to: CGPoint(x: tx, y: y))
                    course.addLine(to: CGPoint(x: tx + towerW, y: y))
                    y += 13
                }
                ctx.stroke(course, with: .color(Color.black.opacity(0.16)), lineWidth: 1)
                var joint = TowerDice(991)
                var jr = 0
                while jr < 40 {
                    let jx = tx + CGFloat(joint.unit()) * towerW
                    let jy = h * 0.20 + CGFloat(joint.unit()) * h * 0.8
                    var v = Path()
                    v.move(to: CGPoint(x: jx, y: jy))
                    v.addLine(to: CGPoint(x: jx, y: jy + 13))
                    ctx.stroke(v, with: .color(Color.black.opacity(0.14)), lineWidth: 1)
                    jr += 1
                }

                var battl = Path()
                var bx = tx
                var k = 0
                while bx < tx + towerW {
                    let bw = towerW / 7
                    if k % 2 == 0 {
                        battl.addRect(CGRect(x: bx, y: h * 0.10, width: bw, height: h * 0.07))
                    }
                    bx += bw
                    k += 1
                }
                battl.addRect(CGRect(x: tx - 5, y: h * 0.155, width: towerW + 10, height: h * 0.035))
                ctx.fill(battl, with: .color(L.stoneLit))
                ctx.stroke(battl, with: .color(Color.black.opacity(0.28)), lineWidth: 1)

                let lw = towerW * 0.30
                let lx = w * 0.5 - lw / 2
                var op = Path()
                op.move(to: CGPoint(x: lx, y: h * 0.62))
                op.addLine(to: CGPoint(x: lx, y: h * 0.36))
                op.addQuadCurve(to: CGPoint(x: lx + lw, y: h * 0.36),
                                control: CGPoint(x: lx + lw / 2, y: h * 0.24))
                op.addLine(to: CGPoint(x: lx + lw, y: h * 0.62))
                op.closeSubpath()
                ctx.fill(op, with: .color(L.louvre))
                var lv = Path()
                var ly = h * 0.30
                while ly < h * 0.62 {
                    lv.move(to: CGPoint(x: lx + 2, y: ly))
                    lv.addLine(to: CGPoint(x: lx + lw - 2, y: ly + 4))
                    ly += 9
                }
                ctx.stroke(lv, with: .color(L.stoneLit.opacity(0.55)), lineWidth: 2.4)
                ctx.stroke(op, with: .color(Color.black.opacity(0.45)), lineWidth: 1.4)

                let swing = sin(t * 1.3)
                var i = 0
                while i < min(bells, 6) {
                    let bxp = lx + lw * (0.18 + 0.64 * CGFloat(i) / CGFloat(max(1, min(bells, 6) - 1)))
                    let ph = swing * (0.4 + 0.12 * Double(i))
                    let byp = h * 0.44 + CGFloat(sin(ph)) * 4
                    var bell = Path()
                    bell.move(to: CGPoint(x: bxp - 5, y: byp))
                    bell.addQuadCurve(to: CGPoint(x: bxp + 5, y: byp),
                                      control: CGPoint(x: bxp, y: byp + 13))
                    bell.closeSubpath()
                    ctx.fill(bell, with: .color(L.glow.opacity(0.30 + 0.20 * Double(i % 2))))
                    i += 1
                }

                if L.starAlpha < 0.4 {
                    var halo = Path()
                    halo.addEllipse(in: CGRect(x: lx - 26, y: h * 0.30 - 26,
                                               width: lw + 52, height: h * 0.34 + 52))
                    ctx.fill(halo, with: .radialGradient(
                        Gradient(colors: [L.glow.opacity(0.10), L.glow.opacity(0)]),
                        center: CGPoint(x: w / 2, y: h * 0.46), startRadius: 4, endRadius: 90))
                }

                var flock = TowerDice(3391)
                var f = 0
                while f < 7 {
                    let sp = 0.5 + flock.unit()
                    let bxx = (flock.unit() * Double(w) + t * 14 * sp)
                        .truncatingRemainder(dividingBy: Double(w) + 40) - 20
                    let byy = flock.unit() * Double(h) * 0.4 + sin(t * 1.6 + flock.unit() * 6) * 6
                    var bird = Path()
                    bird.move(to: CGPoint(x: CGFloat(bxx) - 5, y: CGFloat(byy)))
                    bird.addQuadCurve(to: CGPoint(x: CGFloat(bxx), y: CGFloat(byy) - 2),
                                      control: CGPoint(x: CGFloat(bxx) - 2.5, y: CGFloat(byy) - 4))
                    bird.addQuadCurve(to: CGPoint(x: CGFloat(bxx) + 5, y: CGFloat(byy)),
                                      control: CGPoint(x: CGFloat(bxx) + 2.5, y: CGFloat(byy) - 4))
                    ctx.stroke(bird, with: .color(Color.black.opacity(0.35)), lineWidth: 1.2)
                    f += 1
                }
            }
        }
    }
}

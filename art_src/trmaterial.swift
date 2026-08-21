import Foundation
import CoreGraphics

func paperSheet(w: Int, h: Int, seed: UInt64, tone: Tone) -> Sheet {
    let p = Sheet(w, h)
    p.topDown()
    var rng = Dice(seed)
    p.fillAll(tone)

    var i = 0
    while i < 40 {
        let x = rng.d() * p.w, y = rng.d() * p.h
        let rr = rng.r(p.w * 0.08, p.w * 0.34)
        let warm = rng.chance(0.55)
        if let g = CGGradient(colorsSpace: rgbSpace,
                              colors: [cg(warm ? tone.lt(0.045).al(0.24) : tone.dk(0.038).al(0.20)),
                                       cg(tone.al(0))] as CFArray, locations: [0, 1]) {
            p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: x, y: y), startRadius: 0,
                                     endCenter: CGPoint(x: x, y: y), endRadius: rr, options: [])
        }
        i += 1
    }

    var y = 0.0
    while y < p.h {
        p.rect(0, y, p.w, 1.1, tone.dk(0.062).al(0.34))
        y += rng.r(5.4, 7.2)
    }
    var x = rng.r(0, 120)
    while x < p.w {
        p.rect(x, 0, 1.8, p.h, tone.lt(0.11).al(0.22))
        x += rng.r(112, 148)
    }

    i = 0
    let fibres = Int(p.w * p.h / 1500)
    while i < fibres {
        let fx = rng.d() * p.w, fy = rng.d() * p.h
        let a = rng.r(0, 6.283), len = rng.r(4, 18)
        p.ctx.setStrokeColor(cg(tone.dk(rng.r(0.04, 0.15)).al(rng.r(0.10, 0.32))))
        p.ctx.setLineWidth(rng.r(0.6, 1.5))
        p.ctx.beginPath()
        p.ctx.move(to: CGPoint(x: fx, y: fy))
        p.ctx.addLine(to: CGPoint(x: fx + cos(a) * len, y: fy + sin(a) * len))
        p.ctx.strokePath()
        i += 1
    }

    i = 0
    while i < rng.i(6, 12) {
        let sx = rng.d() * p.w, sy = rng.d() * p.h
        let rr = rng.r(p.w * 0.02, p.w * 0.075)
        var band: [CGPoint] = []
        var a = 0.0
        while a < 6.283 {
            band.append(CGPoint(x: sx + cos(a) * rr * rng.r(0.78, 1.24),
                                y: sy + sin(a) * rr * rng.r(0.78, 1.24)))
            a += 0.32
        }
        p.poly(band, Tone(r: 0.529, g: 0.443, b: 0.302, a: rng.r(0.030, 0.070)))
        i += 1
    }

    i = 0
    while i < Int(p.w * p.h / 420) {
        let px = rng.d() * p.w, py = rng.d() * p.h
        p.disc(px, py, rng.r(0.4, 1.6), tone.dk(rng.r(0.12, 0.36)).al(rng.r(0.06, 0.24)))
        i += 1
    }

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(tone.dk(0.10).al(0)), cg(tone.dk(0.14).al(0.34))] as CFArray,
                          locations: [0.55, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: p.w / 2, y: p.h / 2), startRadius: 0,
                                 endCenter: CGPoint(x: p.w / 2, y: p.h / 2),
                                 endRadius: max(p.w, p.h) * 0.70, options: [.drawsAfterEndLocation])
    }
    return p
}

func canvasStrip(w: Int, h: Int, seed: UInt64) -> Sheet {
    let p = Sheet(w, h)
    p.topDown()
    var rng = Dice(seed)
    let base = Tone(r: 0.478, g: 0.427, b: 0.341)
    p.fillAll(base)

    var x = 0.0
    while x < p.w {
        p.rect(x, 0, 2.4, p.h, base.lt(rng.r(0.03, 0.11)).al(0.55))
        x += rng.r(4.2, 6.0)
    }
    var y = 0.0
    while y < p.h {
        p.rect(0, y, p.w, 2.2, base.dk(rng.r(0.04, 0.14)).al(0.48))
        y += rng.r(4.2, 6.0)
    }
    var i = 0
    while i < Int(p.w * p.h / 900) {
        p.disc(rng.d() * p.w, rng.d() * p.h, rng.r(0.4, 1.6),
               (rng.chance(0.5) ? base.lt(0.20) : base.dk(0.24)).al(rng.r(0.10, 0.34)))
        i += 1
    }

    let stitchY = p.h * 0.16
    var sx = 8.0
    while sx < p.w - 8 {
        pen(p, [pt(sx, stitchY + rng.r(-1.2, 1.2)), pt(sx + 11, stitchY + rng.r(-1.2, 1.2))],
            weight: 2.6, colour: Tone(r: 0.259, g: 0.216, b: 0.161).al(0.85),
            wobble: 0.5, taper: false, seed: seed &+ UInt64(Int(sx)))
        sx += 20
    }
    p.rect(0, 0, p.w, 3.0, base.dk(0.30).al(0.60))

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(base.dk(0.26).al(0.42)), cg(base.al(0))] as CFArray,
                          locations: [0, 1]) {
        p.ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: p.h * 0.5),
                                 options: [])
    }
    return p
}

func leatherPanel(w: Int, h: Int, seed: UInt64) -> Sheet {
    let p = Sheet(w, h)
    p.topDown()
    var rng = Dice(seed)
    let base = Tone(r: 0.290, g: 0.180, b: 0.118)
    p.fillAll(base)

    var i = 0
    while i < 260 {
        let cx = rng.d() * p.w, cy = rng.d() * p.h
        let rr = rng.r(p.w * 0.012, p.w * 0.055)
        var cell: [CGPoint] = []
        var a = 0.0
        while a < 6.283 {
            cell.append(CGPoint(x: cx + cos(a) * rr * rng.r(0.72, 1.28),
                                y: cy + sin(a) * rr * rng.r(0.72, 1.28)))
            a += 0.5
        }
        p.poly(cell, (rng.chance(0.5) ? base.lt(0.06) : base.dk(0.08)).al(rng.r(0.20, 0.55)))
        penContour(p, cell, weight: 1.1, colour: base.dk(0.30).al(0.40), seed: seed &+ UInt64(i))
        i += 1
    }
    i = 0
    while i < Int(p.w * p.h / 700) {
        p.disc(rng.d() * p.w, rng.d() * p.h, rng.r(0.4, 1.4),
               (rng.chance(0.5) ? base.lt(0.16) : base.dk(0.22)).al(rng.r(0.08, 0.28)))
        i += 1
    }
    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(base.lt(0.10).al(0.30)), cg(base.dk(0.34).al(0.55))] as CFArray,
                          locations: [0, 1]) {
        p.ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 0),
                                 end: CGPoint(x: p.w, y: p.h), options: [])
    }
    return p
}

func makeMaterials(dir: String) {
    let paper = paperSheet(w: 900, h: 1950, seed: hashOf("ts-paper"), tone: Field.paperWarm)
    paper.write(dir, "bg_paper", quality: 0.86)
    let deep = paperSheet(w: 760, h: 900, seed: hashOf("ts-paper-card"), tone: Field.paper.lt(0.30))
    deep.write(dir, "bg_card", quality: 0.86)
    let canvas = canvasStrip(w: 1200, h: 240, seed: hashOf("ts-canvas"))
    canvas.write(dir, "bg_canvas", quality: 0.88)
    let leather = leatherPanel(w: 1200, h: 700, seed: hashOf("ts-leather"))
    leather.write(dir, "bg_leather", quality: 0.88)
}

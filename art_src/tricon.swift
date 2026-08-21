import Foundation
import CoreGraphics

private let bellStops: [(Double, Double)] = [
    (0.00, 0.150), (0.06, 0.190), (0.13, 0.300), (0.22, 0.420),
    (0.33, 0.500), (0.46, 0.540), (0.58, 0.566), (0.70, 0.606),
    (0.80, 0.672), (0.88, 0.774), (0.95, 0.920), (1.00, 1.000)
]

private func bellHalfWidth(_ t: Double) -> Double {
    let u = min(1.0, max(0.0, t))
    var i = 0
    while i < bellStops.count - 1 {
        let a = bellStops[i]
        let b = bellStops[i + 1]
        if u >= a.0 && u <= b.0 {
            let span = b.0 - a.0
            let k = span > 0 ? (u - a.0) / span : 0
            let e = k * k * (3 - 2 * k)
            return a.1 + (b.1 - a.1) * e
        }
        i += 1
    }
    return bellStops[bellStops.count - 1].1
}

func makeIcon(dir: String) {
    let S = 1024
    let p = Sheet(S, S)
    p.topDown()
    p.light = 2.36
    let seed = hashOf("tower-rounds-bell-icon")
    var rng = Dice(seed)

    let lx = -0.60
    let ly = -0.80

    let stoneA = Tone(r: 0.239, g: 0.235, b: 0.220)
    let stoneB = Tone(r: 0.075, g: 0.071, b: 0.067)
    p.fillAll(stoneA)
    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(stoneA.lt(0.24)), cg(stoneB)] as CFArray,
                          locations: [0, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 250, y: 180), startRadius: 10,
                                 endCenter: CGPoint(x: 512, y: 512), endRadius: 940,
                                 options: [.drawsAfterEndLocation])
    }
    var y = 0.0
    while y < 1024 {
        p.rect(0, y, 1024, 2.0, stoneB.al(0.30))
        var x = rng.r(0, 120)
        while x < 1024 {
            p.rect(x, y, 2.0, 62, stoneB.al(0.22))
            x += rng.r(120, 210)
        }
        y += 62
    }
    var i = 0
    while i < 5200 {
        p.disc(rng.d() * 1024, rng.d() * 1024, rng.r(0.4, 2.0),
               (rng.chance(0.5) ? stoneA.lt(0.24) : stoneB).al(rng.r(0.04, 0.16)))
        i += 1
    }

    let bronze = Tone(r: 0.529, g: 0.373, b: 0.129)
    let bronzeLit = Tone(r: 0.965, g: 0.855, b: 0.573)
    let bronzeDeep = Tone(r: 0.129, g: 0.090, b: 0.039)
    let oak = Tone(r: 0.322, g: 0.220, b: 0.141)

    let cx = 512.0
    let topY = 118.0
    let botY = 902.0
    let height = botY - topY
    let maxHalf = 468.0
    let tiltA = 0.0

    func place(_ hx: Double, _ t: Double) -> CGPoint {
        let px = hx
        let py = topY + t * height - height * 0.5
        let ca = cos(tiltA), sa = sin(tiltA)
        return pt(cx + px * ca - py * sa, (topY + height * 0.5) + px * sa + py * ca)
    }

    var outline: [CGPoint] = []
    let N = 90
    var k = 0
    while k <= N {
        let t = Double(k) / Double(N)
        outline.append(place(bellHalfWidth(t) * maxHalf, t))
        k += 1
    }
    k = N
    while k >= 0 {
        let t = Double(k) / Double(N)
        outline.append(place(-bellHalfWidth(t) * maxHalf, t))
        k -= 1
    }
    let shape = pathOf(outline)

    var cast = outline.map { pt(Double($0.x) - lx * 150, Double($0.y) - ly * 150) }
    var pass = 0
    while pass < 5 {
        let spread = 1.0 + Double(pass) * 0.020
        var sx = 0.0, sy = 0.0
        for q in cast { sx += Double(q.x); sy += Double(q.y) }
        sx /= Double(cast.count); sy /= Double(cast.count)
        p.poly(cast.map { pt(sx + (Double($0.x) - sx) * spread, sy + (Double($0.y) - sy) * spread) },
               Tone(r: 0, g: 0, b: 0, a: 0.13))
        pass += 1
    }
    cast = []

    let stockW = maxHalf * 0.42
    let stock: [CGPoint] = [place(-stockW, -0.085), place(stockW, -0.085),
                            place(stockW * 0.90, 0.035), place(-stockW * 0.90, 0.035)]
    p.poly(stock.map { pt(Double($0.x) + 10, Double($0.y) + 14) }, oak.dk(0.40))
    p.poly(stock, oak)
    p.clip(pathOf(stock)) {
        var r2 = Dice(seed &+ 41)
        var j = 0
        while j < 30 {
            let sy2 = place(0, -0.05).y
            pen(p, [pt(cx - 400, Double(sy2) + r2.r(-60, 60)),
                    pt(cx + 400, Double(sy2) + r2.r(-60, 60))],
                weight: r2.r(1.4, 4.0), colour: (r2.chance(0.5) ? oak.lt(0.20) : oak.dk(0.30)).al(0.5),
                wobble: 1.4, taper: false, seed: seed &+ UInt64(j) &+ 51)
            j += 1
        }
    }
    penContour(p, stock, weight: 2.6, colour: Tone(r: 0, g: 0, b: 0, a: 0.60), seed: seed &+ 61)

    p.poly(outline, bronze)
    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(bronzeLit), cg(bronze), cg(bronzeDeep)] as CFArray,
                          locations: [0, 0.26, 1]) {
        p.clip(shape) {
            p.ctx.drawLinearGradient(g, start: CGPoint(x: 130, y: 120),
                                     end: CGPoint(x: 820, y: 780), options: [])
        }
    }

    p.clip(shape) {
        var r3 = Dice(seed &+ 97)
        var band = 0
        while band < 5 {
            let t0 = [0.34, 0.40, 0.66, 0.72, 0.905][band]
            let hgt = [0.014, 0.009, 0.012, 0.008, 0.020][band]
            var strip: [CGPoint] = []
            var q = 0
            while q <= 30 {
                let u = Double(q) / 30.0
                strip.append(place(bellHalfWidth(t0) * maxHalf * (1.0 - 2.0 * u), t0))
                q += 1
            }
            q = 30
            while q >= 0 {
                let u = Double(q) / 30.0
                strip.append(place(bellHalfWidth(t0 + hgt) * maxHalf * (1.0 - 2.0 * u), t0 + hgt))
                q -= 1
            }
            let hi = strip.map { pt(Double($0.x) + lx * 5, Double($0.y) + ly * 5) }
            p.poly(hi, bronzeLit.al(0.55))
            p.poly(strip, bronze.dk(0.22).al(0.85))
            band += 1
        }

        var letters = 0
        while letters < 26 {
            let u = Double(letters) / 26.0
            let t0 = 0.520
            let hx = bellHalfWidth(t0) * maxHalf * (1.0 - 2.0 * u) * 0.94
            let c0 = place(hx, t0)
            let depth = cos((u - 0.5) * 3.0)
            guard depth > 0.05 else { letters += 1; continue }
            var glyph: [CGPoint] = []
            let gw = 12.0 * depth
            let gh = 26.0
            glyph.append(pt(Double(c0.x) - gw, Double(c0.y) - gh * 0.5))
            glyph.append(pt(Double(c0.x) + gw, Double(c0.y) - gh * 0.5))
            glyph.append(pt(Double(c0.x) + gw * 0.8, Double(c0.y) + gh * 0.5))
            glyph.append(pt(Double(c0.x) - gw * 0.8, Double(c0.y) + gh * 0.5))
            p.poly(glyph.map { pt(Double($0.x) - lx * 4, Double($0.y) - ly * 4) },
                   bronzeDeep.al(0.75))
            p.poly(glyph, bronze.lt(0.14).al(0.92))
            p.poly(glyph.map { pt(Double($0.x) + lx * 2.4, Double($0.y) + ly * 2.4) },
                   bronzeLit.al(0.42))
            letters += 1
        }

        var g2 = 0
        while g2 < 5200 {
            p.disc(rng.d() * 1024, rng.d() * 1024, rng.r(0.4, 1.8),
                   (rng.chance(0.5) ? bronzeLit : bronzeDeep).al(rng.r(0.02, 0.10)))
            g2 += 1
        }
        var spec: [CGPoint] = []
        var sI = 0
        while sI <= 24 {
            let t = Double(sI) / 24.0
            spec.append(pt(300 - 70 * t + sin(t * 2.2) * 12, 150 + t * 760))
            sI += 1
        }
        pen(p, spec, weight: 34.0, colour: Tone(r: 1, g: 0.976, b: 0.898, a: 0.20),
            wobble: 3.0, taper: true, seed: seed &+ 211)
        var spec2: [CGPoint] = []
        sI = 0
        while sI <= 24 {
            let t = Double(sI) / 24.0
            spec2.append(pt(700 + 60 * t, 180 + t * 720))
            sI += 1
        }
        pen(p, spec2, weight: 16.0, colour: Tone(r: 1, g: 0.976, b: 0.898, a: 0.10),
            wobble: 3.0, taper: true, seed: seed &+ 213)
    }

    var mouth: [CGPoint] = []
    var mIdx = 0
    while mIdx <= 40 {
        let a = Double(mIdx) / 40.0 * 3.14159265
        let hx = cos(a) * bellHalfWidth(1.0) * maxHalf
        let dy = sin(a) * 0.030
        mouth.append(place(hx, 1.0 + dy))
        mIdx += 1
    }
    mIdx = 40
    while mIdx >= 0 {
        let a = Double(mIdx) / 40.0 * 3.14159265
        let hx = cos(a) * bellHalfWidth(1.0) * maxHalf * 0.86
        let dy = sin(a) * 0.026
        mouth.append(place(hx, 0.972 + dy))
        mIdx -= 1
    }
    p.poly(mouth, bronzeDeep.al(0.85))
    let mouthHi = mouth.map { pt(Double($0.x) + lx * 6, Double($0.y) + ly * 6) }
    penContour(p, mouthHi, weight: 6.0, colour: bronzeLit.al(0.85), seed: seed &+ 301)
    penContour(p, mouth, weight: 3.0, colour: bronzeDeep.dk(0.30).al(0.75), seed: seed &+ 307)

    let n = outline.count
    var e = 0
    while e < n {
        let a = outline[e]
        let b = outline[(e + 1) % n]
        let ang = atan2(Double(b.y - a.y), Double(b.x - a.x))
        let facing = cos(ang - 1.5707963 - 2.36)
        if facing > 0.05 {
            pen(p, [pt(Double(a.x) + lx * 3, Double(a.y) + ly * 3),
                    pt(Double(b.x) + lx * 3, Double(b.y) + ly * 3)],
                weight: 3.6 * facing + 1.6, colour: bronzeLit.lt(0.30).al(0.94),
                wobble: 0.15, taper: false, seed: seed &+ UInt64(e) &+ 401)
        } else {
            pen(p, [a, b], weight: 2.8, colour: bronzeDeep.dk(0.30).al(0.70),
                wobble: 0.15, taper: false, seed: seed &+ UInt64(e) &+ 431)
        }
        e += 1
    }

    var rope: [CGPoint] = []
    var rI = 0
    while rI <= 24 {
        let t = Double(rI) / 24.0
        rope.append(pt(944 + sin(t * 2.4) * 16, -40 + t * 1120))
        rI += 1
    }
    pen(p, rope, weight: 13.0, colour: Tone(r: 0.792, g: 0.741, b: 0.639).al(0.92),
        wobble: 1.0, taper: false, seed: seed &+ 501)
    pen(p, rope.map { pt(Double($0.x) + lx * 4, Double($0.y) + ly * 4) },
        weight: 5.0, colour: Tone(r: 1, g: 0.976, b: 0.914).al(0.55),
        wobble: 0.8, taper: false, seed: seed &+ 503)
    var sallyPts: [CGPoint] = []
    rI = 0
    while rI <= 10 {
        let t = 0.42 + Double(rI) / 10.0 * 0.26
        sallyPts.append(pt(944 + sin(t * 2.4) * 16, -40 + t * 1120))
        rI += 1
    }
    pen(p, sallyPts, weight: 28.0, colour: Tone(r: 0.671, g: 0.259, b: 0.239).al(0.94),
        wobble: 0.8, taper: false, seed: seed &+ 511)
    var stripe = 0
    while stripe < 3 {
        let t0 = 0.47 + Double(stripe) * 0.07
        var seg: [CGPoint] = []
        var q = 0
        while q <= 4 {
            let t = t0 + Double(q) / 4.0 * 0.030
            seg.append(pt(944 + sin(t * 2.4) * 16, -40 + t * 1120))
            q += 1
        }
        pen(p, seg, weight: 28.0, colour: Tone(r: 0.910, g: 0.882, b: 0.812).al(0.94),
            wobble: 0.6, taper: false, seed: seed &+ UInt64(stripe) &+ 521)
        stripe += 1
    }

    if let g = CGGradient(colorsSpace: rgbSpace,
                          colors: [cg(stoneB.al(0)), cg(stoneB.al(0.70))] as CFArray,
                          locations: [0.42, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 400, y: 350), startRadius: 0,
                                 endCenter: CGPoint(x: 480, y: 480), endRadius: 880,
                                 options: [.drawsAfterEndLocation])
    }

    p.writePNG(dir, "AppIcon-1024")
}

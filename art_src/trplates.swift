import Foundation
import CoreGraphics

func methodPlate(_ m: RingingMethod, dir: String) {
    let W = 1150
    let H = 1650
    let p = Sheet(W, H)
    p.topDown()
    p.light = 2.30
    let seed = hashOf("tr-" + m.id)
    layPaper(p, seed: seed, tone: Field.paperWarm)
    plateFrame(p, inset: 26, seed: seed &+ 3)

    caption(p, m.name.uppercased(), at: Double(W) / 2, 104, size: 40,
            colour: Field.ink, face: "Georgia-Bold", align: .centre, tracking: 1.8)
    caption(p, "\(m.classification) · \(m.stage.title) · \(m.firstRung)",
            at: Double(W) / 2, 144, size: 21, colour: Field.sepia,
            face: "Georgia-Italic", align: .centre)
    pen(p, [pt(180, 172), pt(Double(W) - 180, 172)], weight: 1.6, colour: Field.inkSoft,
        wobble: 0.5, taper: false, seed: seed &+ 7)

    let run = generateRows(m, leads: 12)
    let n = m.bells
    let rowCount = min(38, run.rows.count)
    let gridX = 150.0
    let gridY = 232.0
    let gridW = 520.0
    let gridH = 860.0
    let colW = gridW / Double(n)
    let rowH = gridH / Double(rowCount)

    var c = 0
    while c <= n {
        let x = gridX + Double(c) * colW
        pen(p, [pt(x, gridY), pt(x, gridY + gridH)], weight: 0.8,
            colour: Field.inkPale.al(0.35), wobble: 0.2, taper: false, seed: seed &+ UInt64(c))
        c += 1
    }

    var r = 0
    while r < rowCount {
        let row = run.rows[r]
        var b = 0
        while b < n {
            let x = gridX + (Double(b) + 0.5) * colW
            let y = gridY + (Double(r) + 0.5) * rowH
            let isTreble = row[b] == 1
            let isTwo = row[b] == 2
            caption(p, "\(row[b])", at: x, y + 6, size: min(19, rowH * 0.80),
                    colour: isTwo ? Field.ink : (isTreble ? Field.rust : Field.inkPale),
                    face: "Georgia", align: .centre)
            b += 1
        }
        if run.leadHeads.contains(r) && r > 0 {
            pen(p, [pt(gridX - 8, gridY + Double(r) * rowH), pt(gridX + gridW + 8, gridY + Double(r) * rowH)],
                weight: 1.4, colour: Field.rust.al(0.55), wobble: 0.3, taper: false,
                seed: seed &+ UInt64(r) &+ 91)
        }
        r += 1
    }

    var line: [CGPoint] = []
    var treble: [CGPoint] = []
    r = 0
    while r < rowCount {
        let place2 = run.rows[r].firstIndex(of: 2) ?? 0
        let place1 = run.rows[r].firstIndex(of: 1) ?? 0
        line.append(pt(gridX + (Double(place2) + 0.5) * colW, gridY + (Double(r) + 0.5) * rowH))
        treble.append(pt(gridX + (Double(place1) + 0.5) * colW, gridY + (Double(r) + 0.5) * rowH))
        r += 1
    }
    pen(p, line, weight: 3.6, colour: Tone(r: 0.239, g: 0.325, b: 0.463).al(0.80),
        wobble: 0.4, taper: false, seed: seed &+ 111)
    penBroken(p, treble, weight: 2.4, colour: Field.rust.al(0.65), pieces: 6, gap: 0.06,
              wobble: 0.4, seed: seed &+ 131)

    caption(p, "THE BLUE LINE", at: gridX + gridW / 2, gridY - 22, size: 17,
            colour: Field.rust, face: "Georgia-Bold", align: .centre, tracking: 2.6)
    caption(p, "second's line in blue, treble dashed", at: gridX + gridW / 2,
            gridY + gridH + 34, size: 16, colour: Field.inkPale,
            face: "Georgia-Italic", align: .centre)

    var ty = 250.0
    let tx = 720.0
    let tw = Double(W) - tx - 96
    caption(p, "PLACE NOTATION", at: tx, ty, size: 17, colour: Field.rust,
            face: "Georgia-Bold", align: .left, tracking: 2.4)
    ty += 30
    for lineText in wrapText(expandNotation(m.notation).joined(separator: " · "),
                             width: tw, size: 17, face: "Georgia") {
        caption(p, lineText, at: tx, ty, size: 17, colour: Field.ink, align: .left)
        ty += 25
    }
    ty += 6
    caption(p, "lead end \(m.leadEnd)", at: tx, ty, size: 16, colour: Field.sepia,
            face: "Georgia-Italic", align: .left)
    ty += 40
    caption(p, "ROPE SIGHT", at: tx, ty, size: 17, colour: Field.rust,
            face: "Georgia-Bold", align: .left, tracking: 2.4)
    ty += 30
    for lineText in wrapText(m.ropeSight, width: tw, size: 18) {
        caption(p, lineText, at: tx, ty, size: 18, colour: Field.inkSoft, align: .left)
        ty += 26
    }

    var by = 1190.0
    caption(p, "THE METHOD", at: 96, by, size: 18, colour: Field.rust,
            face: "Georgia-Bold", align: .left, tracking: 2.6)
    by += 32
    for lineText in wrapText(m.note, width: Double(W) - 192, size: 22) {
        caption(p, lineText, at: 96, by, size: 22, colour: Field.ink, align: .left)
        by += 31
    }

    p.write(dir, "meth_" + m.id, quality: 0.94)
}

func rowsPlate(_ m: RingingMethod, dir: String) {
    let W = 1150
    let H = 1650
    let p = Sheet(W, H)
    p.topDown()
    let seed = hashOf("trrows-" + m.id)
    layPaper(p, seed: seed, tone: Field.paperCool)
    plateFrame(p, inset: 26, seed: seed &+ 3)

    caption(p, "A PLAIN COURSE", at: Double(W) / 2, 96, size: 26,
            colour: Field.rust, face: "Georgia-Bold", align: .centre, tracking: 4.2)
    caption(p, m.name, at: Double(W) / 2, 146, size: 38,
            colour: Field.ink, face: "Georgia-Bold", align: .centre)
    pen(p, [pt(200, 178), pt(Double(W) - 200, 178)], weight: 1.6, colour: Field.inkSoft,
        wobble: 0.5, taper: false, seed: seed &+ 7)

    let run = generateRows(m, leads: 12)
    let n = m.bells
    let perCol = 44
    let cols = min(5, (run.rows.count + perCol - 1) / perCol)
    let colW = (Double(W) - 200) / Double(max(1, cols))
    var idx = 0
    var col = 0
    while col < cols {
        var row = 0
        while row < perCol && idx < run.rows.count {
            let x = 100 + Double(col) * colW + colW * 0.5
            let y = 240 + Double(row) * 30
            let text = run.rows[idx].map { String($0) }.joined()
            let isLead = run.leadHeads.contains(idx)
            caption(p, text, at: x, y, size: 20,
                    colour: isLead ? Field.rust : Field.ink,
                    face: isLead ? "Georgia-Bold" : "Georgia", align: .centre)
            row += 1
            idx += 1
        }
        col += 1
    }
    _ = n

    caption(p, "Lead heads in red. No row is rung twice in a plain course.",
            at: Double(W) / 2, Double(H) - 96, size: 19, colour: Field.inkPale,
            face: "Georgia-Italic", align: .centre)

    p.write(dir, "rows_" + m.id, quality: 0.94)
}


func placeBellsPlate(_ m: RingingMethod, dir: String) {
    let W = 1400
    let H = 1500
    let p = Sheet(W, H)
    p.topDown()
    let seed = hashOf("trpb-" + m.id)
    layPaper(p, seed: seed, tone: Field.paperWarm)
    plateFrame(p, inset: 26, seed: seed &+ 3)

    caption(p, "PLACE BELLS", at: Double(W) / 2, 96, size: 28,
            colour: Field.rust, face: "Georgia-Bold", align: .centre, tracking: 4.4)
    caption(p, m.name, at: Double(W) / 2, 146, size: 38,
            colour: Field.ink, face: "Georgia-Bold", align: .centre)
    pen(p, [pt(240, 178), pt(Double(W) - 240, 178)], weight: 1.6, colour: Field.inkSoft,
        wobble: 0.5, taper: false, seed: seed &+ 7)

    let run = generateRows(m, leads: 12)
    let n = m.bells
    let rowCount = min(30, run.rows.count)
    let panelW = (Double(W) - 160) / Double(n)
    let panelH = 980.0
    let top = 250.0

    var b = 0
    while b < n {
        let x0 = 80 + Double(b) * panelW
        let colW = (panelW - 22) / Double(n)
        let rowH = panelH / Double(rowCount)

        var line: [CGPoint] = []
        var r = 0
        while r < rowCount {
            let place = run.rows[r].firstIndex(of: b + 1) ?? 0
            line.append(pt(x0 + 11 + (Double(place) + 0.5) * colW, top + (Double(r) + 0.5) * rowH))
            r += 1
        }
        var c = 0
        while c <= n {
            let x = x0 + 11 + Double(c) * colW
            pen(p, [pt(x, top), pt(x, top + panelH)], weight: 0.6,
                colour: Field.inkPale.al(0.25), wobble: 0.15, taper: false,
                seed: seed &+ UInt64(b * 20 + c))
            c += 1
        }
        pen(p, line, weight: 3.2,
            colour: b == 0 ? Field.rust.al(0.85) : Tone(r: 0.239, g: 0.325, b: 0.463).al(0.82),
            wobble: 0.3, taper: false, seed: seed &+ UInt64(b) &+ 71)
        caption(p, "\(b + 1)", at: x0 + panelW / 2, top - 20, size: 24,
                colour: b == 0 ? Field.rust : Field.ink, face: "Georgia-Bold", align: .centre)
        b += 1
    }

    caption(p, "Each panel is one bell's path through two leads. The treble is red.",
            at: Double(W) / 2, top + panelH + 62, size: 20, colour: Field.inkPale,
            face: "Georgia-Italic", align: .centre)
    var y = top + panelH + 112
    for lineText in wrapText(m.ropeSight, width: Double(W) - 320, size: 21) {
        caption(p, lineText, at: Double(W) / 2, y, size: 21, colour: Field.inkSoft,
                align: .centre)
        y += 30
    }

    p.write(dir, "pb_" + m.id, quality: 0.94)
}

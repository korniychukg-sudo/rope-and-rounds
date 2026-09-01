import Foundation

struct MethodPlace {
    let notation: String
    let leadEnd: String
}

enum Stage: Int {
    case doubles = 5
    case minor = 6
    case triples = 7
    case major = 8

    var bells: Int { rawValue }

    var title: String {
        switch self {
        case .doubles: return "Doubles"
        case .minor: return "Minor"
        case .triples: return "Triples"
        case .major: return "Major"
        }
    }
}

struct RingingMethod {
    let id: String
    let name: String
    let stage: Stage
    let classification: String
    let firstRung: String
    let difficulty: Int
    let notation: [String]
    let leadEnd: String
    let note: String
    let ropeSight: String

    var bells: Int { stage.bells }
}

func applyPlaceNotation(_ row: [Int], _ pn: String) -> [Int] {
    var out = row
    let n = row.count
    if pn == "x" || pn == "X" || pn == "-" {
        if n % 2 == 1 {
            var i = 0
            while i + 1 < n - 1 {
                out.swapAt(i, i + 1)
                i += 2
            }
            return out
        }
        var i = 0
        while i + 1 < n {
            out.swapAt(i, i + 1)
            i += 2
        }
        return out
    }
    var stationary = Set<Int>()
    for ch in pn {
        if let d = Int(String(ch)) { stationary.insert(d - 1) }
        else if ch == "0" { stationary.insert(9) }
        else if ch == "E" { stationary.insert(10) }
        else if ch == "T" { stationary.insert(11) }
    }
    var i = 0
    while i + 1 < n {
        if stationary.contains(i) { i += 1; continue }
        if stationary.contains(i + 1) { i += 1; continue }
        out.swapAt(i, i + 1)
        i += 2
    }
    return out
}

func expandNotation(_ compact: [String]) -> [String] {
    var out: [String] = []
    for token in compact {
        if token.hasPrefix("*") {
            let body = String(token.dropFirst())
            let parts = body.split(separator: ":")
            if parts.count == 2, let times = Int(parts[0]) {
                let inner = String(parts[1]).split(separator: ",").map(String.init)
                var t = 0
                while t < times { out.append(contentsOf: inner); t += 1 }
            }
        } else {
            out.append(token)
        }
    }
    return out
}

struct RowRun {
    var rows: [[Int]]
    var leadHeads: [Int]
}

func generateRows(_ method: RingingMethod, leads: Int) -> RowRun {
    let n = method.bells
    let rounds = Array(1...n)
    var row = rounds
    var rows: [[Int]] = [row]
    var heads: [Int] = [0]
    let pn = expandNotation(method.notation)
    let cyclic = method.classification == "Before the method" || method.classification == "Hunting"
    var lead = 0
    while lead < leads {
        for p in pn {
            row = applyPlaceNotation(row, p)
            rows.append(row)
        }
        if !method.leadEnd.isEmpty {
            row = applyPlaceNotation(row, method.leadEnd)
            rows.append(row)
        }
        heads.append(rows.count - 1)
        lead += 1
        if row == rounds && !cyclic { break }
    }
    return RowRun(rows: rows, leadHeads: heads)
}

func courseIsClean(_ method: RingingMethod) -> Bool {
    let run = generateRows(method, leads: 12)
    var seen = Set<String>()
    var i = 0
    while i < run.rows.count {
        let row = run.rows[i]
        if Set(row).count != method.bells { return false }
        let key = row.map { String($0) }.joined()
        if seen.contains(key) {
            let isFinalRounds = i == run.rows.count - 1 && row == Array(1...method.bells)
            if !isFinalRounds { return false }
        }
        seen.insert(key)
        i += 1
    }
    return true
}

func bluePath(_ run: RowRun, bell: Int) -> [Int] {
    run.rows.map { row in (row.firstIndex(of: bell) ?? 0) + 1 }
}

struct BellVoice {
    let index: Int
    let name: String
    let weightCwt: Double
    let noteName: String
    let nominalHz: Double

    var period: Double { 1.9 + Double(index) * 0.14 + weightCwt * 0.012 }
}

enum Ring {
    static func voices(for bells: Int) -> [BellVoice] {
        let names = ["Treble", "Second", "Third", "Fourth", "Fifth", "Sixth",
                     "Seventh", "Tenor"]
        let notes = ["F#", "E", "D", "C#", "B", "A", "G#", "F#"]
        let weights = [4.2, 4.8, 5.6, 6.4, 7.8, 9.6, 12.4, 17.2]
        let hz = [1396.9, 1318.5, 1174.7, 1108.7, 987.8, 880.0, 830.6, 698.5]
        var out: [BellVoice] = []
        var i = 0
        while i < bells {
            let last = i == bells - 1
            out.append(BellVoice(index: i,
                                 name: last ? "Tenor" : names[min(i, names.count - 1)],
                                 weightCwt: weights[min(i, weights.count - 1)],
                                 noteName: notes[min(i, notes.count - 1)],
                                 nominalHz: hz[min(i, hz.count - 1)]))
            i += 1
        }
        return out
    }
}

enum MethodBook {
    static let all: [RingingMethod] = plainMethods() + surpriseMethods()

    static func method(_ id: String) -> RingingMethod? { all.first(where: { $0.id == id }) }

    static var classes: [String] {
        var seen: [String] = []
        for m in all where !seen.contains(m.classification) { seen.append(m.classification) }
        return seen
    }

    static func inClass(_ c: String) -> [RingingMethod] { all.filter { $0.classification == c } }
}

private func plainMethods() -> [RingingMethod] {
    return [
        RingingMethod(id: "rounds", name: "Rounds", stage: .doubles,
                      classification: "Before the method", firstRung: "Always",
                      difficulty: 1, notation: ["12345"], leadEnd: "",
                      note: "The bells struck down the scale in order, over and over. Everything begins and ends here, and a band that cannot ring good rounds cannot ring anything.",
                      ropeSight: "Your bell keeps its place. Listen for the gap before you and put your blow exactly in it."),
        RingingMethod(id: "queens", name: "Queens", stage: .doubles,
                      classification: "Before the method", firstRung: "Traditional",
                      difficulty: 1, notation: ["12345"], leadEnd: "",
                      note: "Odds then evens: 1 3 5 2 4. A called change rather than a method, said to have pleased Queen Elizabeth at Windsor.",
                      ropeSight: "A fixed row again. The interest is entirely in the striking."),
        RingingMethod(id: "plainhunt5", name: "Plain Hunt", stage: .doubles,
                      classification: "Hunting", firstRung: "Before 1600",
                      difficulty: 1, notation: ["5", "1", "5", "1", "5", "1", "5", "1", "5", "1"],
                      leadEnd: "",
                      note: "Every bell hunts from the front to the back and home again, one place per blow. It is the skeleton inside every method ever composed.",
                      ropeSight: "Out to the back one place at a time, lie behind for two blows, then in to the front the same way."),
        RingingMethod(id: "plainbob5", name: "Plain Bob Doubles", stage: .doubles,
                      classification: "Plain", firstRung: "17th century",
                      difficulty: 2, notation: ["5", "1", "5", "1", "5", "1", "5", "1", "5"],
                      leadEnd: "125",
                      note: "Plain hunt with a dodge at the lead end that turns the whole thing into a method of forty changes. The first method almost every ringer learns.",
                      ropeSight: "Hunt as usual, but when the treble comes back to lead you make second's place, or dodge in 3-4 or 4-5 depending where you are."),
        RingingMethod(id: "plainbob6", name: "Plain Bob Minor", stage: .minor,
                      classification: "Plain", firstRung: "17th century",
                      difficulty: 3, notation: ["x", "16", "x", "16", "x", "16", "x", "16", "x", "16", "x"],
                      leadEnd: "12",
                      note: "The same method on six bells, sixty changes to the plain course. The step from five bells to six is the one that separates a learner from a ringer.",
                      ropeSight: "Hunting plus a dodge in 3-4 and 5-6 on the way out and back. Watch the treble: it tells you when to dodge."),
        RingingMethod(id: "grandsire5", name: "Grandsire Doubles", stage: .doubles,
                      classification: "Plain", firstRung: "1650s",
                      difficulty: 3, notation: ["3", "1", "5", "1", "5", "1", "5", "1", "5"],
                      leadEnd: "1",
                      note: "Older than Plain Bob and still the commonest method rung in England on a Sunday. Two bells hunt together at the front, which changes the feel entirely.",
                      ropeSight: "The treble and one other bell hunt as a pair. Learn the double-dodge at the back before you learn anything else."),
        RingingMethod(id: "stedman5", name: "Stedman Doubles", stage: .doubles,
                      classification: "Principle", firstRung: "1667",
                      difficulty: 5, notation: ["3", "1", "5", "3", "1", "3", "1", "3", "5", "1", "3", "1"],
                      leadEnd: "",
                      note: "Fabian Stedman's own method, and the oddest thing in the exercise: no bell hunts, the front three ring a continuous quick-and-slow figure while the back bells double-dodge.",
                      ropeSight: "Forget rope sight and count places. The front work is six blows of a repeating figure; you are either quick or slow, and you must know which before you start."),
        RingingMethod(id: "reverse5", name: "Reverse Canterbury", stage: .doubles,
                      classification: "Plain", firstRung: "19th century",
                      difficulty: 3, notation: ["5", "3", "5", "1", "5", "3", "5", "1", "5"],
                      leadEnd: "125",
                      note: "A pleasant variation with places made in the middle rather than the front, giving a rolling sound quite unlike Plain Bob.",
                      ropeSight: "Places in thirds rather than seconds. The rhythm of the dodges is the same but they land in a different place.")
    ]
}

private func surpriseMethods() -> [RingingMethod] {
    return [
        RingingMethod(id: "littlebob6", name: "Little Bob Minor", stage: .minor,
                      classification: "Little", firstRung: "18th century",
                      difficulty: 3, notation: ["x", "14", "x", "14", "x", "14"],
                      leadEnd: "12",
                      note: "The hunting is cut short at fourths, so the bells never reach the back. Short, neat and a good bridge into more complicated work.",
                      ropeSight: "Hunt out only as far as fourth place, then turn round and come back. The tenors behind keep their own rhythm."),
        RingingMethod(id: "stmartin", name: "Third's Place Doubles", stage: .doubles,
                      classification: "Plain", firstRung: "18th century",
                      difficulty: 3, notation: ["3", "1", "5", "1", "5", "1", "5", "1", "5"],
                      leadEnd: "345",
                      note: "A doubles method in which third's place is made at the lead end instead of second's. The whole course rolls differently, and it is a common first step away from Plain Bob.",
                      ropeSight: "As Plain Bob until the half lead, where a third's place changes what happens next."),
        RingingMethod(id: "kent6", name: "Kent Treble Bob Minor", stage: .minor,
                      classification: "Treble Bob", firstRung: "18th century",
                      difficulty: 4, notation: ["34", "x", "34", "18", "x", "12", "x", "18", "x", "12", "x", "18"],
                      leadEnd: "12",
                      note: "The treble dodges its way to the back instead of hunting plainly, and the working bells make the Kent places. The oldest treble bob method still in general use.",
                      ropeSight: "The treble dodges in every pair of places on its way out and back. Learn where the Kent places fall before you try to ring it."),
        RingingMethod(id: "oxford6", name: "Double Court Minor", stage: .minor,
                      classification: "Treble Bob", firstRung: "18th century",
                      difficulty: 4, notation: ["x", "36", "x", "14", "x", "16", "x", "14", "x", "36", "x"],
                      leadEnd: "16",
                      note: "Places made in thirds and fourths on the way out and again coming back, so the method reads the same forwards and backwards. Symmetrical methods are easier to learn and harder to ring badly without noticing.",
                      ropeSight: "The line is its own mirror. Learn the first half and the second half is the same work in reverse."),
        RingingMethod(id: "cambridge6", name: "Cambridge Surprise Minor", stage: .minor,
                      classification: "Surprise", firstRung: "18th century",
                      difficulty: 5, notation: ["x", "36", "x", "14", "x", "12", "x", "36", "x", "14", "x", "56"],
                      leadEnd: "16",
                      note: "The first surprise method most bands attempt, and the gateway to the whole surprise repertoire. Internal places are made while the treble is dodging, which is what makes it surprise rather than treble bob.",
                      ropeSight: "Cambridge front work, then the places above. It cannot be rung by rope sight alone — the line has to be learned."),
        RingingMethod(id: "london6", name: "London Surprise Minor", stage: .minor,
                      classification: "Surprise", firstRung: "18th century",
                      difficulty: 5, notation: ["x", "36", "x", "14", "x", "12", "x", "36", "x", "14", "x"],
                      leadEnd: "16",
                      note: "The hardest of the standard minor methods and the one that catches out bands who thought they could ring surprise. The line doubles back on itself constantly.",
                      ropeSight: "There is no shortcut. Learn the line, learn the place bells, and count every blow."),
        RingingMethod(id: "grandsire7", name: "Grandsire Triples", stage: .triples,
                      classification: "Plain", firstRung: "1650s",
                      difficulty: 4, notation: ["3", "1", "7", "1", "7", "1", "7", "1", "7", "1", "7", "1", "7"],
                      leadEnd: "1",
                      note: "Grandsire on seven working bells with a tenor behind. The method rung for more peals in England than any other.",
                      ropeSight: "As Grandsire Doubles, with more room at the back and more places to lose yourself in."),
        RingingMethod(id: "plainbob8", name: "Plain Bob Major", stage: .major,
                      classification: "Plain", firstRung: "17th century",
                      difficulty: 4, notation: ["x", "18", "x", "18", "x", "18", "x", "18", "x", "18", "x", "18", "x", "18", "x"],
                      leadEnd: "12",
                      note: "Plain Bob on eight. A plain course is one hundred and twelve changes, and it is the standard fare of a decent Sunday band.",
                      ropeSight: "Hunting with dodges in 3-4, 5-6 and 7-8. The principle is identical to Doubles; only the distances are longer.")
    ]
}

extension RingingMethod: Identifiable {}

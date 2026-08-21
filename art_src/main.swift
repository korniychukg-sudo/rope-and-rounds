import Foundation

let args = CommandLine.arguments
let outDir = args.count > 1 ? args[1] : "./out"
let iconDir = args.count > 2 ? args[2] : outDir
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let mode = args.count > 3 ? args[3] : "all"

if mode == "all" || mode == "material" {
    makeMaterials(dir: outDir)
    print("materials done")
}
if mode == "all" || mode == "icon" {
    makeIcon(dir: iconDir)
    print("icon done")
}
if mode == "all" || mode == "meth" {
    var n = 0
    for m in MethodBook.all {
        methodPlate(m, dir: outDir)
        rowsPlate(m, dir: outDir)
        placeBellsPlate(m, dir: outDir)
        n += 1
        if n % 6 == 0 { print("method plates \(n)/\(MethodBook.all.count)") }
    }
    print("method plates done")
}

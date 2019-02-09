#!/usr/bin/swift

import Foundation

guard CommandLine.arguments.count == 2 else {
    print("Syntax: to_plist [Localizable.strings]")
    exit(0)
}

guard let data = try? NSString(contentsOfFile: CommandLine.arguments[1], encoding: 4) as String else {
    print("Invalid Localizable.strings file provided")
    exit(0)
}

let lines = data.split(separator: "\n")

for i in 0..<(lines.count / 2) {
    let comment = String(String(String(lines[i * 2]).dropFirst(3)).dropLast(3))

    var quoteComponents = String(lines[i * 2 + 1]).split(separator: "\"")

    var key = String(quoteComponents.dropFirst())
    while key[-1] == "\\" {
        key += key.popFirst()
    }

    print("comment: \(comment), key: \(key)")
}

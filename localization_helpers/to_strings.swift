#!/usr/bin/swift

import Foundation

guard CommandLine.arguments.count == 2 else {
    print("Syntax: to_strings [Localizable.plist]")
    exit(0)
}

guard let localizableDictionary = NSDictionary(contentsOfFile: CommandLine.arguments[1]) as Dictionary<String, Any> else {
    print("Invalid Localizable.plist file provided")
    exit(0)
}


for key in localizableDictionary.allKeys {
    let comment = localizableDictionary.value(forKey: key as! String)?.value(forKey: "comment") as! String
    let value = localizableDictionary.value(forKey: key as! String)?.valueForKey("value") as! String
    
    print("/* \(comment) */")
    print("\"\(key)\" = \"\(value)\";\n")
}

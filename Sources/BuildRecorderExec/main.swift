//
//  main.swift
//  
//
//  Created by MainasuK on 2023-07-13.
//

import Foundation

let arguments = ProcessInfo().arguments
guard arguments.count > 1 else {
    print("missing arguments")
    exit(1)
}

let path = arguments[1]

let now = Date()
let timestamp = now.timeIntervalSince1970

var generatedCode = """
import Foundation

public enum BuildRecord {
    public static let timestamp = Date(timeIntervalSince1970: \(timestamp))
}

"""

try generatedCode.write(
    to: URL(fileURLWithPath: path),
    atomically: true,
    encoding: .utf8
)

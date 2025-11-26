//
//  Storage.swift
//  rules
//
//  Created by 4 on '25.11.25.
//

import SwiftUI

class Storage {
    static func dictionary(_ key: Key) -> [String: Any]? {
        UserDefaults.standard.dictionary(forKey: key.rawValue)
    }
    
    static func int(_ key: Key) -> Int {
        UserDefaults.standard.integer(forKey: key.rawValue)
    }
    
    static func bool(_ key: Key) -> Bool {
        UserDefaults.standard.bool(forKey: key.rawValue)
    }
    
    
    static func string(_ key: Key) -> String? {
        UserDefaults.standard.string(forKey: key.rawValue)
    }
    
    
    static func array(_ key: Key) -> [Any]? {
        UserDefaults.standard.array(forKey: key.rawValue)
    }
    
    static func set(_ value: Any?, for key: Key) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }
    
    
    static func getDate(of key: Key) -> TimeInterval {
        return getDouble(for: key)
    }
    
    static func getDouble(for key: Key) -> Double {
        UserDefaults.standard.double(forKey: key.rawValue)
    }
    
    static func getSavedTimes() -> [TimeInterval] {
        return array(.times) as? [TimeInterval] ?? []
    }
}

enum Key: String {
    case times = "times"
}


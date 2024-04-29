//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/17.
//

import Foundation

extension Dictionary {
    
    public var queryString: String {
        map({
            let value = "\($1)".urlEncoding
            return "\($0)=\(value)"
        }).joined(separator: "&")
    }
}

extension Dictionary where Key: Comparable {
    
    public var sortedQueryString: String {
        keys.sorted(by: ({ $0 < $1 })).map({
            let value = "\(self[$0]!)".urlEncoding
            return "\($0)=\(value)"
        }).joined(separator: "&")
    }
}


extension Dictionary {
    
    mutating public func filter(with keys: Set<Key>, excepted: Bool = false) {
        guard !keys.isEmpty else { return }
        self = filter { keys.contains($0.key) != excepted }
    }
    
    mutating public func merge(_ other: Self, _ keyMapping: Dictionary<Key, Key>) {
        if keyMapping.isEmpty {
            _ = other.map { self[$0] = $1 }
        } else {
            _ = keyMapping.map { self[$0] = other[$1] }
        }
    }
}

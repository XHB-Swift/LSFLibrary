//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/10.
//

import Foundation

public struct Stack<T> {
    
    internal var storage: DoubleLinkList<T> = .init()
    
    public var isEmpty: Bool { count == 0 }
    public var count: Int { storage.count }
    
    public init() {}
    
    public func push(_ value: T) {
        storage.insert(first: value)
    }
    
    public func pop() -> T? {
        storage.removeFirst()
    }
    
    public func peek() -> T? {
        storage.first
    }
    
    public func removeAll() {
        storage.removeAll()
    }
}

extension Stack: Sequence {
    public typealias Element = T
    public typealias Iterator = DoubleLinkList<T>.Iterator
    
    public func makeIterator() -> Iterator {
        storage.makeIterator()
    }
}

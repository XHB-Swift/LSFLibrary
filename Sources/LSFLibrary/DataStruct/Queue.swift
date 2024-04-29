//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/9.
//

import Foundation


public struct Queue<T> {
    
    internal var storage: DoubleLinkList<T> = .init()
    
    public var isEmpty: Bool { count == 0 }
    public var count: Int { storage.count }
    
    public init() {}
    
    public mutating func enqueue(_ element: T) {
        storage.append(node: .init(storage: element))
    }
    
    public mutating func dequeue() -> T? {
        storage.removeFirst()
    }
    
    public mutating func peek() -> T? {
        storage.first
    }
    
    public mutating func removeAll() {
        storage.removeAll()
    }
}

extension Queue : Sequence {
    
    public typealias Element = T
    public typealias Iterator = DoubleLinkList<T>.Iterator
    
    public func makeIterator() -> Iterator {
        storage.makeIterator()
    }
}

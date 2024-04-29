//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/9.
//

import Foundation

public struct DoubleLinkList<T> {
    
    internal let list: List
    
    public init() {
        self.list = .init()
    }
}

extension DoubleLinkList {
    
    public var count: Int { list.count }
    
    public var first: T? { list.first?.storage }
    public var last: T? { list.last?.storage }
    
    public func insert(first value: T) {
        list.insert(first: .init(storage: value))
    }
    
    public func append(_ value: T) {
        list.append(node: .init(storage: value))
    }
    
    public func reversed() {
        list.reversed()
    }
    
    public func removeFirst() -> T? {
        removeFirstNode()?.storage
    }
    
    public func removeLast() -> T? {
        removeLastNode()?.storage
    }
    
    public func removeAll() {
        list.removeAll()
    }
}

extension DoubleLinkList {
    
    internal func insert(first node: List.Node) {
        list.insert(first: node)
    }
    
    internal func append(node: List.Node) {
        list.append(node: node)
    }
    
    internal func remove(node: List.Node) {
        list.remove(node: node)
    }
    
    internal func moveTo(first node: List.Node) {
        list.moveTo(first: node)
    }
    
    @discardableResult
    internal func removeFirstNode() -> List.Node? {
        list.removeFirst()
    }
    
    @discardableResult
    internal func removeLastNode() -> List.Node? {
        list.removeLast()
    }
}

extension DoubleLinkList {
    
    internal final class List {
        private(set) var count = 0
        internal var first: Node?
        internal var last: Node?
        internal var reversedFlag: Bool = false
        
        internal func insert(first node: Node) {
            node.rear = first
            first?.front = node
            first = node
        }
        
        internal func append(node: Node) {
            node.front = last
            last?.rear = node
            last = node
            if (first == nil) {
                first = last
            }
        }
        
        internal func remove(node: Node) {
            let front = node.front
            let rear = node.rear
            front?.rear = rear
            rear?.front = front
            node.front = nil
            node.rear = nil
        }
        
        @discardableResult
        internal func removeFirst() -> Node? {
            guard let _first = first else { return nil }
            remove(node: _first)
            first = _first.rear
            return _first
        }
        
        @discardableResult
        internal func removeLast() -> Node? {
            guard let _last = last else { return nil }
            remove(node: _last)
            last = _last.front
            return _last
        }
        
        internal func moveTo(first node: Node) {
            remove(node: node)
            insert(first: node)
        }
        
        internal func reversed() {
            reversedFlag = !reversedFlag
        }
        
        internal func removeAll() {
            first = nil
            last = nil
            count = 0
        }
        
        internal final class Node: NodeProtocol {
            var storage: T
            var front: Node?
            var rear: Node?
            
            init(storage: T, front: Node? = nil, rear: Node? = nil) {
                self.storage = storage
                self.front = front
                self.rear = rear
            }
        }
    }
}

extension DoubleLinkList : Sequence {
    public typealias Element = T
    
    public struct Iterator : IteratorProtocol {
        
        public typealias Element = T
        
        internal var reversedFlag: Bool
        internal var front: DoubleLinkList<T>.List.Node?
        internal var rear: DoubleLinkList<T>.List.Node?
        internal var node: DoubleLinkList<T>.List.Node?
        
        internal init(list: List) {
            self.front = list.first
            self.rear = list.last
            self.node = list.reversedFlag ? self.rear : self.front
            self.reversedFlag = list.reversedFlag
        }
        
        public mutating func next() -> Element? {
            let storage = node?.storage
            node = self.reversedFlag ? node?.front : node?.rear
            return storage
        }
    }
    
    public func makeIterator() -> Iterator {
        .init(list: list)
    }
}

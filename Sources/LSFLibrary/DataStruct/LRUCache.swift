//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/9.
//

import Foundation

public struct LRUCache<Key, Value> where Key: Hashable {
    
    fileprivate let storage: Storage
    
    public var cachedDict: [Key: Value] {
        return storage.cachedDict
    }
    
    public init(capacity: Int) {
        storage = .init(capacity: capacity)
    }
    
    public func set(value: Value, for key: Key) {
        storage.set(value: value, for: key)
    }
    
    public func value(for key: Key) -> Value? {
        storage.value(for: key)
    }
    
    @discardableResult
    public func removeValue(for key: Key) -> Value? {
        return storage.removeValue(for: key)
    }
}

extension LRUCache {
    
    fileprivate final class Storage {
        
        fileprivate typealias LinkNode = DoubleLinkList<Value>.List.Node
        
        fileprivate var capacity = 0
        fileprivate var linkList: DoubleLinkList<Value> = .init()
        fileprivate var dict: [Key: LinkNode] = [:]
        
        fileprivate var cachedDict: [Key: Value] {
            var _dict: [Key: Value] = .init()
            
            _ = dict.map({ _dict[$0] = $1.storage })
            
            return _dict
        }
        
        fileprivate init(capacity: Int) {
            self.capacity = capacity
        }
        
        fileprivate func set(value: Value, for key: Key) {
            if let node = dict[key] {
                node.storage = value
                dict[key] = node
                linkList.moveTo(first: node)
            } else {
                let node: LinkNode = .init(storage: value)
                dict[key] = node
                linkList.insert(first: node)
            }
            if dict.count > capacity {
                guard let last = linkList.removeLastNode(),
                      let nodeIndex = dict.firstIndex(where: { $0.value === last })
                else { return }
                dict.remove(at: nodeIndex)
            }
        }
        
        fileprivate func value(for key: Key) -> Value? {
            dict[key]?.storage
        }
        
        @discardableResult
        fileprivate func removeValue(for key: Key) -> Value? {
            guard let node = dict[key] else { return nil }
            dict.removeValue(forKey: key)
            linkList.remove(node: node)
            return node.storage
        }
    }
}

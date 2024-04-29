//
//  Thread.swift
//
//
//  Created by 谢鸿标 on 2024/4/25.
//

import Foundation

public protocol Lockable: AnyObject {
    
    func lock()
    func unlock()
}

@inlinable
public func run_async(_ inMain: Bool = true, _ completion: @escaping () -> Void) {
    if inMain {
        if Thread.isMainThread {
            completion()
        } else {
            DispatchQueue.main.async(execute: completion)
        }
    } else {
        completion()
    }
}

public enum Lock {
    ///系统自旋锁
    @available(iOS 10.0, OSX 10.12, watchOS 3.0, tvOS 10.0, *)
    public final class OSUnfair: Lockable {
        
        private var _lock = os_unfair_lock_s()
        
        public func lock() {
            os_unfair_lock_lock(&_lock)
        }
        
        public func unlock() {
            os_unfair_lock_unlock(&_lock)
        }
    }

    ///互斥锁
    public final class Mutex: Lockable {
        
        private var _lock = pthread_mutex_t()
        
        public init() {
            pthread_mutex_init(&_lock, nil)
        }
        
        deinit {
            pthread_mutex_destroy(&_lock)
        }
        
        public func lock() {
            pthread_mutex_lock(&_lock)
        }
        
        public func unlock() {
            pthread_mutex_unlock(&_lock)
        }
    }

    ///递归锁
    public final class Recursive: Lockable {
        
        private var _lock = pthread_mutex_t()
        
        public init() {
            var attr = pthread_mutexattr_t()
            pthread_mutexattr_init(&attr)
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
            pthread_mutex_init(&_lock, &attr)
        }
        
        deinit {
            pthread_mutex_destroy(&_lock)
        }
        
        public func lock() {
            pthread_mutex_lock(&_lock)
        }

        public func unlock() {
            pthread_mutex_unlock(&_lock)
        }
    }

    ///条件锁
    public final class Condition: Lockable {
        
        private var _lock1 = pthread_cond_t()
        private var _lock2 = pthread_mutex_t()
        
        public init() {
            pthread_cond_init(&_lock1, nil)
            pthread_mutex_init(&_lock2, nil)
        }
        
        deinit {
            pthread_cond_destroy(&_lock1)
            pthread_mutex_destroy(&_lock2)
        }
        
        public func lock() {
            pthread_mutex_lock(&_lock2)
        }
        
        public func unlock() {
            pthread_mutex_unlock(&_lock2)
        }
        
        public func wait(until time: TimeInterval) {
            let integerPart = Int(time.nextDown)
            let fractionPart = time - TimeInterval(integerPart)
            var pthread_time = timespec(tv_sec: integerPart, tv_nsec: Int(fractionPart * 1000000000))
            pthread_cond_timedwait_relative_np(&_lock1, &_lock2, &pthread_time)
        }
        
        public func wait() {
            pthread_cond_wait(&_lock1, &_lock2)
        }
        
        public func signal() {
            pthread_cond_signal(&_lock1)
        }
    }

    ///自旋锁实现
    public final class Spin: Lockable {
        
        private let _lock: Lockable
        
        public init() {
            if #available(iOS 10.0, macOS 10.12, watchOS 3.0, tvOS 10.0, *) {
                _lock = OSUnfair()
            } else {
                _lock = Mutex()
            }
        }

        public func lock() {
            _lock.lock()
        }
        
        public func unlock() {
            _lock.unlock()
        }
    }
    
    ///ObjC的@synchronized实现
    public final class Synchronized: Lockable {
        
        public init() {}
        
        public func lock() {
            objc_sync_enter(self)
        }
        
        public func unlock() {
            objc_sync_exit(self)
        }
    }
}

extension DispatchQueue {
    
    fileprivate static let spin = Lock.Spin()
    fileprivate static var pool = Set<String>()
    
    ///GCD实现一次执行
    public static func once(name: String, _ block: () -> Void) {
        spin.lock(); defer { spin.unlock() }
        guard !pool.contains(name) else { return }
        block()
        pool.insert(name)
    }
}

@propertyWrapper
public struct LockableValue<T, L> where L: Lockable {
    
    private var value: T
    private var lock: L
    
    public var projectedValue: LockableValue<T, L> {
        get { self }
        set { self = newValue }
    }
    
    public var wrappedValue: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            value = newValue
        }
    }
    
    public init(wrappedValue: T, lock: L) {
        self.value = wrappedValue
        self.lock = lock
    }
    
    mutating public func with(_ closure: (T) -> T) {
        lock.lock()
        defer { lock.unlock() }
        value = closure(value)
    }
    
    mutating public func with(_ closure: (inout T) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        closure(&value)
    }
}

extension LockableValue where T: Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
    
    public static func == (lhs: Self, rhs: T) -> Bool {
        lhs.wrappedValue == rhs
    }
}

extension LockableValue where T == Int {
    
    public static func += (lhs: inout Self, rhs: T) {
        lhs.with({ $0 + rhs })
    }
    
    public static func += (lhs: inout Self, rhs: Self) {
        lhs.with({ $0 + rhs.value })
    }
    
    public static func -= (lhs: inout Self, rhs: T) {
        lhs.with({ $0 - rhs })
    }
    
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs.with({ $0 - rhs.value })
    }
}

extension LockableValue where L == Lock.OSUnfair {
    public init(wrappedValue: T) {
        self.init(wrappedValue: wrappedValue, lock: .init())
    }
}

extension LockableValue where L == Lock.Mutex {
    public init(wrappedValue: T) {
        self.init(wrappedValue: wrappedValue, lock: .init())
    }
}

extension LockableValue where L == Lock.Recursive {
    public init(wrappedValue: T) {
        self.init(wrappedValue: wrappedValue, lock: .init())
    }
}

extension LockableValue where L == Lock.Synchronized {
    public init(wrappedValue: T) {
        self.init(wrappedValue: wrappedValue, lock: .init())
    }
}

public typealias Atmoic<T> = LockableValue<T, Lock.OSUnfair>

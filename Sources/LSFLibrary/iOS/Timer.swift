//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/23.
//

import UIKit

extension Timer {
    
    public typealias Handler = (_ interval: TimeInterval, _ suspended: TimeInterval) -> Void
    
    private static var SuspendedKey: Void?
    
    private var suspendedInterval: TimeInterval {
        get {
            objc_getAssociatedObject(self, &Timer.SuspendedKey) as? TimeInterval ?? 0
        }
        set {
            objc_setAssociatedObject(self, &Timer.SuspendedKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    public static func start(with interval: TimeInterval,
                             commonModes: Bool = true,
                             repeats: Bool = true,
                             handler: @escaping Handler) -> Timer {
        
        let timer = Timer.scheduledTimer(timeInterval: interval, 
                                         target: self,
                                         selector: #selector(handlerAction(_:)),
                                         userInfo: handler,
                                         repeats: repeats)
        
        RunLoop.current.add(timer, forMode: commonModes ? .common : .default)
        
        timer.addObservers()
        
        return timer
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        suspendedInterval = Date().timeIntervalSince1970
    }
    
    @objc private func appWillEnterForeground() {
        let handler = userInfo as? Handler
        handler?(timeInterval, Date().timeIntervalSince1970 - suspendedInterval)
    }
    
    @objc private static func handlerAction(_ sender: Timer) {
        let handler = sender.userInfo as? Handler
        handler?(sender.timeInterval, 0)
    }
    
    public func stop() {
        invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

extension CADisplayLink {
    
    public typealias Handler = (TimeInterval) -> Void
    private static var HandlerKey: Void?
    
    private var handler: Handler? {
        get {
            objc_getAssociatedObject(self, &CADisplayLink.HandlerKey) as? Handler
        }
        set {
            objc_setAssociatedObject(self, &CADisplayLink.HandlerKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    public static func scheduled(in commonModes: Bool = true, handler: @escaping Handler) -> CADisplayLink {
        let displayLink: CADisplayLink = .init(target: self, selector: #selector(handlerAction(_:)))
        displayLink.handler = handler
        displayLink.add(to: .main, forMode: commonModes ? .common : .default)
        return displayLink
    }
    
    @objc private static func handlerAction(_ sender: CADisplayLink) {
        sender.handler?(sender.duration)
    }
}


public final class GCDTimer {
    
    public typealias Handler = (_ interval: TimeInterval, _ suspended: TimeInterval) -> Void
    
    private var repeats = false
    private var interval: TimeInterval = 0
    private var suspendedInterval: TimeInterval = 0
    private var timerQueue = DispatchQueue(label: "com.apple.swift.queue.timer")
    private var timer: DispatchSourceTimer? = nil
    private var handler: Handler? = nil
    
    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }
    
    public init(repeats: Bool = false,
                interval: TimeInterval,
                suspendedInterval: TimeInterval,
                handler: Handler? = nil) {
        self.repeats = repeats
        self.interval = interval
        self.suspendedInterval = suspendedInterval
        self.handler = handler
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        suspendedInterval = Date().timeIntervalSince1970
    }
    
    @objc private func appWillEnterForeground() {
        handlerAction(Date().timeIntervalSince1970 - suspendedInterval)
    }
    
    public func start() {
        if timer != nil { return }
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.setEventHandler(handler: { [weak self] in
            self?.handlerAction(0)
        })
        timer?.schedule(deadline: .now(), repeating: interval, leeway: .seconds(0))
    }
    
    public func stop() {
        if timer == nil { return }
        timer?.cancel()
        timer = nil
    }
    
    private func handlerAction(_ interval: TimeInterval) {
        runAsync {
            if self.timer == nil { return }
            self.handler?(self.interval, interval)
            if !self.repeats { self.stop() }
        }
    }
}

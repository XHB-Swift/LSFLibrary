//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/12.
//

import UIKit

extension Tween {
    
    public final class Animator {
        
        private let scheduler = Scheduler()
        
    }
}

extension Tween {
    
    fileprivate final class Scheduler {
        
        private var displayLink: CADisplayLink? = nil
        private var lastTimestamp: TimeInterval = 0
        
        fileprivate var updated: ((TimeInterval) -> Void)?
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        fileprivate init() {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(appDidBecomeActive(_:)),
                                                   name: UIApplication.didBecomeActiveNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(appWillResignActive(_:)),
                                                   name: UIApplication.willResignActiveNotification,
                                                   object: nil)
        }
        
        @objc private func appDidBecomeActive(_ sender: Notification) {
            self.lastTimestamp = 0
            self.displayLink?.isPaused = false
        }
        
        @objc private func appWillResignActive(_ sender: Notification) {
            self.displayLink?.isPaused = true
            self.lastTimestamp = 0
        }
        
        @objc private func displayLinkUpdated(_ sender: CADisplayLink) {
            let duration = max(CFAbsoluteTimeGetCurrent() - self.lastTimestamp, 0)
            self.updated?(duration)
        }
        
        fileprivate func start() {
            if self.displayLink != nil { return }
            self.displayLink = .init(target: self, selector: #selector(displayLinkUpdated(_:)))
            self.displayLink?.add(to: .main, forMode: .common)
            self.lastTimestamp = CFAbsoluteTimeGetCurrent()
        }
        
        fileprivate func stop() {
            if self.displayLink != nil {
                self.displayLink?.invalidate()
                self.displayLink = nil
                self.lastTimestamp = 0
            }
        }
    }
}

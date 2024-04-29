//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/12.
//

import Foundation

extension Tween {
    
    public final class Interpolator {
        
        private var easing: Tween.Easing
        private var duration: TimeInterval
        private var v0: Double
        private var vd: Double
        private var v1: Double
        
        public var valueChanged: ((Double) -> Void)?
        
        public init(easing: Tween.Easing,
                    duration: TimeInterval,
                    v0: Double,
                    vd: Double = 0.0,
                    v1: Double) {
            self.easing = easing
            self.duration = duration
            self.v0 = v0
            self.vd = vd
            self.v1 = v1
        }
        
        public func timeChange(_ deltaTime: TimeInterval) {
            if deltaTime >= self.duration {
                self.vd = self.v1;
            } else {
                self.v0 = self.easing.function(deltaTime, self.v0, self.v1 - self.v0, self.duration - deltaTime)
            }
            self.valueChanged?(self.vd)
        }
        
        public func resetValue(_ v0: Double, _ v1: Double) {
            self.v0 = v0;
            self.v1 = v1;
            self.vd = 0;
        }
    }
}

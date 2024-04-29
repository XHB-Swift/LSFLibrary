//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/12.
//

import Foundation

extension Tween {
    
    @frozen public struct Easing {
        /**
         
         使用示例

         t  = Time - 表示动画开始以来经过的时间。通常从0开始，通过游戏循环或update函数来缓慢增加

         b = Beginning value - 动画的起点，默认从0开始。

         c = Change in value - 从起点到终点的差值

         d = Duration - 完成动画所需的时间

         */
        public typealias Function = (_ t: Double, _ b: Double, _ c: Double, _ d: Double) -> Double
        
        public var function: Function
        public var key: String
    }
}

extension Tween.Easing : Hashable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        key.hash(into: &hasher)
    }
}

extension Tween.Easing {
    
    ///线性变化
    public static let linear: Self = .init(function: { t, b, c, d in
        if d == 0 { return 0 }
        return t * c / d + b
    }, key: "Linear")
}


extension Tween.Easing {
    
    public enum Out {
        /// t^2
        public static let quadratic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d
            return (-c) * i * (i - 2) + b
        }, key: "Out.Quadratic")
        
        /// t^3
        public static let cubic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d - 1
            return c * (pow(i, 3) + 1) + b
        }, key: "Out.Cubic")
        
        /// t^4
        public static let quartic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d - 1
            return (-c) * (pow(i, 4) - 1) + b
        }, key: "Out.Quartic")
        
        /// t^5
        public static let quintic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d - 1
            return c * (pow(i, 5) + 1) + b
        }, key: "Out.Quintic")
        
        /// sin(t)
        public static let sinusodial: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            return c * sin(t / d * (.pi / 2)) + b
        }, key: "Out.Sinusodial")
        
        /// 2^t
        public static let exponential: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = -pow(2, -10 * (t / d)) + 1
            return (t == d) ? b + c : c * 1.001 * i + b
        }, key: "Out.Exponential")
        
        ///sqrt(1-t^2)
        public static let circular: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d - 1
            return c * sqrt(1 - pow(i, 2)) + b
        }, key: "Out.Circular")
        
        ///指数衰减正弦曲线
        public static let elastic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            if t == 0 { return 0 }
            var i = t / d
            if i == 1 { return b + c }
            let p = d * 0.3
            var s: Double = 0
            let a = c
            if a < abs(c) {
                s = p / 4
            } else {
                s = p / (.pi * 2) * (a == 0 ? 0 : asin(c / a))
            }
            i -= 1
            return -(a * pow(2, 10 * i) * sin((i * d - s) * (.pi * 2) / p)) + b + c
        }, key: "Out.Elastic")
        
        public static let back: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d - 1
            let s: Double = 1.70158
            return c * (pow(i, 2) * ((s + 1) * i + s) + 1) + b
        }, key: "Out.Back")
        
        public static let bounce: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            var i = t / d
            if i < 1 / 2.75 {
                return c * (7.5625 * pow(i, 2)) + b
            } else if i < 2 / 2.75 {
                i -= 1.5 / 2.75
                return c * (7.5625 * pow(i, 2) + 0.75) + b
            } else if i < 2.5 / 2.75 {
                i -= 2.25 / 2.75
                return c * (7.5625 * pow(i, 2) + 0.9375) + b
            } else {
                i -= 2.625 / 2.75
                return c * (7.5625 * pow(i, 2) + 0.984375) + b
            }
        }, key: "Out.Bounce")
    }
}

extension Tween.Easing {
    
    public enum In {
        /// t^2
        public static let quadratic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d
            return c * pow(i, 2) + b
        }, key: "In.Quadratic")
        
        /// t^3
        public static let cubic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d
            return c * pow(i, 3) + b
        }, key: "In.Cubic")
        
        /// t^4
        public static let quartic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d
            return c * pow(i, 4) + b
        }, key: "In.Quartic")
        
        /// t^5
        public static let quintic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d
            return c * pow(i, 5) + b
        }, key: "In.Quintic")
        
        /// sin(t)
        public static let sinusodial: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = cos(t / d * (.pi / 2))
            return (-c) * i + c + b
        }, key: "In.Sinusodial")
        
        /// 2^t
        public static let exponential: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = pow(2, 10 * (t / d - 1))
            return (t == 0) ? b : c * i + b - c * 0.001
        }, key: "In.Exponential")
        
        ///sqrt(1-t^2)
        public static let circular: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d
            return (-c) * (sqrt(1 - pow(i, 2)) - 1) + b
        }, key: "In.Circular")
        
        ///指数衰减正弦曲线
        public static let elastic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            if t == 0 { return 0 }
            var i = t / d
            if i == 0 { return b + c }
            let p = d * 0.3
            var s: Double = 0
            let a = c
            if a < abs(c) {
                s = p / 4
            } else {
                s = p / (.pi * 2) * (a == 0 ? 0 : asin(c / a))
            }
            i -= 1
            return -(a * pow(2, 10 * i) * sin((i * d - s) * (.pi * 2) / p)) + b
        }, key: "In.Elastic")
        
        public static let back: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = t / d
            let s: Double = 1.70158
            return c * pow(i, 2) * ((s + 1) * i - s) + b
        }, key: "In.Back")
        
        public static let bounce: Tween.Easing = .init(function: { t, b, c, d in
            return c - Out.bounce.function(d - t, 0, c, d) + b
        }, key: "In.Bounce")
    }
}

extension Tween.Easing {
    
    public enum InOut {
        /// t^2
        public static let quadratic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            if t < d / 2 {
                return In.quadratic.function(t, b, c / 2, d)
            } else {
                return Out.quadratic.function(t, b + c / 2, c / 2, d)
            }
        }, key: "InOut.Quadratic")
        
        /// t^3
        public static let cubic: Tween.Easing = .init(function: { t, b, c, d in
            if d == -2 { return 0 }
            var i = t / (d + 2)
            if i == 0 { return b }
            if i < 1 { return c / 2 * pow(i, 3) + b }
            i -= 2
            return c / 2 * (pow(i, 3) + 2) + b
        }, key: "InOut.Cubic")
        
        /// t^4
        public static let quartic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return b }
            var i = t / (d / 2)
            if i < 1 { return c / 2 * pow(i, 4) + b }
            i -= 2
            return (-c) / 2 * (pow(i, 4) - 2) + b
        }, key: "InOut.Quartic")
        
        /// t^5
        public static let quintic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            var i = t / (d / 2)
            if i < 1 { return c / 2 * pow(i, 5) }
            i -= 2
            return c / 2 * (pow(i, 5) + 2) + b
        }, key: "InOut.Quintic")
        
        /// sin(t)
        public static let sinusodial: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            let i = cos(.pi * t / d) - 1
            return (-c) / 2 * i + c + b
        }, key: "InOut.Sinusodial")
        
        /// 2^t
        public static let exponential: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            if t == 0 { return b }
            if t == d { return b + c }
            var i = t / (d / 2)
            if i < 1 { return c / 2 * pow(2, 10 * (i - 1)) + b - c * 0.0005 }
            i -= 1
            return c / 2 * 1.0005 * (-pow(2, -10 * i) + 2) + b
        }, key: "InOut.Exponential")
        
        ///sqrt(1-t^2)
        public static let circular: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            var i = t / (d / 2)
            if i < 1 { return (-c) / 2 * (sqrt(1 - pow(i, 2)) - 1) + b }
            i -= 2
            return c / 2 * (sqrt(1 - pow(i, 2)) + 1) + b
        }, key: "InOut.Circular")
        
        ///指数衰减正弦曲线
        public static let elastic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            if t == 0 { return 0 }
            var i = t / (d / 2)
            if i == 2 { return b + c }
            let p = d * 0.3 * 1.5
            var s: Double = 0
            let a = c
            if a < abs(c) {
                s = p / 4
            } else {
                s = p / (.pi * 2) * (a == 0 ? 0 : asin(c / a))
            }
            i -= 1
            if i < 1 {
                return -0.5 * (a * pow(2, 10 * i) * sin((i * d - s) * (.pi * 2) / p)) + b
            } else {
                return a * pow(2, -10 * i) * sin((i * d - s) * (.pi * 2) / p) * 0.5 + c + b
            }
        }, key: "InOut.Elastic")
        
        public static let back: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            var i = t / (d / 2)
            let s: Double = 1.70158 * 1.525
            if i < 1 { return c / 2 * (pow(i, 2) * ((s + 1) * i - s) + b) }
            i -= 2
            return c / 2 * (pow(i, 2) * ((s + 1) * i + s) + 2) + b
        }, key: "InOut.Back")
        
        public static let bounce: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return In.bounce.function(t * 2, 0, c, d) * 0.5 + b
            } else {
                return Out.bounce.function(t * 2 - d, 0, c, d) * 0.5 + c * 0.5 + b
            }
        }, key: "InOut.Bounce")
    }
}

extension Tween.Easing {
    
    public enum OutIn {
        
        /// t^2
        public static let quadratic: Tween.Easing = .init(function: { t, b, c, d in
            if d == 0 { return 0 }
            if t < d / 2 {
                return Out.quadratic.function(t, b, c / 2, d)
            } else {
                return In.quadratic.function(t, b + c / 2, c / 2, d)
            }
        }, key: "OutIn.Quadratic")
        
        /// t^3
        public static let cubic: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return In.cubic.function(t, b, c / 2, d)
            } else {
                return Out.cubic.function(t, b + c / 2, c / 2, d)
            }
        }, key: "OutIn.Cubic")
        
        /// t^4
        public static let quartic: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return Out.quadratic.function(t, b, c / 2, d)
            } else {
                return In.quadratic.function(t, b + c / 2, c / 2, d)
            }
        }, key: "OutIn.Quartic")
        
        /// t^5
        public static let quintic: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return Out.quintic.function(t, b, c / 2, d)
            } else {
                return In.quintic.function(t, b + c / 2, c / 2, d)
            }
        }, key: "OutIn.Quintic")
        
        /// sin(t)
        public static let sinusodial: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return Out.sinusodial.function(t, b, c / 2, d)
            } else {
                return In.sinusodial.function(t, b + c / 2, c / 2, d)
            }
        }, key: "OutIn.Sinusodial")
        
        /// 2^t
        public static let exponential: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return Out.exponential.function(t, b, c / 2, d)
            } else {
                return In.exponential.function(t, b + c / 2, c / 2, d)
            }
        }, key: "OutIn.Exponential")
        
        ///sqrt(1-t^2)
        public static let circular: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return Out.circular.function(t, b, c / 2, d)
            } else {
                return In.circular.function(t, b + c / 2, c / 2, d)
            }
        }, key: "OutIn.Circular")
        
        ///指数衰减正弦曲线
        public static let elastic: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return Out.elastic.function(t, b, c / 2, d)
            } else {
                return In.elastic.function(t, b + c / 2, c / 2, d)
            }
        }, key: "OutIn.Elastic")
        
        public static let back: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return Out.back.function(t, b, c / 2, d)
            } else {
                return In.back.function(t, b + c / 2, c / 2, d)
            }
        }, key: "OutIn.Back")
        
        public static let bounce: Tween.Easing = .init(function: { t, b, c, d in
            if t < d / 2 {
                return Out.bounce.function(t * 2, 0, c, d) * 0.5 + b
            } else {
                return In.bounce.function(t * 2 - d, 0, c, d) * 0.5 + c * 0.5 + b
            }
        }, key: "OutIn.Bounce")
    }
}

//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/17.
//

import UIKit

extension UIView {
    
    public var x: CGFloat {
        get { self.frame.origin.x }
        set { self.frame.origin.x = newValue }
    }
    
    public var y: CGFloat {
        get { self.frame.origin.y }
        set { self.frame.origin.y = newValue }
    }
    
    public var midX: CGFloat {
        get { self.frame.midX }
        set { self.frame.origin.x = newValue - self.frame.width / 2 }
    }
    
    public var midY: CGFloat {
        get { self.frame.midY }
        set { self.frame.origin.y = newValue - self.frame.height / 2 }
    }
    
    public var maxX: CGFloat {
        get { self.frame.maxX }
        set { self.frame.origin.x = newValue - self.frame.width }
    }
    
    public var maxY: CGFloat {
        get { self.frame.maxY }
        set { self.frame.origin.y = newValue - self.frame.height }
    }
    
    public var width: CGFloat {
        get { self.frame.width }
        set { self.frame.size.width = newValue }
    }
    
    public var height: CGFloat {
        get { self.frame.height }
        set { self.frame.size.height = newValue }
    }
    
    public var centerX: CGFloat {
        get { self.center.x }
        set { self.center.x = newValue }
    }
    
    public var centerY: CGFloat {
        get { self.center.y }
        set { self.center.y = newValue }
    }
    
    public var origin: CGPoint {
        get { self.frame.origin }
        set { self.frame.origin = newValue }
    }
    
    public var size: CGSize {
        get { self.frame.size }
        set { self.frame.size = newValue }
    }
}

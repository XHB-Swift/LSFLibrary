//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/17.
//

import UIKit

extension UIColor {
    
    public convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        let red: CGFloat = .init((hex >> 16) & 0xFF)
        let green: CGFloat = .init((hex >> 8) & 0xFF)
        let blue: CGFloat = .init((hex) & 0xFF)
        self.init(red, green, blue, alpha)
    }
    
    public convenience init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1.0) {
        self.init(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }
}

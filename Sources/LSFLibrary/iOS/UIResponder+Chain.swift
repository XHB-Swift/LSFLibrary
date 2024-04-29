//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/24.
//

import UIKit

extension UIResponder {
    
    @objc func responds(event: Event, from sender: UIResponder) {
        next?.responds(event: event, from: sender)
    }
}

extension UIResponder {
    
    @objc public class Event: NSObject {
        
        public let name: String
        public var value: Any?
        
        public init(name: String, value: Any? = nil) {
            self.name = name
            self.value = value
        }
    }
}

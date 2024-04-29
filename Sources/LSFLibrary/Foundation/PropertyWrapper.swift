//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/21.
//

import Foundation


@propertyWrapper
public struct Trimmed {
    
    private var string = ""
    
    public var wrappedValue: String {
        get { string }
        set { string = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    public init(string: String) {
        self.string = string
    }
}

extension UserDefaults {
    
    @propertyWrapper
    public struct Wrapper<T> {
        
        public let key: String
        public let value: T
        
        public var wrappedValue: T {
            get { UserDefaults.standard.object(forKey: key) as? T ?? value }
            set { UserDefaults.standard.set(newValue, forKey: key) }
        }
    }
}


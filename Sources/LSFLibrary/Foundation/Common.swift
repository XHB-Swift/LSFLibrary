//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/21.
//

import Foundation

@inlinable
public func runAsync(in main: Bool = true, handler: @escaping () -> Void) {
    if (main) {
        if (Thread.isMainThread) {
            handler()
        } else {
            DispatchQueue.main.async(execute: handler)
        }
    } else {
        handler()
    }
}

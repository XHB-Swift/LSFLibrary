//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/9.
//

import Foundation

protocol NodeProtocol {
    associatedtype T
    var storage: T { set get }
}

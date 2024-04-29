//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/23.
//

import Foundation
import CryptoKit
import CommonCrypto

extension String {
    
    public var hex: Int { .init(self, radix: 16) ?? 0 }
    
    public subscript(index: Int) -> Self? {
        if !(0..<count).contains(index) { return nil }
        let targetIndex = self.index(startIndex, offsetBy:index)
        return .init(self[targetIndex])
    }

    public subscript(range: Range<Int>) -> Self? {
        if range.lowerBound < 0 ||
           range.lowerBound >= count ||
           range.upperBound > count {
            return nil
        }
        let index0 = self.index(startIndex, offsetBy: range.lowerBound)
        let index1 = self.index(startIndex, offsetBy: range.upperBound)
        return .init(self[index0..<index1])
    }
    
    public subscript(range: NSRange) -> Self? {
        guard let r: Range = .init(range) else { return nil }
        return self[r]
    }
    
    public func md5(lowerCased: Bool = true) -> Self {
        if isEmpty { return self }
        guard let data = data(using: .utf8) else { return "" }
        let string: String
        if #available(iOS 13, *) {
            string = Insecure.MD5.hash(data: data).map({ String(format: "%02hhx", $0) }).joined()
        } else {
            string = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
                var array: [UInt8] = .init(repeating: 0, count: .init(CC_MD5_BLOCK_BYTES))
                CC_MD5(bytes.baseAddress, .init(data.count), &array)
                return array
            }.map({ String(format: "%02x", $0) }).joined()
        }
        return lowerCased ? string : string.uppercased()
    }
    
    public var base64Encoding: Self? {
        data(using: .utf8)?.base64EncodedString(options: [])
    }
    
    public var base64Decoding: Self? {
        if let data = Data(base64Encoded: self, options: []) {
            return .init(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
}

extension String {
    
    public var urlEncoding: Self {
        var allowedCharacters: CharacterSet = .letters
        allowedCharacters.formUnion(.alphanumerics)
        allowedCharacters.formUnion(.punctuationCharacters)
        allowedCharacters.remove(charactersIn: "!*'();:@&=+$,/?%#[]")
        return addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
    }
    
    public var urlDecoding: Self { removingPercentEncoding ?? "" }
}

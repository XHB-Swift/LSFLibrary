//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/23.
//

import UIKit
import WebKit

public enum JavaScript {}

extension WKWebView {
    
    func send(_ message: [String: String], _ jsMethodHandler: @escaping (String) -> String) {
        do {
            let data = try JSONEncoder().encode(message)
            if let string = formatJSONString(with: data) {
                runAsync {
                    let jsMethod = jsMethodHandler("'\(string)'")
                    self.evaluateJavaScript(jsMethod,
                                            completionHandler: { result, error in
                        if let e = error {
                            print("evaluate js method: \(jsMethod)  error: \(e)")
                        }
                    })
                }
            }
        } catch {
            print("error = \(error)")
        }
    }
    
    func send(_ message: [String: Any], _ jsMethodHandler: @escaping (String) -> String) {
        if !JSONSerialization.isValidJSONObject(message) {
            print("message = \(message) is not a valid json object")
            return
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            if let string = formatJSONString(with: data) {
                let jsMethod = jsMethodHandler("'\(string)'")
                self.evaluateJavaScript(jsMethod,
                                        completionHandler: { result, error in
                    if let e = error {
                        print("evaluate js method: \(jsMethod)  error: \(e)")
                    }
                })
            }
        } catch {
            print("error = \(error)")
        }
    }
    
    private func formatJSONString(with jsonData: Data) -> String? {
        if let string = String(data: jsonData, encoding: .utf8) {
            var jsonString = string.replacingOccurrences(of: "\\", with: "\\\\")
            jsonString = jsonString.replacingOccurrences(of: "\"", with: "\\\"")
            jsonString = jsonString.replacingOccurrences(of: "\'", with: "\\\'")
            jsonString = jsonString.replacingOccurrences(of: "\n", with: "\\n")
            jsonString = jsonString.replacingOccurrences(of: "\r", with: "\\r")
            jsonString = jsonString.replacingOccurrences(of: "\u{0c}", with: "\\u{0c}")
            jsonString = jsonString.replacingOccurrences(of: "\u{2028}", with: "\\u{2028}")
            jsonString = jsonString.replacingOccurrences(of: "\u{2029}", with: "\\u{2029}")
            return jsonString
        }
        return nil
    }
}

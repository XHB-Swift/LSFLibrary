//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/20.
//

import WebKit
import Foundation

extension JavaScript {
    
    public class Bridge: NSObject, WKScriptMessageHandler {
        
        public typealias ResponseCallback = (_ data: String?) -> Void
        public typealias MessageCallback = (_ data: String?, _ responseCallback: ResponseCallback?) -> Void
         
        private weak var webView: WKWebView? = nil
        private var injection: JavaScript.Injection
        private var messageCallbacks: [String: MessageCallback] = [:]
        private var responseCallbacks: [String: ResponseCallback] = [:]
        private var startupMessageQueue: [[String: String]]? = []
        
        public init(webView: WKWebView, 
                    injection: JavaScript.Injection = .init(moduleName: "JSBridger")) {
            self.webView = webView
            self.injection = injection
            super.init()
            let userContentController = webView.configuration.userContentController
            userContentController.add(self, name: injection.nativeCalledFunction)
            userContentController.add(self, name: injection.nativeStartupFunction)
            userContentController.add(self, name: injection.nativeResponseFunction)
            let injectCode = injection.injectCode()
            if !injectCode.isEmpty {
                let script = WKUserScript(source: injectCode,
                                          injectionTime: .atDocumentEnd,
                                          forMainFrameOnly: true)
                userContentController.addUserScript(script)
            }
        }
        
        public func call<T>(name: String, data: T? = nil, handler: @escaping ResponseCallback) where T: Codable {
            var message: [String: String] = [:]
            message[JavaScript.Injection.Keys.name.rawValue] = name
            var dataString = ""
            if let _data = data {
                if let string = _data as? String {
                    dataString = string
                } else if let jsonData = try? JSONEncoder().encode(_data),
                          let jsonString = String(data: jsonData, encoding: .utf8) {
                    dataString = jsonString.replacingOccurrences(of: "\"", with: "")
                }
            }
            message[JavaScript.Injection.Keys.data.rawValue] = dataString
            let callbackId = UUID().uuidString
            responseCallbacks[callbackId] = handler
            message[JavaScript.Injection.Keys.callbackId.rawValue] = callbackId
            if startupMessageQueue != nil {
                startupMessageQueue?.append(message)
            } else {
                send(message)
            }
        }
        
        public func register(name: String, handler: @escaping MessageCallback) {
            messageCallbacks[name] = handler
        }
        
        public func userContentController(_ userContentController: WKUserContentController,
                                          didReceive message: WKScriptMessage) {
            let name = message.name
            let body = message.body
            handleCalledFunction(name, body)
            handleStartupFunction(name, body)
            handleResponseFunction(name, body)
        }
        
        private func handleCalledFunction(_ name: String,
                                          _ body: Any) {
            guard name == injection.nativeCalledFunction else { return }
            let messageData = convert(body: body)
            var responseCallback: JavaScript.Bridge.ResponseCallback?
            if let callbackId = messageData[JavaScript.Injection.Keys.callbackId.rawValue] {
                responseCallback = { data in
                    self.send([
                        JavaScript.Injection.Keys.responseData.rawValue: data ?? "",
                        JavaScript.Injection.Keys.responseId.rawValue: callbackId
                    ])
                }
            }
            let dataString = messageData[JavaScript.Injection.Keys.data.rawValue]
            if let messageHandlerName = messageData[JavaScript.Injection.Keys.name.rawValue],
               let messageHandler = messageCallbacks[messageHandlerName] {
                messageHandler(dataString, responseCallback)
            }
        }
        
        private func handleStartupFunction(_ name: String, _ body: Any) {
            guard name == injection.nativeStartupFunction else { return }
            startupMessageQueue?.forEach({ message in
                self.send(message)
            })
            startupMessageQueue = nil
        }
        
        private func handleResponseFunction(_ name: String, _ body: Any) {
            let messageData = convert(body: body)
            guard let responseId = messageData[JavaScript.Injection.Keys.responseId.rawValue] else { return }
            let dataString = messageData[JavaScript.Injection.Keys.data.rawValue]
            let responseCallback = responseCallbacks[responseId]
            responseCallback?(dataString)
        }
        
        private func convert(body: Any) -> [String: String] {
            var data: [String: String] = [:]
            if let jsonString = body as? String,
               !jsonString.isEmpty,
               let jsonData = jsonString.data(using: .utf8) {
                do {
                    let dict = try JSONDecoder().decode([String: String].self, from: jsonData)
                    data = data.merging(dict, uniquingKeysWith: { (_,k2) in return k2 })
                } catch {
                    print("error = \(error)")
                }
            }
            return data
        }
        
        private func send(_ message: [String: String]) {
            webView?.send(message, injection.invoke(with:))
        }
    }
}

//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/24.
//

import UIKit
import WebKit

extension JavaScript {
    
    public class WebView: UIView {
        
        private let topBar: TopBar = .init(frame: .zero)
        private let progressView: UIProgressView = .init(frame: .zero)
        private let webView: WKWebView = .init(frame: .zero, configuration: .init())
        private var progressObservation: NSKeyValueObservation? = nil
        private lazy var frameBridge: FrameBridge = .init(webView: webView)
        
        deinit {
            progressObservation = nil
        }
        
        public required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(topBar)
            addSubview(progressView)
            addSubview(webView)
            webView.navigationDelegate = self
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { _, _ in
                self.progressView.progress = .init(self.webView.estimatedProgress)
            }
        }
        
        public override func layoutSubviews() {
            topBar.x = safeAreaInsets.left
            topBar.y = safeAreaInsets.top
            topBar.width = width - (safeAreaInsets.left + safeAreaInsets.right)
            topBar.height = 44
            progressView.x = topBar.x
            progressView.y = topBar.maxY
            progressView.width = topBar.width
            progressView.height = 3
            webView.x = progressView.x
            webView.y = progressView.maxY
            webView.width = progressView.width
            webView.height = height - webView.y - safeAreaInsets.bottom
        }
        
        public func loadHTMLString(_ htmlString: String, baseURL: URL?) {
            webView.loadHTMLString(htmlString, baseURL: baseURL)
        }
        
        public func loadRequest(_ request: URLRequest) {
            webView.load(request)
        }
    }
}

extension JavaScript.WebView: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.progress = 0
        progressView.isHidden = false
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.isHidden = true
        progressView.progress = 0
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        progressView.progress = 0
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        progressView.progress = 0
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else { return }
        if frameBridge.isBridgeURLScheme(url) {
            if frameBridge.isBridgeLoadedURL(url) {
                frameBridge.injectIFrame()
            } else if frameBridge.isBridgeQueueMessageURL(url) {
                frameBridge.flushQueueMessages()
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

extension JavaScript.WebView {
    
    public typealias ResponseCallback = (_ data: Any?) -> Void
    public typealias MessageCallback = (_ data: Any?, _ callback: ResponseCallback?) -> Void
    
    public func register(name: String, handler: @escaping MessageCallback) {
        frameBridge.register(name: name, handler: handler)
    }
    
    public func call(name: String, data: Any? = nil, handler: ResponseCallback? = nil) {
        frameBridge.call(name: name, data: data, handler: handler)
    }
    
    fileprivate final class FrameBridge {
        
        private weak var webView: WKWebView?
        private var startupMessageQueue: [[String: Any]]? = []
        private var responseCallbacks: [String: ResponseCallback] = [:]
        private var messageCallbacks: [String: MessageCallback] = [:]
        
        init(webView: WKWebView? = nil) {
            self.webView = webView
        }
        
        func call(name: String, data: Any? = nil, handler: ResponseCallback? = nil) {
            var message: [String: Any] = [:]
            if let _data = data {
                message["data"] = _data
            }
            if let responseCb = handler {
                let callbackId = UUID().uuidString
                message["callbackId"] = callbackId
                responseCallbacks[callbackId] = responseCb
            }
            message["handlerName"] = name
            if startupMessageQueue != nil {
                startupMessageQueue?.append(message)
            } else {
                send(message)
            }
        }
        
        func register(name: String, handler: @escaping MessageCallback) {
            messageCallbacks[name] = handler
        }
        
        func injectIFrame() {
            webView?.evaluateJavaScript(JavaScript.WebView.InjectJSCode, completionHandler: { result, error in
                if let e = error {
                    print("error = \(e)")
                }
            })
            startupMessageQueue?.forEach { send($0) }
            startupMessageQueue?.removeAll()
            startupMessageQueue = nil
        }
        
        func flushQueueMessages() {
            webView?.evaluateJavaScript("WebViewJavascriptBridge._fetchQueue();",
                                        completionHandler: { result, error in
                if let jsonString = result as? String {
                    self.flushMessage(jsonString)
                }
                if let e = error {
                    print("evalute js 'WebViewJavascriptBridge._fetchQueue()' error: \(e)")
                }
            })
        }
        
        func flushMessage(_ jsonString: String) {
            if let jsonData = jsonString.data(using: .utf8),
               let messages = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                messages.forEach { message in
                    if let responseId = message["responseId"] as? String {
                        let responseCb = self.responseCallbacks[responseId]
                        responseCb?(message["responseData"])
                        responseCallbacks.removeValue(forKey: responseId)
                    } else {
                        var responseCb: ResponseCallback? = nil
                        if let callbackId = message["callbackId"] {
                            responseCb = { string in
                                var data: Any = NSNull()
                                if let msg = string { data = msg }
                                if self.startupMessageQueue != nil {
                                    self.startupMessageQueue?.append(["responseId": callbackId,
                                                                      "responseData": data])
                                } else {
                                    self.send(message)
                                }
                            }
                        }
                        if let handlerName = message["handlerName"] as? String {
                            let handler = messageCallbacks[handlerName]
                            handler?(message["data"], responseCb)
                        }
                    }
                }
            }
        }
        
        func isBridgeURLScheme(_ url: URL) -> Bool {
            guard let scheme = url.scheme?.lowercased() else { return false }
            return scheme == "https" || scheme == "wvjbscheme"
        }
        
        func isBridgeLoadedURL(_ url: URL) -> Bool {
            guard let host = hostFrom(url: url) else { return false }
            return isBridgeURLScheme(url) && host == "__bridge_loaded__"
        }
        
        func isBridgeQueueMessageURL(_ url: URL) -> Bool {
            guard let host = hostFrom(url: url) else { return false }
            return isBridgeURLScheme(url) && host == "__wvjb_queue_message__"
        }
        
        func hostFrom(url: URL) -> String? {
            let host: String
            if #available(iOS 16.0, *) {
                guard let _host = url.host() else { return nil }
                host = _host
            } else {
                guard let _host = url.host else { return nil }
                host = _host
            }
            return host
        }
        
        func send(_ message: [String: Any]) {
            webView?.send(message, { "WebViewJavascriptBridge._handleMessageFromObjC(\($0));" })
        }
    }
}

extension JavaScript.WebView {
    
    fileprivate final class TopBar: UIView {
        
        private let titleLabel: UILabel = .init()
        private let backButton: UIButton = .init(type: .custom)
        private let closeButton: UIButton = .init(type: .custom)
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(titleLabel)
            addSubview(backButton)
            addSubview(closeButton)
            backButton.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
            closeButton.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        }
        
        override func layoutSubviews() {
            titleLabel.sizeToFit()
            titleLabel.centerX = width / 2
            backButton.sizeToFit()
            closeButton.sizeToFit()
            closeButton.maxX = width
        }
        
        @objc private func backButtonAction() {
            responds(event: .webViewBack, from: self)
        }
        
        @objc private func closeButtonAction() {
            responds(event: .webViewClose, from: self)
        }
    }
}

extension UIResponder.Event {
    
    public static let webViewBack: UIResponder.Event = .init(name: "webViewBack")
    public static let webViewClose: UIResponder.Event = .init(name: "webViewClose")
    
}

extension JavaScript.WebView {
    
    fileprivate static let InjectJSCode = """
    
                (function() {
                    if (window.WebViewJavascriptBridge) {
                        return;
                    }

                    if (!window.onerror) {
                        window.onerror = function(msg, url, line) {
                            console.log(\"WebViewJavascriptBridge: ERROR:\" + msg + \"@\" + url + \":\" + line);
                        }
                    }
                    window.WebViewJavascriptBridge = {
                        registerHandler: registerHandler,
                        callHandler: callHandler,
                        disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
                        _fetchQueue: _fetchQueue,
                        _handleMessageFromObjC: _handleMessageFromObjC
                    };

                    var messagingIframe;
                    var sendMessageQueue = [];
                    var messageHandlers = {};
                    
                    var CUSTOM_PROTOCOL_SCHEME = 'https';
                    var QUEUE_HAS_MESSAGE = '__wvjb_queue_message__';
                    
                    var responseCallbacks = {};
                    var uniqueId = 1;
                    var dispatchMessagesWithTimeoutSafety = true;

                    function registerHandler(handlerName, handler) {
                        messageHandlers[handlerName] = handler;
                    }
                    
                    function callHandler(handlerName, data, responseCallback) {
                        if (arguments.length == 2 && typeof data == 'function') {
                            responseCallback = data;
                            data = null;
                        }
                        _doSend({ handlerName:handlerName, data:data }, responseCallback);
                    }
                    function disableJavscriptAlertBoxSafetyTimeout() {
                        dispatchMessagesWithTimeoutSafety = false;
                    }
                    
                    function _doSend(message, responseCallback) {
                        if (responseCallback) {
                            var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
                            responseCallbacks[callbackId] = responseCallback;
                            message['callbackId'] = callbackId;
                        }
                        sendMessageQueue.push(message);
                        messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
                    }

                    function _fetchQueue() {
                        var messageQueueString = JSON.stringify(sendMessageQueue);
                        sendMessageQueue = [];
                        return messageQueueString;
                    }

                    function _dispatchMessageFromObjC(messageJSON) {
                        if (dispatchMessagesWithTimeoutSafety) {
                            setTimeout(_doDispatchMessageFromObjC);
                        } else {
                             _doDispatchMessageFromObjC();
                        }
                        
                        function _doDispatchMessageFromObjC() {
                            var message = JSON.parse(messageJSON);
                            var messageHandler;
                            var responseCallback;

                            if (message.responseId) {
                                responseCallback = responseCallbacks[message.responseId];
                                if (!responseCallback) {
                                    return;
                                }
                                responseCallback(message.responseData);
                                delete responseCallbacks[message.responseId];
                            } else {
                                if (message.callbackId) {
                                    var callbackResponseId = message.callbackId;
                                    responseCallback = function(responseData) {
                                        _doSend({ handlerName:message.handlerName, responseId:callbackResponseId, responseData:responseData });
                                    };
                                }
                                
                                var handler = messageHandlers[message.handlerName];
                                if (!handler) {
                                    console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
                                } else {
                                    handler(message.data, responseCallback);
                                }
                            }
                        }
                    }
                    
                    function _handleMessageFromObjC(messageJSON) {
                        _dispatchMessageFromObjC(messageJSON);
                    }

                    messagingIframe = document.createElement('iframe');
                    messagingIframe.style.display = 'none';
                    messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
                    document.documentElement.appendChild(messagingIframe);

                    registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);
                    
                    setTimeout(_callWVJBCallbacks, 0);
                    function _callWVJBCallbacks() {
                        var callbacks = window.WVJBCallbacks;
                        delete window.WVJBCallbacks;
                        for (var i=0; i<callbacks.length; i++) {
                            callbacks[i](WebViewJavascriptBridge);
                        }
                    }
                })();
    
    """
    
}

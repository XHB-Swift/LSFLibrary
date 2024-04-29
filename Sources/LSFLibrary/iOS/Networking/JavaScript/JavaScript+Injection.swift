//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/23.
//

import Foundation
 
extension JavaScript {
    
    public struct Injection {
        
        public var moduleName: String
        public var nativeCalledFunction: String = "calledFunction"
        public var nativeStartupFunction: String = "startupFunction"
        public var nativeMessageFunction: String = "nativeMessageHandler"
        public var nativeResponseFunction: String = "responseFunction"
        
        public init(moduleName: String,
                    nativeCalledFunction: String = "calledFunction",
                    nativeStartupFunction: String = "startupFunction",
                    nativeMessageFunction: String = "nativeMessageHandler",
                    nativeResponseFunction: String = "responseFunction") {
            self.moduleName = moduleName
            self.nativeCalledFunction = nativeCalledFunction
            self.nativeStartupFunction = nativeStartupFunction
            self.nativeMessageFunction = nativeMessageFunction
            self.nativeResponseFunction = nativeResponseFunction
        }
        
        internal func invoke(with message: String) -> String {
            
            return """
            \(moduleName).\(nativeMessageFunction)('\(message)');
            """
        }
        
        internal func injectCode() -> String {
            """
            (function() {
            
                if (window.\(moduleName)) {
                    return;
                }
                
                \(declareModule())
            
                var uniqueId = 1;
            
                \(declareCallHandler())
            
                \(declareRegisterHandler())
            
                \(declareNativeMessageHandler())
                
                setTimeout(function () {
                   if (typeof window._\(moduleName)InitFinished === \"function\") {
                       window._\(moduleName)InitFinished(window.\(moduleName));
                   }
                   if (typeof nativeBridgeHead === \"undefined\") {
                       window.webkit.messageHandlers.\(nativeStartupFunction).postMessage(\"\");
                   } else {
                       nativeBridgeHead.\(nativeStartupFunction)();
                   }
                }, 0);
            })();
            """
        }
        
        private func declareModule() -> String {
            """
            window.\(moduleName) = {
               callHandler: callHandler,
               registerHandler: registerHandler,
               \(nativeMessageFunction): \(nativeMessageFunction),
               messageHandlers: {},
               messageCallbacks: {}
            };
            """
        }
        
        private func declareCallHandler() -> String {
            """
            function callHandler(name, data, responseCallback) {
                if (arguments.length == 2 && typeof data == 'function') {
                    responseCallback = data;
                    data = null;
                }
                var message = {\"\(Keys.name.rawValue)\":name};
                if (data) {
                    message[\"\(Keys.data.rawValue)\"] = data;
                }
                if (responseCallback) {
                    var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
                    message[\"\(Keys.callbackId.rawValue)\"] = callbackId;
                    \(moduleName).messageCallbacks[callbackId] = responseCallback;
                }
                var messageJSON = JSON.stringify(message);
                if (typeof nativeBridgeHead === \"undefined\") {
                   window.webkit.messageHandlers.\(nativeCalledFunction).postMessage(messageJSON);
                } else {
                   nativeBridgeHead.\(nativeCalledFunction)(messageJSON);
                }
            }
            """
        }
        
        private func declareRegisterHandler() -> String {
            """
            function registerHandler(name, handler) {
               \(moduleName).messageHandlers[name] = handler;
            }
            """
        }
        
        private func declareNativeMessageHandler() -> String {
            """
            function \(nativeMessageFunction)(messageJSON) {
               var nativeMessage = messageJSON;
               if (typeof nativeMessage != \"object\") {
                  nativeMessage = JSON.parse(unescape(messageJSON));
               }
               var responseId = nativeMessage[\"\(Keys.responseId.rawValue)\"];
               if (responseId) {
                   var callback = \(moduleName).messageCallbacks[responseId];
                   var responseData = nativeMessage[\"\(Keys.responseData.rawValue)\"];
                   callback(responseData);
               } else {
                   var messageName = nativeMessage[\"\(Keys.name.rawValue)\"];
                   var messageData = nativeMessage[\"\(Keys.data.rawValue)\"];
                   var messageCallbackId = nativeMessage[\"\(Keys.callbackId.rawValue)\"];
                   var handler = \(moduleName).messageHandlers[messageName];
                   var responseCallback = function(data) {
                       var responseMessage = {
                           \(Keys.responseId.rawValue): messageCallbackId,
                           \(Keys.responseData.rawValue): data
                       };
                       var responseMessageJSON = JSON.stringify(responseMessage);
                       if (typeof nativeBridgeHead === \"undefined\") {
                           window.webkit.messageHandlers.\(nativeResponseFunction).postMessage(responseMessageJSON);
                       } else {
                           nativeBridgeHead.\(nativeResponseFunction)(responseMessageJSON);
                       }
                   }
                   handler(messageData, responseCallback);
               }
            }
            """
        }
    }
}

extension JavaScript.Injection {
    
    internal enum Keys: String {
        case name
        case data
        case callbackId
        case responseId
        case responseData
    }
}

extension JavaScript.Injection: Hashable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.moduleName == rhs.moduleName
    }
}

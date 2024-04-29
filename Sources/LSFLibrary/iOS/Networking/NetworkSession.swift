//
//  File.swift
//  
//
//  Created by 谢鸿标 on 2023/9/17.
//

import Foundation

public protocol URLRequestDataTransformer {
    func body(_ params: [String: Any]) -> Data?
    func body<T>(_ params: [String: T]) -> Data? where T: Codable
}

public protocol URLResponseDataTransformer {
    func result(_ data: Data) throws -> Any
    func result<T>(_ data: Data, _ t: T.Type) throws -> T where T: Codable
}

public struct JSONTransformer: URLRequestDataTransformer, URLResponseDataTransformer {
    
    public func body(_ params: [String : Any]) -> Data? {
        if !JSONSerialization.isValidJSONObject(params) { return nil }
        return try? JSONSerialization.data(withJSONObject: params, options: [.prettyPrinted])
    }
    
    public func body<T>(_ params: [String : T]) -> Data? where T : Decodable, T : Encodable {
        try? JSONEncoder().encode(params)
    }
    
    public func result(_ data: Data) throws -> Any {
        try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }
    
    public func result<T>(_ data: Data, _ t: T.Type) throws -> T where T : Decodable, T : Encodable {
        try JSONDecoder().decode(t, from: data)
    }
}

extension URLRequest {
    
    public static func get(url: String, 
                           header: [String: Any]? = nil,
                           params: [String: Any]? = nil,
                           cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                           timeoutInterval: TimeInterval = 60.0) -> Self? {
        var urlString = url
        if let _params = params, !_params.isEmpty {
            if urlString.hasSuffix("?") {
                urlString.append(_params.queryString)
            } else {
                urlString.append("?\(_params.queryString)")
            }
        }
        guard let _url = URL(string: urlString) else { return nil }
        var request: URLRequest = .init(url: _url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = header?.mapValues({ "\($0)" })
        return request
    }
    
    public static func post<T>(url: String,
                               header: [String: Any]? = nil,
                               params: [String: Any]? = nil,
                               transformer: T,
                               cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                               timeoutInterval: TimeInterval = 60.0) -> Self? where T: URLRequestDataTransformer {
        guard let _url = URL(string: url) else { return nil }
        var request: URLRequest = .init(url: _url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = header?.mapValues({ "\($0)" })
        request.httpBody = transformer.body(params ?? [:])
        return request
    }
    
    public static func post<T, V>(url: String,
                                  header: [String: Any]? = nil,
                                  params: [String: V]? = nil,
                                  transformer: T,
                                  cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                  timeoutInterval: TimeInterval = 60.0) -> Self? where T: URLRequestDataTransformer, V: Codable {
        guard let _url = URL(string: url) else { return nil }
        var request: URLRequest = .init(url: _url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = header?.mapValues({ "\($0)" })
        request.httpBody = transformer.body(params ?? [:])
        return request
    }
}

extension URLSession {
    
    public func get<T>(url: String,
                       header: [String: Any]? = nil,
                       params: [String: Any]? = nil,
                       transformer: T,
                       cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                       timeoutInterval: TimeInterval = 60.0,
                       completion: @escaping (Result<Any, Error>) -> Void) where T: URLResponseDataTransformer {
        guard let request: URLRequest = .get(url: url,
                                             header: header,
                                             params: params,
                                             cachePolicy: cachePolicy,
                                             timeoutInterval: timeoutInterval)
        else { return }
        dataTask(with: request) { data, response, error in
            
            if let _data = data {
                do {
                    let result = try transformer.result(_data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            } else if let _error = error {
                completion(.failure(_error))
            }
            
        }.resume()
    }
    
    public func post<T1, T2>(url: String,
                             header: [String: Any]? = nil,
                             params: [String: Any]? = nil,
                             transformer1: T1,
                             transformer2: T2,
                             cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                             timeoutInterval: TimeInterval = 60.0,
                             completion: @escaping (Result<Any, Error>) -> Void) where T1: URLRequestDataTransformer,
                                                                                       T2: URLResponseDataTransformer {
        guard let request: URLRequest = .post(url: url,
                                              header: header,
                                              params: params,
                                              transformer: transformer1,
                                              cachePolicy: cachePolicy,
                                              timeoutInterval: timeoutInterval)
        else { return }
        dataTask(with: request) { data, response, error in
            
            if let _data = data {
                do {
                    let result = try transformer2.result(_data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            } else if let _error = error {
                completion(.failure(_error))
            }
            
        }.resume()
    }
    
    public func get<T, R>(url: String,
                          header: [String: Any]? = nil,
                          params: [String: Any]? = nil,
                          transformer: T,
                          cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                          timeoutInterval: TimeInterval = 60.0,
                          completion: @escaping (Result<R, Error>) -> Void) where T: URLResponseDataTransformer, R: Codable {
        guard let request: URLRequest = .get(url: url,
                                             header: header,
                                             params: params,
                                             cachePolicy: cachePolicy,
                                             timeoutInterval: timeoutInterval)
        else { return }
        dataTask(with: request) { data, response, error in
            
            if let _data = data {
                do {
                    let result = try transformer.result(_data, R.self)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            } else if let _error = error {
                completion(.failure(_error))
            }
            
        }.resume()
    }
    
    public func post<T1, T2, R>(url: String,
                                header: [String: Any]? = nil,
                                params: [String: Any]? = nil,
                                transformer1: T1,
                                transformer2: T2,
                                cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                timeoutInterval: TimeInterval = 60.0,
                                completion: @escaping (Result<R, Error>) -> Void) where R: Codable,
                                                                                        T1: URLRequestDataTransformer,
                                                                                        T2: URLResponseDataTransformer {
        guard let request: URLRequest = .post(url: url,
                                              header: header,
                                              params: params,
                                              transformer: transformer1,
                                              cachePolicy: cachePolicy,
                                              timeoutInterval: timeoutInterval)
        else { return }
        dataTask(with: request) { data, response, error in
            
            if let _data = data {
                do {
                    let result = try transformer2.result(_data, R.self)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            } else if let _error = error {
                completion(.failure(_error))
            }
            
        }.resume()
    }
}

public enum NetworkSession<Key, Value> where Key: Hashable {
    
    public typealias Operation = (url: String,
                                  method: String,
                                  header: [String: Value],
                                  body: Data?,
                                  cachePolicy: URLRequest.CachePolicy,
                                  timeoutInterval: TimeInterval)
    
    public static func resume<R>(_ operation: Operation,
                                 _ completion: @escaping (Result<R, Error>) -> Void) where R: Codable {
        resume(operation) { result in
            switch result {
            case .success(let success):
                if let data = success.0 {
                    let jsonDecoder = JSONDecoder()
                    do {
                        completion(.success(try jsonDecoder.decode(R.self, from: data)))
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    let response = success.1
                    completion(.failure(NSError(domain: "EmptyData",
                                                code: -1,
                                                userInfo: [
                                                    NSLocalizedDescriptionKey : response?.description ?? ""
                                                ])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public static func resume(_ operation: Operation,
                              _ completion: @escaping (Result<(Data?, URLResponse?), Error>) -> Void) {
        guard let url: URL = .init(string: operation.url) else { return }
        var request: URLRequest = .init(url: url,
                                        cachePolicy: operation.cachePolicy,
                                        timeoutInterval: operation.timeoutInterval)
        request.httpMethod = operation.method
        request.allHTTPHeaderFields = operation.header.mapValues({ "\($0)" })
        request.httpBody = operation.body
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success((data, response)))
            }
        }.resume()
    }
}

extension NetworkSession {
    
    private static func get(url: String, params: [Key: Value]) -> String {
        var _url = url
        if !_url.hasSuffix("?") {
            _url.append("?")
        }
        _url.append(params.queryString)
        return _url
    }
    
    public static func getRaw(url: String,
                              header: [String: Value],
                              params: [Key: Value],
                              cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                              timeoutInterval: TimeInterval = 60.0,
                              completion: @escaping (Result<(Data?, URLResponse?), Error>) -> Void) {
        resume((get(url: url, params: params),
                "GET",
                header,
                nil,
                cachePolicy,
                timeoutInterval),
               completion)
    }
    
    public static func getJSON<R>(url: String,
                                  header: [String: Value],
                                  params: [Key: Value],
                                  cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                  timeoutInterval: TimeInterval = 60.0,
                                  completion: @escaping (Result<R, Error>) -> Void) where R: Codable {
        resume((get(url: url, params: params),
                "GET",
                header,
                nil,
                cachePolicy,
                timeoutInterval),
               completion)
    }
    
    public static func postRaw(url: String,
                               header: [String: Value],
                               params: [Key: Value],
                               cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                               timeoutInterval: TimeInterval = 60.0,
                               completion: @escaping (Result<(Data?, URLResponse?), Error>) -> Void) {
    }
}

extension NetworkSession where Key: Comparable {
    
    private static func get(url: String, params: [Key: Value], sorted: Bool = false) -> String {
        var _url = url
        if !_url.hasSuffix("?") {
            _url.append("?")
        }
        _url.append(sorted ? params.sortedQueryString : params.queryString)
        return _url
    }
    
    public static func getRaw(url: String,
                              header: [String: Value],
                              params: [Key: Value],
                              sortedParams: Bool = false,
                              cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                              timeoutInterval: TimeInterval = 60.0,
                              completion: @escaping (Result<(Data?, URLResponse?), Error>) -> Void) {
        resume((get(url: url, params: params, sorted: sortedParams),
                "GET",
                header,
                nil,
                cachePolicy,
                timeoutInterval),
               completion)
    }
    
    public static func getJSON<R>(url: String,
                                  header: [String: Value],
                                  params: [Key: Value],
                                  sortedParams: Bool = false,
                                  cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                                  timeoutInterval: TimeInterval = 60.0,
                                  completion: @escaping (Result<R, Error>) -> Void) where R: Codable {
        resume((get(url: url, params: params, sorted: sortedParams),
                "GET",
                header,
                nil,
                cachePolicy,
                timeoutInterval),
               completion)
    }
}

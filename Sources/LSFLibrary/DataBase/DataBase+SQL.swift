//
//  DataBase+SQL.swift
//
//
//  Created by 谢鸿标 on 2024/4/26.
//

import SQLite3
import Foundation

// MARK: SQL 操作

extension DataBase {
    
    public enum SQL {
        
        case create(String, [Field])
        case select([String], String, Condition)
        case delete(String, Condition)
        case insertOrReplace([String], String, Condition)
        
        public var rawValue: String {
            switch self {
            case .create(let string, let array):
                return "CREATE TABLE IF NOT EXISTS \(string) (\(array.map({ $0.toDefine }).joined(separator: ", ")))"
            case .select(let array, let string, let condition):
                let columnDesc = array.isEmpty ? "*" : array.joined(separator: ", ")
                return "SELECT \(columnDesc) FROM \(string) \(condition.rawValue)"
            case .delete(let string, let condition):
                return "DELETE FROM \(string) \(condition)"
            case .insertOrReplace(let array, let string, let condition):
                let columnDesc = array.joined(separator: ", ")
                let valueDesc = array.map({ _ in "?" }).joined(separator: ", ")
                return "INSERT OR REPLACE INTO \(string) (\(columnDesc)) VALUES (\(valueDesc)) \(condition.rawValue)"
            }
        }
    }
}

extension DataBase.SQL {
    
    public struct Field {
        
        public let name: String
        public let priority: Field.Priority
        
        fileprivate var toDefine: String {
            let p = priority.rawValue
            return "\(name) TEXT\(p.isEmpty ? p : " \(p)")"
        }
        
        public init(name: String) {
            self.init(name: name, priority: .none)
        }
        
        public init(name: String, priority: Field.Priority) {
            self.name = name
            self.priority = priority
        }
    }
    
    public struct Condition: RawRepresentable {
        
        public typealias RawValue = String
        
        public var rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension DataBase.SQL.Field {
    
    public enum Priority: String {
        case none = ""
        case primaryKey = "PRIMARY KEY"
        case unique = "UNIQUE"
    }
}

extension DataBase.SQL.Condition {
    
    public static let OR = DataBase.SQL.Condition("OR")
    public static let NOT = DataBase.SQL.Condition("NOT")
    public static let AND = DataBase.SQL.Condition("AND")
    public static let NONE = DataBase.SQL.Condition("")
    public static let WHERE = DataBase.SQL.Condition("WHERE")
    
    public var or: Self {
        .init(rawValue: "\(rawValue) OR")
    }
    
    public var not: Self {
        .init(rawValue: "\(rawValue) NOT")
    }
    
    public var and: Self {
        .init(rawValue: "\(rawValue) AND")
    }
    
    public func like(column: String, pattern: String) -> Self {
        .init(rawValue: "\(rawValue) \(column) LIKE '\(pattern)'")
    }
    
    public func regexp(column: String, pattern: String) -> Self {
        .init(rawValue: "\(rawValue) \(column) REGEXP '\(pattern)'")
    }
    
    public func between(value1: Any, value2: Any) -> Self {
        .init(rawValue: "\(rawValue) BETWEEN \(value1) \(Self.AND.rawValue) \(value2)")
    }
    
    public func compare(column: String, operator: String, value: Any) -> Self {
        .init(rawValue: "\(rawValue) \(column) \(`operator`) \(value)")
    }
    
    public func orderBy(asc columns: [String]) -> Self {
        .init(rawValue: "\(rawValue) ORDER BY \(columns.joined(separator: " ")) ASC")
    }
    
    public func orderBy(desc columns: [String]) -> Self {
        .init(rawValue: "\(rawValue) ORDER BY \(columns.joined(separator: " ")) DESC")
    }
    
    public func limit(_ count: Int) -> Self {
        .init(rawValue: "\(rawValue) LIMIT \(count)")
    }
}


extension DataBase {
    
    public typealias Row = [String: String]
    
    public protocol Table {
        var name: String { get }
        var fields: [(DataBase.SQL.Field, String?)] { get }
    }
    
    public func transaction(handler: @escaping (OpaquePointer?) -> Void) {
        connect(defaultFile) { db in
            do {
                try self.exec(sql: "BEGIN TRANSACTION;", for: db)
                handler(db)
                try self.exec(sql: "COMMIT;", for: db)
            } catch {
                print("error -> \(error)")
            }
        }
    }
}

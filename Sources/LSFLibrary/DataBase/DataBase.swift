//
//  DataBase.swift
//
//
//  Created by 谢鸿标 on 2024/4/25.
//

import SQLite3
import Foundation

public final class DataBase {
    
    fileprivate let lock: Lock.Mutex = .init()
    fileprivate let queue: DispatchQueue = .init(label: "com.lsflib.database")
    fileprivate var sqliteOpaquePointers: [String: OpaquePointer] = [:]
    
    public var defaultFile: String {
        guard let rootPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        else { return "" }
        return "\(rootPath.hasSuffix("/") ? rootPath : "\(rootPath)/")com_lsflib_db.sqlite"
    }
    
    fileprivate func open(db fileName: String) throws {
        lock.lock(); defer { lock.unlock() }
        guard let cString = fileName.cString(using: .utf8)
        else {
            throw DataBase.Error.notFound(fileName)
        }
        var sqlite: OpaquePointer?
        let result = sqlite3_open(cString, &sqlite)
        if result != SQLITE_OK {
            throw DataBase.Error.open(.init(cString: sqlite3_errmsg(sqlite)))
        }
        sqliteOpaquePointers[fileName] = sqlite
    }
    
    fileprivate func close(db fileName: String) throws {
        lock.lock(); defer { lock.unlock() }
        guard let sqlite = sqliteOpaquePointers[fileName]
        else {
            throw DataBase.Error.notFound(fileName)
        }
        let result = sqlite3_close(sqlite)
        if result != SQLITE_OK {
            throw DataBase.Error.close(.init(cString: sqlite3_errmsg(sqlite)))
        }
        sqliteOpaquePointers.removeValue(forKey: fileName)
    }
    
    public func exec(sql: String, for db: OpaquePointer?) throws {
        guard let cSQL = sql.cString(using: .utf8) else {
            throw DataBase.Error.invalidSQL(sql)
        }
        let result = sqlite3_exec(db, cSQL, nil, nil, nil)
        if result != SQLITE_OK {
            throw DataBase.Error.execSQL(.init(cString: sqlite3_errmsg(db)), sql)
        }
    }
    
    public func prepare(sql: String, for fileName: String) throws -> Statement {
        lock.lock(); defer { lock.unlock() }
        guard let sqlite = sqliteOpaquePointers[fileName]
        else {
            throw DataBase.Error.notFound(fileName)
        }
        guard let cSQL = sql.cString(using: .utf8) else {
            throw DataBase.Error.invalidSQL(sql)
        }
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(sqlite, cSQL, -1, &statement, nil)
        if result != SQLITE_OK {
            throw DataBase.Error.execSQL(.init(cString: sqlite3_errmsg(sqlite)), sql)
        }
        return .init(db: sqlite, raw: statement)
    }
    
    public func prepare(sql: String, for db: OpaquePointer?) throws -> Statement {
        guard let cSQL = sql.cString(using: .utf8) else {
            throw DataBase.Error.invalidSQL(sql)
        }
        var statement: OpaquePointer?
        let result = sqlite3_prepare_v2(db, cSQL, -1, &statement, nil)
        if result != SQLITE_OK {
            throw DataBase.Error.execSQL(.init(cString: sqlite3_errmsg(db)), sql)
        }
        return .init(db: db, raw: statement)
    }
    
    public func connect(_ file: String, 
                        _ handler: @escaping (OpaquePointer?) -> Void) {
        queue.async {
            do {
                try self.open(db: file)
                handler(self.sqliteOpaquePointers[file])
                try self.close(db: file)
            } catch {
                print("error -> \(error)")
            }
        }
    }
}

// MARK: Statement

extension DataBase {
    
    public class Statement {
        
        public let db: OpaquePointer?
        public let raw: OpaquePointer?
        
        public init(db: OpaquePointer?, raw: OpaquePointer?) {
            self.db = db
            self.raw = raw
        }
        
        public convenience init(other: Statement) {
            self.init(db: other.db, raw: other.raw)
        }
        
        @discardableResult
        public func step() -> Int32 {
            sqlite3_step(raw)
        }
        
        @discardableResult
        public func reset() -> Int32 {
            sqlite3_reset(raw)
        }
        
        @discardableResult
        public func finalize() -> Int32 {
            sqlite3_finalize(raw)
        }
        
        public func resetIfDone() {
            if step() == SQLITE_DONE {
                reset()
            }
        }
        
        public func numberOfColumns() -> Int {
            .init(sqlite3_column_count(raw))
        }
        
        public func columnName(at index: Int) -> String {
            return .init(cString: sqlite3_column_name(raw, .init(index)))
        }
        
        public func bind(text: String, at index: Int) {
            sqlite3_bind_text(raw, .init(index), text.cString(using: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        }
        
        public func columnText(at index: Int) -> String {
            guard let cString = sqlite3_column_text(raw, .init(index))
            else { return "" }
            return .init(cString: cString)
        }
    }
}

// MAKR: 定义错误

extension DataBase {
    
    public enum Error: Swift.Error {
        case `open`(String)
        case close(String)
        case notFound(String)
        case invalidSQL(String)
        case execSQL(String, String)
        case invalidType(String)
    }
}

extension String {
    
    public var toBool: Bool? {
        switch lowercased() {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: return nil
        }
    }
}

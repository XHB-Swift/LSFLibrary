import XCTest
@testable import LSFLibrary

final class LSFLibraryTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(LSFLibrary().text, "Hello, World!")
        let createUserTable = DataBase.SQL.create("User", [
            .init(name: "id", priority: .primaryKey),
            .init(name: "name"),
            .init(name: "age")
        ])
        print("createUserTable -> \(createUserTable.rawValue)")
    }
}

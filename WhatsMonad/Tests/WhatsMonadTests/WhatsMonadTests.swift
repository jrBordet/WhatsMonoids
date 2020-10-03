import XCTest
@testable import WhatsMonad

final class WhatsMonadTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(WhatsMonad().text, "Hello, World!")
    }
    
    func test_incr() {
        XCTAssertEqual(incr(1), 2)
    }
    
    func test_container_map() {
        let container = Container<Int>(1)
        
        guard case let .value(value) = container else {
            fatalError()
        }
        
        XCTAssertEqual(value, 1)
        
        let incrContainer = container.map { (i: Int) -> Int in
            i + 1
        }
        
        guard case let .value(v) = incrContainer else {
            fatalError()
        }
        
        XCTAssertEqual(v, 2)
        
        let valueString = container.map { $0 + 1 }.map { String($0) }
        
        guard case let .value(s) = valueString else {
            fatalError()
        }
        
        XCTAssertEqual(s, "2")
        
        let fmap = map { (i: Int) -> Int in
            i + 1
        }
        
        let r = fmap(container)
        
        guard case let .value(incrValue) = r else {
            fatalError()
        }
        
        XCTAssertEqual(incrValue, 2)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

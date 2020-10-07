import XCTest
@testable import WhatsMonad

final class WhatsMonadTests: XCTestCase {
    
    // MARK: - Functors
    
    func test_apply_function_to_container() {
        func plusThree(_ i: Int) -> Int {
            i + 3
        }
        
        let result = Maybe<Int>(1).map(plusThree(_:))
        
        XCTAssertEqual(unwrap(result), 4)
    }
    
    func test_container_map() {
        let container = Maybe<Int>(1)
        
        let result = container.map { $0 + 1 }
        
        XCTAssertEqual(unwrap(result), 2)
    }
    
    // MARK: - Map laws
    
    func test_map_identity() {
        let container = Maybe<Int>(1)
        
        let result = container.map(id)
        
        XCTAssertEqual(unwrap(result), 1)
    }
    
    func test_map_composition() {
        let incr: (Int) -> Int = { v in v + 1 }
        let square: (Int) -> Int = { v in v * v }
        
        let container = Maybe<Int>(1)
        
        let incr_square = pipe(incr, square)
        
        let result_composition = container
            .map(incr_square)
        
        let result_chaining = container
            .map(incr)
            .map(square)
        
        let unwrapped = try! unwrap(result_composition, rhs: result_chaining)
        XCTAssertTrue(unwrapped.0 == unwrapped.1)
    }
    
    func test_container_map_with_operator() {
        let incr: (Int) -> Int = { $0 + 1 }
        let square: (Int) -> Int = { $0 * $0 }
        
        let result = pipe(square, incr) <^> Maybe<Int>(2)
        
        XCTAssertEqual(unwrap(result), 5)
    }
    
    // MARK: - Apply
    
    func test_container_apply() {
        let stringify = Maybe<(Int) -> String> { String($0) }
        
        let container: Maybe<Int> = .value(42)
        
        let result = container.apply(stringify)
        
        XCTAssertEqual(unwrap(result), "42")
    }
    
    func test_container_apply_2() {
        let result = curry(addition) <^> Maybe(41) <*> Maybe(1)
        
        XCTAssertEqual(unwrap(result), 42)
        
        let a: Int? = 41
        let b: Int? = 1
        
        if let a = a, let b = b {
            let result = addition(a, b: b)
            
            XCTAssertEqual(result, 42)
        }        
    }
    
    func test_container_apply_on_array() {
        let result =  [ { $0 + 3 }, { $0 * 2 } ] <*> [1, 2, 3]
        
        XCTAssertEqual(result, [4, 5, 6, 2, 4, 6])
    }
    
    // MARK: - flatMap
    
    func test_container_flatMap() {
        let result = Maybe<Int>.value(2).flatMap(half(_:))
        
        switch result {
        case .none:
            fatalError()
        case let .value(v):
            XCTAssertEqual(v, 1)
        }
    }
    
    func test_container_flatMap_operator() {
        let result = Maybe<Int>.value(2) >>- half
        
        XCTAssertEqual(unwrap(result), 1)
    }
        
    func test_container_flatMap_operator_() {
        let result = Maybe(20) >>- half >>- half
        
        XCTAssertEqual(unwrap(result), 5)
    }
}

func half(_ a: Int) -> Maybe<Int> {
    a % 2 == 0 ? Maybe(a / 2) : Maybe<Int>.none
}

func addition(_ a: Int, b: Int) -> Int {
    a + b
}

func unwrap<A>(_ result: Maybe<A>) -> A {
    guard case let .value(v) = result else {
        fatalError()
    }
    
    return v
}

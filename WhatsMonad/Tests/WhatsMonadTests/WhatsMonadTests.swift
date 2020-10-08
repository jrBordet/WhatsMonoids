import XCTest
@testable import WhatsMonad

final class WhatsMonadTests: XCTestCase {
    
    // MARK: - Alternative

    func test_maybe_alternative() {
        let result = Maybe<Int>.value(42) <|> Maybe(0)
        
        switch result {
        case .none:
            fatalError()
        case let .value(x):
            XCTAssertEqual(x, 42)
        }
    }
    
    func test_maybe_alternative_none() {
        let result = Maybe<Int>.none <|> Maybe(0)
        
        switch result {
        case .none:
            fatalError()
        case let .value(x):
            XCTAssertEqual(x, 0)
        }
    }
    
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
        
        let result = pipe(incr, square) <^> Maybe<Int>(3)
        
        let fancy = { (i: Int) in "fancy \(i)" }
                
        let fancy_incr = pipe(incr, fancy) <^> Maybe<Int>(3)
        
        XCTAssertEqual(unwrap(result), 16)
    }
    
    func test_array_as_functor() {
        let transform = pipe({ $0 + 2 }, { $0 + 1 })
         
        let result = transform <^> [0, 1, 2, 3] // [0, 1, 2, 3].map(transform)
        
        XCTAssertEqual(result, [3, 4, 5, 6])
    }
    
    func test_optional_as_functor() {
        let a: Int? = 3
        
        let transform = pipe({ $0 + 2 }, { $0 + 1 })

        let result = transform <^> a // a.map(transform)
        
        XCTAssertEqual(result, 6)
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
    
    func test_container_apply_3() {
        let a = Maybe(41)
        let b = Maybe(1)
        
        let result = curry(addition) <^> a <*> b
        
        XCTAssertEqual(unwrap(result), 42)
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
    
    //    f        >>= return  ==  f
    func test_monad_identity_law() {
        let f = Maybe<Int>(1) >>- MaybeId
        
        // Maybe<Int>(1).flatMap { v in MaybeId(v) }
        
        guard case let .value(v) = f else {
            fatalError()
        }
        
        XCTAssertEqual(v, 1)
    }
    
    // Secondo assioma - Legge dell'associatività
    // https://it.wikipedia.org/wiki/Monade_(informatica)
    // Un insieme di tre funzioni, possono essere combinate in due modi equivalenti.
    
//    func test_monad_composition_law() {
//        //(f >>- g) >>- h       ==    f >>- (\x -> g x >>- h)
//        let result = Maybe(20) >>- half >>- half
//        // func >>-<A, B>(_ a: Maybe<A>, f: @escaping(A) -> Maybe<B>) -> Maybe<B>
////        let compute: (Int) -> Maybe<Int> = pipe(curry(half), curry(half))
//
//        let f = flatMap(half(_:))
//
//        let a = Maybe<Int>(20).flatMap(half(_:)).flatMap(half(_:))//f(Maybe<Int>(20))
//
//        switch a {
//        case .none:
//            fatalError()
//        case let .value(v):
//            XCTAssertEqual(v, 5)
//        }
//    }
    
    // https://wiki.haskell.org/Monad_laws
    func test_monad_composition_law() {
        //(f >>- g) >>- h       ==    f >>- (\x -> g x >>- h)
        let x = Maybe(20)
        let expectedResult = 11
        
        let result = x >>- half >>- incr
        
        XCTAssertEqual(unwrap(result), expectedResult)
        
        let a = x >>- half
        let result_2 = a >>- incr(_:)
                        
        XCTAssertEqual(unwrap(result_2), expectedResult)
    }
    
    func test_kleisli_operator() {
        let f3: (Int) -> Maybe<String> = { Maybe.value("fancy \($0)") }
        
        // (f >=> g) >=> h
        // f >=> (g >=> h)
//
        let first = (half(_:) >=> half(_:)) >=> f3
        let second = half(_:) >=> (half(_:) >=> f3)

        let result = first(20)
        let result_2 = second(20)
        
        switch result {
        case .none:
            fatalError()
        case let .value(v):
            XCTAssertEqual(v, "fancy 5")
        }
        
        switch result_2 {
        case .none:
            fatalError()
        case let .value(v):
            XCTAssertEqual(v, "fancy 5")
        }
        
    }
    
}

func MaybeId<A>(_ a: A) -> Maybe<A> {
    Maybe(a)
}

func half(_ a: Int) -> Maybe<Int> {
    a % 2 == 0 ? Maybe(a / 2) : Maybe<Int>.none
}

func incr(_ a: Int) -> Maybe<Int> {
    a % 2 == 0 ? Maybe(a + 1) : Maybe<Int>.none
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

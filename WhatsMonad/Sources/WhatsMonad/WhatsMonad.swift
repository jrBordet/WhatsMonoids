import Foundation

precedencegroup Map {
    associativity: left
    higherThan: Apply
}

precedencegroup Apply {
    associativity: left
    higherThan: DefaultPrecedence
}

precedencegroup FlatMap {
    associativity: left
    higherThan: Apply
}

infix operator <^>: Map

public func <^><A, B>(
    _ f: @escaping(A) -> B,
    a: Maybe<A>
) -> Maybe<B> {
    a.map(f)
}

public func <^><A, B>(
    _ f: @escaping(A) -> B,
    _ a: [A]
) -> [B] {
    a.map(f)
}

public func <^><A, B>(
    _ f: @escaping(A) -> B,
    _ a: A?
) -> B? {
    a.map(f)
}

infix operator <*>: Apply

func <*><A, B>(
    _ f: Maybe<(A) -> B>,
    _ a: Maybe<A>
) -> Maybe<B> {
    a.apply(f)
}

func <*><A, B>(
    _ f: [(A) -> B],
    _ a: [A]
) -> [B] {
    a.apply(f)
}

func <^><A, B>(
    _ f: [(A) -> B],
    _ a: [A]
) -> [B] {
    a.apply(f)
}

infix operator <|>

public func <|><A>(
    _ a: Maybe<A>,
    _ alternative: Maybe<A>
) -> Maybe<A> {
    ifVal(a, alternative)
}

public func ifVal<A>(
    _ a: Maybe<A>,
    _ alternative: Maybe<A>
) -> Maybe<A> {
    guard case .value = a else {
        return alternative
    }
    
    return a
}

extension Array {
    func apply<A>(_ fs: [(Element) -> A]) -> [A] {
        var result = [A]()
        
        for f in fs {
            for element in self.map(f) {
                result.append(element)
            }
        }
        
        return result
    }
}

public func id<A>(_ a: A) -> A {
    a
}

public func apply<A, B>(
    _ a: A,
    _ f: (A) -> B
) -> B {
    f(a)
}

infix operator >>-: FlatMap

func >>-<A, B> (_ a: Maybe<A>, f: @escaping(A) -> Maybe<B>) -> Maybe<B> {
    a.flatMap(f)
}

//infix operator >>>: FlatMap
//
//func >>><A, B> (_ f: @escaping(A) -> Maybe<B>) -> (Maybe<A>) -> Maybe<B> {
//    flatMap(f)
//}

//The monad composition operator (also known as the Kleisli composition operator) is defined in Control.Monad:

//prefix operator >=>
//
//public prefix func >=> <A, B>(_ f: @escaping(A) -> Maybe<B>) -> (Maybe<A>) -> Maybe<B> {
//    flatMap(f)
//}

public func pipe<A, B, C>(
    _ f: @escaping (A) -> B,
    _ g: @escaping (B) -> C
)-> (A) -> C {
    return { a in
        g(f(a))
    }
}

public func incr(_ i: Int) -> Int { i + 1 }

public enum Maybe<A> {
    case none
    case value(A)
    
    public init(_ v: A) {
        self = .value(v)
    }
    
    func map<B>(_ f: @escaping (A) -> B) -> Maybe<B> {
        guard case let .value(t) = self else {
            return .none
        }
        
        return .value(f(t))
    }
    
    func apply<B>(_ f: Maybe<((A) -> B)>) -> Maybe<B> {
        guard case let .value(transform) = f else {
            return .none
        }
        
        return self.map(transform)
        
        //        switch f {
        //        case .none:
        //            return .none
        //        case let .value(tranform):
        //            return self.map(tranform)
        //        }
        
        //        switch f {
        //        case .none:
        //            return .none
        //        case let .value(transform): // (A) -> B)
        //            switch self {
        //            case .none:
        //                return .none
        //            case let .value(a):
        //                return Maybe<B>(transform(a))
        //            }
        //        }
    }
    
    func flatMap<B>(_ f: @escaping(A) -> Maybe<B>) -> Maybe<B> {
        guard case let .value(a) = self else {
            return .none
        }
        
        switch f(a) {
        case .none:
            return .none
        case let .value(v):
            return Maybe<B>(v)
        }
    }
}


public func zip<A, B, C: Equatable>(_ lhs: Maybe<A>, rhs: Maybe<B>) -> Maybe<C> {
    fatalError()
}

public func unwrap<A>(_ lhs: Maybe<A>, rhs: Maybe<A>) throws -> (A, A) {
    guard
        case let .value(vLhs) = lhs,
        case let .value(vRhls) = rhs else {
        throw NSError(domain: "assertion failed - no value found", code: -1, userInfo: nil)
    }
    
    return (vLhs, vRhls)
}

func map<A, B>(
    _ f: @escaping (A) -> B
) -> (Maybe<A>) -> Maybe<B> {
    return { result in
        switch result {
        case .none:
            return .none
        case let  .value(t):
            return .value(f(t))
        }
    }
}

infix operator >=>: FlatMap

func >=><A, B, C>(
    _ lhs: @escaping(A) -> Maybe<B>,
    _ rhs: @escaping(B) -> Maybe<C>
) -> (A) -> Maybe<C> {
    return { a in
        //lhs(a).flatMap(rhs)
        flatMap(rhs)(lhs(a))
    }
}

func kleisli<A, B, C>(
    _ lhs: @escaping(A) -> Maybe<B>,
    _ rhs: @escaping(B) -> Maybe<C>
) -> (A) -> Maybe<C> {
    return { a in
        lhs(a).flatMap(rhs)
    }
}

func flatMap<A, B>(_ f: @escaping(A) -> Maybe<B>) -> (Maybe<A>) -> Maybe<B> {
    return { fA in
        guard case let .value(a) = fA else {
            return .none
        }
        
        switch f(a) {
        case .none:
            return .none
        case let .value(b):
            return Maybe<B>(b)
        }
    }
}

public func curry<A, B, C>(
    _ f: @escaping(A, B) -> C
) -> (A) -> (B) -> C {
    return { a in
        return { b in
            f(a, b)
        }
    }
}

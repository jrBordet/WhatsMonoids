struct WhatsMonad {
    var text = "Hello, World!"
}


public func incr(_ i: Int) -> Int { i + 1 }

func notreachable() {}

public enum Container<T> {
    case error
    case value(T)
    
    public init(_ v: T) {
         self = .value(v)
     }
    
    func map<G>(_ f: @escaping (T) -> G) -> Container<G> {
        guard case let .value(t) = self else {
            return .error
        }
        
        return .value(f(t))
    }
}

func map<T, G>(_ f: @escaping (T) -> G) -> (Container<T>) -> Container<G> {
    return { result in
        switch result {
        case .error:
            return .error
        case let  .value(t):
            return .value(f(t))
        }
    }
}


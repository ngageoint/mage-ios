import Foundation

public struct AnyUseCaseRegistration: Sendable {
    public let register: @MainActor @Sendable (UseCaseFactory) -> Void
    
    public init(_ register: @MainActor @escaping @Sendable (UseCaseFactory) -> Void) {
        self.register = register
    }
}

public protocol UseCase { }

public struct UseCaseKey<T>: Hashable, Sendable {
    public init() {}
}

@MainActor
public final class UseCaseFactory: Sendable {
    
    private var factories: [AnyHashable: () throws -> Any] = [:]
    private var instances: [AnyHashable: Any] = [:]
    
    public init() {}
    
    public func register<T>(
        _ key: UseCaseKey<T>,
        factory: @escaping () throws -> T
    ) {
        factories[key] = {
            return try factory()
        }
    }
    
    public func resolve<T>(
        _ key: UseCaseKey<T>
    ) async -> T {
        
        if let cached = instances[key] as? T {
            return cached
        }
        
        guard let factory = factories[key] else {
            fatalError("No factory registered for \(T.self)")
        }
        
        do {
            let instance = try factory()
            
            guard let typed = instance as? T else {
                fatalError("Type mismatch for \(T.self)")
            }
            
            instances[key] = typed
            return typed
        } catch {
            fatalError("Error constructing use case for \(T.self): \(error)")
        }
        
        
    }
}

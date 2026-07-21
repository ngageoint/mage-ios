//
//  PersistenceContainer.swift
//  Persistence
//
//  Created by Daniel Barela on 6/19/26.
//

import Foundation

public final class PersistenceContainer: NSObject, @unchecked Sendable {
    public static let shared = PersistenceContainer()
    
    private var persistence: PersistenceProtocol?
    
    private let lock = NSLock()
    
    public func configure(_ persistence: PersistenceProtocol) {
        lock.lock()
        defer { lock.unlock() }
        
        precondition(self.persistence == nil)
        self.persistence = persistence
    }
    
    public func get() -> PersistenceProtocol {
        guard let persistence else {
            fatalError("Not configured")
        }
        return persistence
    }
}

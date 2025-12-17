//
//  UserDefaults+Publisher.swift
//  MAGE
//
//  Created by Paul Solt on 12/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Combine
import Foundation

extension UserDefaults {
    
    /// A publisher that fires when settings change on UserDefaults. Use this to reduce unwanted updates
    /// and combine with `Publisher.mergeMany([])` to group related settings changes into one event stream.
    ///
    /// - Only fires when values change. It ignores initial state and duplicate changes (Assigning the same value)
    /// - The type is erased and standardized so that it can be used with `Publisher.mergeMany([])`
    ///
    /// - Parameter keyPath: The `KeyPath` to the specific `UserDefaults` property to observe.
    /// - Returns: An `AnyPublisher<Void, Never>` that fires only when the settings value actually changes.
    func settingsChangePublisher<T: Equatable>(_ keyPath: KeyPath<UserDefaults, T>) -> AnyPublisher<Void, Never> {
            publisher(for: keyPath)
                .dropFirst()
                .removeDuplicates()
                .handleEvents(receiveOutput: { newValue in
                    MageLogger.misc.debug("Setting changed: \(String(describing: keyPath)) -> \(String(describing: newValue))")
                })
                .map { _ in }
                .eraseToAnyPublisher()
    }
}

//
//  RoleRepository.swift
//  MAGETests
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct RoleRepositoryProviderKey: InjectionKey {
    static var currentValue: RoleRepository = RoleRepositoryImpl()
}

extension InjectedValues {
    var roleRepository: RoleRepository {
        get { Self[RoleRepositoryProviderKey.self] }
        set { Self[RoleRepositoryProviderKey.self] = newValue }
    }
}

extension Set {
    func setmap<U>(transform: (Element) -> U) -> Set<U> {
        return Set<U>(self.lazy.map(transform))
    }
}

protocol RoleRepository {
    func getRole(remoteId: String) -> RoleModel?
}

class RoleRepositoryImpl: ObservableObject, RoleRepository {
    @Injected(\.roleLocalDataSource)
    var localDataSource: RoleLocalDataSource
    
    func getRole(remoteId: String) -> RoleModel? {
        localDataSource.getRole(remoteId: remoteId)
    }
}

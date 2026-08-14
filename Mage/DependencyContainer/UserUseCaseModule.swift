// 
//     
//  UserUseCaseModule.swift
//  MAGE
//
// 


import UseCaseFactory
import UserFetch

@MainActor
enum UserUseCaseModule: UseCaseModule {
    static func build(deps: AppDependencies) -> [AnyUseCaseRegistration] {
        [
            .init { factory in
                factory.register(.EventUserFetchUseCase) {
                    return EventUserFetchUseCase(userFetchRepository: deps.userFetch)
                }
            }
        ]
    }
}

extension UseCaseKey {
    static var EventUserFetchUseCase: UseCaseKey<EventUserFetchUseCase> { .init() }
}

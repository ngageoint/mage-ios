// 
//     
//  UserUseCaseModule.swift
//  MAGE
//
// 


import UseCaseFactory
import UserFetch
import User

@MainActor
enum UserUseCaseModule: UseCaseModule {
    static func build(deps: AppDependencies) -> [AnyUseCaseRegistration] {
        [
            .init { factory in
                factory.register(.EventUserFetchUseCase) {
                    return EventUserFetchUseCase(userFetchRepository: deps.userFetch)
                }
            },
            .init { factory in
                factory.register(.GetMyselfUseCase) {
                    return GetMyselfUseCase(
                        repository: deps.userRepository
                    )
                }
            },
            .init { factory in
                factory.register(.GetUserUseCase) {
                    return GetUserUseCase(
                        repository: deps.userRepository
                    )
                }
            }
            ,
            .init { factory in
                factory.register(.RefreshUserUseCase) {
                    return RefreshUserUseCase(
                        repository: deps.userRepository
                    )
                }
            }
        ]
    }
}

extension UseCaseKey {
    static var EventUserFetchUseCase: UseCaseKey<EventUserFetchUseCase> { .init() }
    static var GetMyselfUseCase: UseCaseKey<GetMyselfUseCase> { .init() }
    static var GetUserUseCase: UseCaseKey<GetUserUseCase> { .init() }
    static var RefreshUserUseCase: UseCaseKey<RefreshUserUseCase> { .init() }
}

// 
//     
//  LocationUseCaseModule.swift
//  MAGE
//
// 


import UseCaseFactory

@MainActor
enum LocationUseCaseModule: UseCaseModule {
    static func build(deps: AppDependencies) -> [AnyUseCaseRegistration] {
        [
            .init { factory in
                factory.register(.EventLocationFetchUseCase) {
                    return EventLocationFetchUseCase(
                        repository: deps.locationFetch,
                        userRepository: deps.userRepository
                    )
                }
            }
        ]
    }
}

extension UseCaseKey {
    static var EventLocationFetchUseCase: UseCaseKey<EventLocationFetchUseCase> { .init() }
}

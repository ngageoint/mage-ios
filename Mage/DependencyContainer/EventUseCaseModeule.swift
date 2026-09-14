// 
//     
//  EventUseCaseModeule.swift
//  MAGE
//
// 


import UseCaseFactory
import EventFetch

enum EventUseCaseModeule: UseCaseModule {
    static func build(deps: AppDependencies) -> [AnyUseCaseRegistration] {
        [
            .init { factory in
                factory.register(.FetchEventsUseCase) {
                    return FetchEventsUseCase(
                        repository: deps.eventFetch,
                        eventRepository: deps.eventRepository
                    )
                }
            }
        ]
    }
}

extension UseCaseKey {
    static var FetchEventsUseCase: UseCaseKey<FetchEventsUseCase> { .init() }
}

// 
//     
//  SettingsUseCaseModule.swift
//  MAGE
//
// 

import UseCaseFactory
import SettingsFetch
import Settings

@MainActor
enum SettingsUseCaseModule: UseCaseModule {
    static func build(deps: AppDependencies) -> [AnyUseCaseRegistration] {
        [
            .init { factory in
                factory.register(.RefreshSettingsUseCase) {
                    return RefreshSettingsUseCase(
                        repository: deps.settingsRepository,
                        fetchRepository: deps.settingsFetch
                    )
                }
            },
            .init { factory in
                factory.register(.ObserveSettingsUseCase) {
                    return ObserveSettingsUseCaseImpl(
                        repository: deps.settingsRepository
                    )
                }
            }
        ]
    }
}

extension UseCaseKey {
    static var RefreshSettingsUseCase: UseCaseKey<RefreshSettingsUseCase> { .init() }
    static var ObserveSettingsUseCase: UseCaseKey<ObserveSettingsUseCase> { .init() }
}

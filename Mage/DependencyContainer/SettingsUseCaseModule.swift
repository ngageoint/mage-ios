// 
//     
//  SettingsUseCaseModule.swift
//  MAGE
//
// 

import UseCaseFactory
import SettingsFetch

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
            }
        ]
    }
}

extension UseCaseKey {
    static var RefreshSettingsUseCase: UseCaseKey<RefreshSettingsUseCase> { .init() }
}

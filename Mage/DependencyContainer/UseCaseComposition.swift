// 
//     
//  UseCaseComposition.swift
//  MAGE
//
// 


import UseCaseFactory

@MainActor
final class UseCaseComposition {
    static func build(
        deps: AppDependencies
    ) -> UseCaseFactory {
        
        let factory = UseCaseFactory()
        
        let modules: [any UseCaseModule.Type] = [
            SettingsUseCaseModule.self,
            UserUseCaseModule.self,
            LocationUseCaseModule.self
        ]
        
        for module in modules {
            let registrations = module.build(deps: deps)
            registrations.forEach { $0.register(factory) }
        }
        
        return factory
    }
}

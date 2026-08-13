// 
//     
//  UseCaseModule.swift
//  MAGE
//
// 


import UseCaseFactory

@MainActor
protocol UseCaseModule {
    static func build(
        deps: AppDependencies
    ) -> [AnyUseCaseRegistration]
}

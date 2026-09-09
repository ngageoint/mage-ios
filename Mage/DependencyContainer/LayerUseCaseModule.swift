// 
//     
//  LayerUseCaseModule.swift
//  MAGE
//
// 

import UseCaseFactory

enum LayerUseCaseModule: UseCaseModule {
    static func build(deps: AppDependencies) -> [AnyUseCaseRegistration] {
        [
            .init { factory in
                factory.register(.RefreshLayersUseCase) {
                    return RefreshLayersUseCase(repository: deps.layerFetch)
                }
            },
            .init { factory in
                factory.register(.StaticLayerDataFetchUseCase) {
                    return StaticLayerDataFetchUseCase(
                        repository: deps.staticLayerDataFetch
                    )
                }
            }
        ]
    }
}

extension UseCaseKey {
    static var RefreshLayersUseCase: UseCaseKey<RefreshLayersUseCase> { .init() }
    static var StaticLayerDataFetchUseCase: UseCaseKey<StaticLayerDataFetchUseCase> { .init() }
}

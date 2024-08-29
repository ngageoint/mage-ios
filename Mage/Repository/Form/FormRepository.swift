//
//  FormRepository.swift
//  MAGE
//
//  Created by Dan Barela on 7/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct FormRepositoryProviderKey: InjectionKey {
    static var currentValue: FormRepository = FormRepositoryImpl()
}

extension InjectedValues {
    var formRepository: FormRepository {
        get { Self[FormRepositoryProviderKey.self] }
        set { Self[FormRepositoryProviderKey.self] = newValue }
    }
}

protocol FormRepository {
    func getForm(formId: NSNumber) -> FormModel?
}

class FormRepositoryImpl: ObservableObject, FormRepository {
    @Injected(\.formLocalDataSource)
    var localDataSource: FormLocalDataSource
    
    // TODO: This needs to be a model not a managed object
    func getForm(formId: NSNumber) -> FormModel? {
        localDataSource.getForm(formId: formId)
    }
}

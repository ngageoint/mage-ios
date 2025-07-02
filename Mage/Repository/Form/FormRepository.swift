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
    static var formModelCache: [NSNumber:FormModel] = [:]
    
    @Injected(\.formLocalDataSource)
    var localDataSource: FormLocalDataSource
    
    // TODO: This needs to be a model not a managed object
    func getForm(formId: NSNumber) -> FormModel? {
        // NOTE: this gets called around 20K times with 5K observations
        if let form = FormRepositoryImpl.formModelCache[formId] {
            return form
        } else {
            let form = localDataSource.getForm(formId: formId)
            FormRepositoryImpl.formModelCache[formId] = form
            return form
        }
    }
}

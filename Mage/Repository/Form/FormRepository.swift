//
//  FormRepository.swift
//  MAGE
//
//  Created by Dan Barela on 7/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct FormRepositoryProviderKey: InjectionKey {
    static var currentValue: FormRepository = FormRepository()
}

extension InjectedValues {
    var formRepository: FormRepository {
        get { Self[FormRepositoryProviderKey.self] }
        set { Self[FormRepositoryProviderKey.self] = newValue }
    }
}

class FormRepository: ObservableObject {
    @Injected(\.formLocalDataSource)
    var localDataSource: FormLocalDataSource
    
    // TODO: This needs to be a model not a managed object
    func getForm(formId: NSNumber) -> Form? {
        localDataSource.getForm(formId: formId)
    }
}

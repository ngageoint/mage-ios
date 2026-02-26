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
    func clearCache()
}

class FormRepositoryImpl: ObservableObject, FormRepository {
    @Injected(\.formLocalDataSource)
    var localDataSource: FormLocalDataSource

    private var formCache: [Int64: FormModel] = [:]
    private let formCacheQueue = DispatchQueue(label: "mil.nga.mage.formRepository.formCache", attributes: .concurrent)
    
    func getForm(formId: NSNumber) -> FormModel? {
        let cacheKey = formId.int64Value
        if let cachedForm = formCacheQueue.sync(execute: { formCache[cacheKey] }) {
            return cachedForm
        }

        let form = localDataSource.getForm(formId: formId)
        if let form = form {
            formCacheQueue.async(flags: .barrier) { [weak self] in
                self?.formCache[cacheKey] = form
            }
        }
        return form
    }
    
    func clearCache() {
        formCacheQueue.async(flags: .barrier) { [weak self] in
            self?.formCache.removeAll()
        }
    }
}

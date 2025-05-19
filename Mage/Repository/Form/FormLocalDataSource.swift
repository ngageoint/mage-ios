//
//  FormLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 7/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import Combine
import UIKit
import BackgroundTasks
import NSManagedObjectContextExtensions

private struct FormLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: FormLocalDataSource = FormCoreDataDataSource()
}

extension InjectedValues {
    var formLocalDataSource: FormLocalDataSource {
        get { Self[FormLocalDataSourceProviderKey.self] }
        set { Self[FormLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol FormLocalDataSource {
    func getForm(formId: NSNumber) -> FormModel?
    
}

class FormCoreDataDataSource: CoreDataDataSource<Form>, FormLocalDataSource, ObservableObject {
    
    func getForm(formId: NSNumber) -> FormModel? {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        return context.performAndWait {
             return context.fetchFirst(Form.self, key: "formId", value: formId).map { form in
                 FormModel(form: form)
             }
        }
    }
}

//
//  FormRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class FormRepositoryMock: FormRepository {
    var forms: [FormModel] = []
    func getForm(formId: NSNumber) -> FormModel? {
        forms.first { form in
            form.formId == Int(truncating: formId)
        }
    }
}

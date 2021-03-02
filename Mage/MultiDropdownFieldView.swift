//
//  MultiDropdownFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 2/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class MultiDropdownFieldView : BaseFieldView {
    
    lazy var textField: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        controller.textInput = textField;
        if (value != nil) {
            textField.text = getDisplayValue();
        }
        return textField;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil);
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: [String]?) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        self.addFieldView();
    }
    
    func addFieldView() {
        if (self.editMode) {
            viewStack.addArrangedSubview(textField);
            let tapView = addTapRecognizer();
            tapView.accessibilityLabel = field[FieldKey.name.key] as? String;
            setupController();
        } else {
            viewStack.addArrangedSubview(fieldNameLabel);
            viewStack.addArrangedSubview(fieldValue);
            fieldValue.text = getDisplayValue();
        }
    }
    
    func getDisplayValue() -> String? {
        return getValue()?.joined(separator: ", ")
    }
    
    override func setValue(_ value: Any?) {
        if (value is String) {
            self.value = [value];
        } else {
            self.value = value;
        }
        
        self.editMode ? (textField.text = getDisplayValue()) : (fieldValue.text = getDisplayValue());
    }
    
    func getValue() -> [String]? {
        return value as? [String];
    }
    
    override func isEmpty() -> Bool {
        return (textField.text ?? "").count == 0;
    }
    
    override func getErrorMessage() -> String {
        return ((field[FieldKey.title.key] as? String) ?? "Field ") + " is required";
    }
}

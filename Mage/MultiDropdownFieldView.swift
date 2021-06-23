//
//  MultiDropdownFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 2/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class MultiDropdownFieldView : BaseFieldView {
    
    lazy var textField: MDCFilledTextField = {
        let textField = MDCFilledTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        textField.trailingView = UIImageView(image: UIImage(named: "expand"));
        textField.trailingViewMode = .always;
        if (value != nil) {
            textField.text = getDisplayValue();
        }
        textField.leadingAssistiveLabel.text = " ";
        textField.sizeToFit();
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
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        textField.applyTheme(withScheme: scheme);
    }
    
    func addFieldView() {
        if (self.editMode) {
            viewStack.addArrangedSubview(textField);
            let tapView = addTapRecognizer();
            tapView.accessibilityLabel = field[FieldKey.name.key] as? String;
            setPlaceholder(textField: textField);
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
    
    override func setValid(_ valid: Bool) {
        super.setValid(valid);
        if (valid) {
            textField.leadingAssistiveLabel.text = " ";
            if let safeScheme = scheme {
                textField.applyTheme(withScheme: safeScheme);
            }
        } else {
            textField.applyErrorTheme(withScheme: globalErrorContainerScheme());
            textField.leadingAssistiveLabel.text = getErrorMessage();
        }
    }
}

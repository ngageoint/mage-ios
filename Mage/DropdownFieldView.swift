//
//  DropdownFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/27/20.
//  Updated by Brent Michalski on 06/23/2025
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

class DropdownFieldView : BaseFieldView {
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .never
        textField.rightView = UIImageView(image: UIImage(named: "arrow_drop_down"))
        textField.rightViewMode = .always
        textField.accessibilityLabel = "\(field[FieldKey.name.key] as? String ?? "") value"
        textField.placeholder = "Select"
        textField.tintColor = .clear  // Prevents cursor
        textField.delegate = self
        return textField
    }()
    
    override func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme else { return }

        textField.textColor = scheme.colorScheme?.primaryColor
        textField.backgroundColor = scheme.colorScheme?.surfaceColor?.withAlphaComponent(0.87)
        textField.rightView?.tintColor = scheme.colorScheme?.onSurfaceColor?.withAlphaComponent(0.6)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil)
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: String?) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode)
        self.addFieldView()
    }
    
    func addFieldView() {
        if editMode {
            viewStack.addArrangedSubview(textField)
            let tapView = addTapRecognizer()
            tapView.accessibilityLabel = field[FieldKey.name.key] as? String
            setPlaceholder(textField: textField)
            textField.text = getDisplayValue()
        } else {
            viewStack.addArrangedSubview(fieldNameLabel)
            viewStack.addArrangedSubview(fieldValue)
            fieldValue.text = getDisplayValue()
        }
    }
    
    func getDisplayValue() -> String? {
        return getValue()
    }
    
    override func setValue(_ value: Any?) {
        self.value = value
        
        if editMode {
            textField.text = getDisplayValue()
        } else {
            fieldValue.text = getDisplayValue()
        }
    }
    
    func getValue() -> String? {
        return value as? String
    }
    
    override func isEmpty() -> Bool {
        return (textField.text ?? "").isEmpty
    }
    
    override func setValid(_ valid: Bool) {
        super.setValid(valid)
            
        if valid {
            textField.layer.borderColor = UIColor.clear.cgColor
            textField.layer.borderWidth = 0
        } else {
            textField.layer.borderColor = UIColor.systemRed.cgColor
            textField.layer.borderWidth = 1
            textField.layer.cornerRadius = 5
        }
    }
    
    func getInvalidChoice() -> String? {
        guard let choices = field[FieldKey.choices.key] as? [[String: Any]], let value = value as? String else { return nil }

        let validChoices = choices.compactMap { $0[FieldKey.title.key] as? String }
        return validChoices.contains(value) ? nil : value
    }
    
    override func isValid(enforceRequired: Bool = false) -> Bool {
        return getInvalidChoice() == nil && super.isValid(enforceRequired: enforceRequired)
    }
    
    override func getErrorMessage() -> String {
        if let invalidChoice = getInvalidChoice() {
            return "\(invalidChoice) is not a valid option."
        }
        
        return ((field[FieldKey.title.key] as? String) ?? "Field ") + " is required"
    }
}


extension DropdownFieldView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        delegate?.fieldTapped(field)
        return false
    }
}

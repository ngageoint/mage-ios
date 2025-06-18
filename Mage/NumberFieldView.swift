//
//  NumberFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/26/20.
//  Updated by Brent Michalski on 6/18/25
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

class NumberFieldView : BaseFieldView {
    private var shouldResign: Bool = false
    private var number: NSNumber?
    private var min: NSNumber?
    private var max: NSNumber?
    
    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    private lazy var helperLabel: UILabel = {
        let label = UILabel(forAutoLayout: ())
        label.textColor = .secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.text = helperText
        return label
    }()

    lazy var textField: UITextField = {
        let textField = UITextField(forAutoLayout: ())
        textField.borderStyle = .roundedRect
        textField.delegate = self
        textField.keyboardType = .decimalPad
        textField.inputAccessoryView = accessoryView
        textField.accessibilityLabel = field[FieldKey.name.key] as? String ?? ""
        
        // Trailing icon setup
        let iconView = UIImageView(image: UIImage(systemName: "number"))
        iconView.tintColor = .secondaryLabel
        textField.rightView = iconView
        textField.rightViewMode = .always
        
        return textField
    }()
    
    private lazy var accessoryView: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.autoSetDimension(.height, toSize: 44)
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let labelItem = UIBarButtonItem(customView: helperLabel)
                
        toolbar.items = [cancelBarButton, flexSpace, labelItem, flexSpace, doneBarButton]
        return toolbar
    }()
    
    lazy var helperText: String? = {
        var helper: String? = nil
        if (self.min != nil && self.max != nil) {
            helper = "Must be between \(self.min!) and \(self.max!)"
        } else if (self.min != nil) {
            helper = "Must be greater than \(self.min!) "
        } else if (self.max != nil) {
            helper = "Must be less than \(self.max!)"
        }
        return helper
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.init(field: field, delegate: delegate, value: nil)
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: String?) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode)
        
        self.min = self.field[FieldKey.min.key] as? NSNumber
        self.max = self.field[FieldKey.max.key] as? NSNumber
        
        setupInputView()
        setValue(value)
    }
    
    override func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme else { return }
        super.applyTheme(withScheme: scheme)
        
        textField.textColor = scheme.colorScheme.onSurfaceColor
        textField.backgroundColor = scheme.colorScheme.surfaceColor
        helperLabel.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        if let icon = textField.rightView as? UIImageView {
            icon.tintColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        }
    }
    
    func setupInputView() {
        if (editMode) {
            viewStack.addArrangedSubview(textField)
            viewStack.addArrangedSubview(helperLabel)
        } else {
            viewStack.addArrangedSubview(fieldNameLabel)
            viewStack.addArrangedSubview(fieldValue)
            fieldValue.text = number?.stringValue
        }
    }
    
    override func getValue() -> Any? {
        return number
    }
    
    func getValue() -> NSNumber? {
        return number
    }
    
    override func setValue(_ value: Any?) {
        setValue(value as? String)
    }
    
    func setValue(_ value: String?) {
        number = value.flatMap { formatter.number(from: $0) }
        if editMode {
            textField.text = number?.stringValue
        } else {
            fieldValue.text = number?.stringValue
        }
    }
    
    @objc func doneButtonPressed() {
        shouldResign = true
        textField.resignFirstResponder()
    }
    
    @objc func cancelButtonPressed() {
        shouldResign = true
        textField.text = number?.stringValue
        textField.resignFirstResponder()
    }
    
    override func isEmpty() -> Bool{
        return textField.text?.isEmpty ?? true
    }
    
    override func getErrorMessage() -> String {
        return helperText ?? "Must be a number"
    }
    
    override func isValid(enforceRequired: Bool = false) -> Bool {
        return isValid(enforceRequired: enforceRequired, number: self.number)
    }
    
    private func isValid(enforceRequired: Bool = false, number: NSNumber?) -> Bool {
        isValid(enforceRequired: enforceRequired) && isValidNumber(number)
    }
    
    func isValidNumber(_ number: NSNumber?) -> Bool {
        guard !isEmpty(), let number else { return false }

        if let min = self.min, number.doubleValue < min.doubleValue {
            return false
        }
        
        if let max = self.max, number.doubleValue > max.doubleValue {
            return false
        }

        return true
    }
    
    override func setValid(_ valid: Bool) {
        super.setValid(valid)
        
        if valid {
            helperLabel.text = helperText
        } else {
            helperLabel.text = getErrorMessage()
            helperLabel.textColor = scheme?.colorScheme.errorColor ?? .systemRed
        }
    }
}

extension NumberFieldView: UITextFieldDelegate {
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldResign
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let value = formatter.number(from: textField.text ?? "")
        let valid = isValid(enforceRequired: true, number: value)
        setValid(valid)
        
        if valid, value != nil, value?.stringValue != number?.stringValue {
            delegate?.fieldValueChanged(field, value: value)
        }
        
        number = value
        shouldResign = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // allow backspace
        if string.isEmpty {
            return true
        }
        
        if let text = textField.text as NSString? {
            let updatedText = text.replacingCharacters(in: range, with: string)
            let number = formatter.number(from: updatedText)
            
            if (number == nil) {
                return false
            }
            
            setValid(isValidNumber(number))
            return true
        }
        
        return false
    }
}

//
//  TextFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/6/20.
//  Updated by Brent Michalski on 6/23/2025
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit

class TextFieldView : BaseFieldView {
    private var multiline: Bool = false
    private var keyboardType: UIKeyboardType = .default
    private var shouldResign: Bool = false
    
    lazy var multilineTextField: UITextView  = {
        let textView = UITextView()
        textView.delegate = self
        textView.keyboardType = keyboardType
        textView.inputAccessoryView = accessoryView
        textView.autocapitalizationType = .none
        textView.accessibilityLabel = field[FieldKey.name.key] as? String ?? ""
        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        
        if let value = value as? String {
            textView.text = value
        }
        
        return textView
    }()
    
    lazy var singleLineTextField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.keyboardType = keyboardType
        textField.inputAccessoryView = accessoryView
        textField.autocapitalizationType = .none
        textField.accessibilityLabel = field[FieldKey.name.key] as? String ?? ""
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        
        if let value = value as? String {
            textField.text = value
        }
        
        return textField
    }()
    
    private lazy var accessoryView: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        toolbar.autoSetDimension(.height, toSize: 44)
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        doneBarButton.accessibilityLabel = "Done"
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        cancelBarButton.accessibilityLabel = "Cancel"
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [cancelBarButton, flexSpace, doneBarButton]
        return toolbar
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, multiline: Bool, keyboardType: UIKeyboardType = .default) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil, multiline: multiline)
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: String?, multiline: Bool = false, keyboardType: UIKeyboardType = .default) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode)
        self.multiline = multiline
        self.keyboardType = keyboardType
        self.addFieldView()
    }
    
    override func updateConstraints() {
        if !didSetupConstraints {
            if editMode {
                if multiline {
                    multilineTextField.autoPinEdgesToSuperviewEdges()
                } else {
                    singleLineTextField.autoPinEdgesToSuperviewEdges()
                }
            }
        }
        super.updateConstraints()
    }
    
    func addFieldView() {
        if editMode {
            if multiline {
                self.addSubview(multilineTextField)
            } else {
                self.addSubview(singleLineTextField)
            }
        } else {
            viewStack.addArrangedSubview(fieldNameLabel)
            viewStack.addArrangedSubview(fieldValue)
            
            if (field[FieldKey.type.key] as? String == FieldType.password.key) {
                fieldValue.text = "*********"
            } else {
                fieldValue.text = getValue()
            }
        }
    }
    
    override func setValue(_ value: Any?) {
        self.setValue(value as? String)
    }
    
    func setValue(_ value: String?) {
        self.value = value
        
        if multiline {
            editMode ? (multilineTextField.text = value) : (fieldValue.text = value)
        } else {
            editMode ? (singleLineTextField.text = value) : (fieldValue.text = value)
        }
    }
    
    func getValue() -> String? {
        return value as? String
    }
    
    override func isEmpty() -> Bool {
        if multiline {
            return (multilineTextField.text ?? "").isEmpty
        } else {
            return (singleLineTextField.text ?? "").isEmpty
        }
    }
    
    override func getErrorMessage() -> String {
        return ((field[FieldKey.title.key] as? String) ?? "Field ") + " is required"
    }
    
    override func setValid(_ valid: Bool) {
        super.setValid(valid)
        
        if multiline {
            multilineTextField.layer.borderColor = valid ? UIColor.systemGray4.cgColor : UIColor.red.cgColor
        } else {
            singleLineTextField.layer.borderColor = valid ? UIColor.systemGray4.cgColor : UIColor.red.cgColor
        }
    }
}

extension TextFieldView {
    func resignFieldFirstResponder() {
        shouldResign = true
        
        if multiline {
            multilineTextField.resignFirstResponder()
        } else {
            singleLineTextField.resignFirstResponder()
        }
    }
    
    @objc func doneButtonPressed() {
        resignFieldFirstResponder()
    }
    
    @objc func cancelButtonPressed() {
        setValue(self.value as? String ?? nil)
        resignFieldFirstResponder()
    }
}


extension TextFieldView: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        shouldResign = false
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldResign
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateValueIfNeeded(newValue: textField.text)
    }
}


extension TextFieldView: UITextViewDelegate {
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return shouldResign
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        updateValueIfNeeded(newValue: textView.text)
    }
    
    private func updateValueIfNeeded(newValue: String?) {
        if value as? String != newValue {
            value = newValue?.isEmpty == true ? nil : newValue
            delegate?.fieldValueChanged(field, value: value)
        }
        
        shouldResign = false
    }
}

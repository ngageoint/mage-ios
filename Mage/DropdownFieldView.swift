//
//  DropdownFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/27/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class DropdownFieldView : BaseFieldView {
    
    lazy var textField: MDCFilledTextField = {
        let textField = MDCFilledTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        textField.trailingView = UIImageView(image: UIImage(named: "arrow_drop_down"));
        textField.accessibilityLabel = "\(field[FieldKey.name.key] as? String ?? "") value"
        textField.trailingViewMode = .always;
        textField.leadingAssistiveLabel.text = " ";
        if (value != nil) {
            textField.text = getDisplayValue();
        }
        textField.sizeToFit();
        return textField;
    }()
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        textField.applyTheme(withScheme: scheme);
        textField.trailingView?.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil);
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: String?) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        self.addFieldView();
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
        return getValue();
    }
    
    override func setValue(_ value: Any?) {
        self.value = value
        self.editMode ? (textField.text = getDisplayValue()) : (fieldValue.text = getDisplayValue());
    }
    
    func getValue() -> String? {
        return value as? String;
    }
    
    override func isEmpty() -> Bool {
        return (textField.text ?? "").count == 0;
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
    
    func getInvalidChoice() -> String? {
        var choiceStrings: [String] = []
        if let choices = self.field[FieldKey.choices.key] as? [[String: Any]] {
            for choice in choices {
                if let choiceString = choice[FieldKey.title.key] as? String {
                    choiceStrings.append(choiceString)
                }
            }
        }
        
        if let value = self.value as? String {
            if (!choiceStrings.contains(value)) {
                return value;
            }
        }
        
        return nil;
    }
    
    override func isValid(enforceRequired: Bool = false) -> Bool {
        if getInvalidChoice() != nil {
            return false;
        }
        
        // verify the choices are in the list of choices in case defaults were set
        return super.isValid(enforceRequired: enforceRequired);
    }
    
    override func getErrorMessage() -> String {
        if let invalidChoice = getInvalidChoice() {
            return "\(invalidChoice) is not a valid option."
        }
        
        return ((field[FieldKey.title.key] as? String) ?? "Field ") + " is required";
    }
}

//
//  EditDropdownFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/27/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class EditDropdownFieldView : BaseFieldView {
    var didSetUpConstraints = false;
    
    lazy var textField: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        controller.textInput = textField;
        if (value != nil) {
            textField.text = (value as? [String])?.joined(separator: ", ");
        }
        return textField;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], delegate: ObservationEditListener? = nil) {
        self.init(field: field, delegate: delegate, value: nil);
    }
    
    convenience init(field: [String: Any], delegate: ObservationEditListener? = nil, value: String) {
        self.init(field: field, delegate: delegate, value: [value]);
    }
    
    init(field: [String: Any], delegate: ObservationEditListener? = nil, value: [String]?) {
        super.init(field: field, delegate: delegate, value: value);
        self.addFieldView();
        setupController();
    }
    
    func addFieldView() {
        self.addSubview(textField);
        let tapView = addTapRecognizer();
        tapView.accessibilityLabel = field[FieldKey.name.key] as? String;
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            textField.autoPinEdgesToSuperviewEdges();
        }
        super.updateConstraints();
    }
    
    override func setValue(_ value: Any) {
        if let stringValue = value as? String {
            textField.text = stringValue;
            self.value = [value];
        } else if let stringArray = value as? [String] {
            textField.text = stringArray.joined(separator: ", ");
            self.value = value;
        }
    }
    
    override func isEmpty() -> Bool {
        return (textField.text ?? "").count == 0;
    }
    
    override func setValid(_ valid: Bool) {
        if (valid) {
            controller.setErrorText(nil, errorAccessibilityValue: nil);
        } else {
            controller.setErrorText(((field[FieldKey.title.key] as? String) ?? "Field ") + " is required", errorAccessibilityValue: nil);
        }
    }
}

//
//  BaseFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/13/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField;

class BaseFieldView : UIView {
    internal var controller: MDCTextInputControllerFilled = MDCTextInputControllerFilled();
    internal var field: [String: Any]!;
    internal var delegate: (ObservationFormFieldListener & FieldSelectionDelegate)?;
    internal var fieldValueValid: Bool! = false;
    internal var value: Any?;
    
    private lazy var fieldSelectionCoordinator: FieldSelectionCoordinator? = {
        var fieldSelectionCoordinator: FieldSelectionCoordinator? = nil;
        if let safeDelegate: FieldSelectionDelegate = delegate {
            fieldSelectionCoordinator = FieldSelectionCoordinator(field: field, formField: self, delegate: safeDelegate);
        }
        return fieldSelectionCoordinator;
    }();
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(field: [String: Any], delegate: (ObservationFormFieldListener & FieldSelectionDelegate)?, value: Any?) {
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        
        self.field = field;
        self.delegate = delegate;
        self.value = value;
    }
    
    func setupController() {
        controller.placeholderText = field[FieldKey.title.key] as? String
        if ((field[FieldKey.required.key] as? Bool) == true) {
            controller.placeholderText = (controller.placeholderText ?? "") + " *"
        }
    }
    
    func setValue(_ value: Any) {
        preconditionFailure("This method must be overridden");
    }
    
    func getValue() -> Any? {
        return value;
    }
    
    func isEmpty() -> Bool {
        return false;
    }

    func setValid(_ valid: Bool) {
        fieldValueValid = valid;
    }

    func isValid() -> Bool {
        return isValid(enforceRequired: true);
    }

    func isValid(enforceRequired: Bool = false) -> Bool {
        if ((field[FieldKey.required.key] as? Bool) == true && enforceRequired && isEmpty()) {
            return false;
        }
        return true;
    }
    
    func addTapRecognizer() -> UIView {
        
        let tapView = UIView(forAutoLayout: ());
        self.addSubview(tapView);
        tapView.autoPinEdgesToSuperviewEdges();
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapView.addGestureRecognizer(tapGesture)
        return tapView;
    }
    
    @objc func handleTap() {
        fieldSelectionCoordinator?.fieldSelected();
    }
}

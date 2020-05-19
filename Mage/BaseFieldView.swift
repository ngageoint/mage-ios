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
    internal var controller: MDCTextInputControllerOutlined = MDCTextInputControllerOutlined();
    internal var field: NSDictionary!;
    internal var delegate: ObservationEditListener?;
    internal var fieldValueValid: Bool! = false;
    internal var value: Any?;
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(field: NSDictionary, delegate: ObservationEditListener?, value: Any?) {
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        
        self.field = field;
        self.delegate = delegate;
        self.value = value;
    }
    
    func setupController() {
        controller.placeholderText = field.object(forKey: "title") as? String
        if ((field.object(forKey: "required") as? Bool) == true) {
            controller.placeholderText = (controller.placeholderText ?? "") + " *"
        }
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
        if ((field.object(forKey: "required") as? Bool) == true && enforceRequired && isEmpty()) {
            return false;
        }
        return true;
    }
    
    func addTapRecognizer() {
        let tapView = UIView(forAutoLayout: ());
        self.addSubview(tapView);
        tapView.autoPinEdgesToSuperviewEdges();
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        tapView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        delegate?.fieldSelected?(field);
    }
}

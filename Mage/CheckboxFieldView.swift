//
//  CheckboxFieldView.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/28/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField

class CheckboxFieldView : BaseFieldView {
    lazy var checkboxSwitch: UISwitch = {
        let checkboxSwitch = UISwitch(forAutoLayout: ());
        checkboxSwitch.accessibilityLabel = field[FieldKey.name.key] as? String ?? "";
        checkboxSwitch.isOn = value as? Bool ?? false;
        checkboxSwitch.addTarget(self, action: #selector(switchValueChanged(theSwitch:)), for: .valueChanged)
        return checkboxSwitch;
    }()

    lazy var label: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.textColor = .label;
        label.text = field[FieldKey.title.key] as? String ?? "";
        if ((field[FieldKey.required.key] as? Bool) == true) {
            label.text = (label.text ?? "") + " *"
        }
        return label;
    }()
    
    lazy var errorLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.textColor = globalErrorContainerScheme().colorScheme.primaryColor;
        label.text = "";
        label.autoSetDimension(.height, toSize: 14.5);
        return label;
    }()
    
    lazy var containerView: UIView = {
        let containerView: UIView = UIView(forAutoLayout: ());
        containerView.addSubview(checkboxSwitch);
        containerView.addSubview(label);
        checkboxSwitch.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .right);
        label.autoPinEdge(.leading, to: .trailing, of: checkboxSwitch, withOffset: 16);
        label.autoPinEdge(toSuperviewEdge: .trailing);
        label.autoAlignAxis(.horizontal, toSameAxisOf: checkboxSwitch);
        return containerView;
    }()
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        label.font = scheme.typographyScheme.body1;
        label.textColor = scheme.colorScheme.onSurfaceColor;
        errorLabel.font = scheme.typographyScheme.caption;
        checkboxSwitch.onTintColor = scheme.colorScheme.primaryColorVariant;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: false);
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: Bool) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        self.addFieldView();
    }
    
    func addFieldView() {
        if (editMode) {
            viewStack.addArrangedSubview(containerView);
            viewStack.addArrangedSubview(errorLabel);
            viewStack.setCustomSpacing(3.5, after: containerView);
        } else {
            viewStack.addArrangedSubview(fieldNameLabel);
            viewStack.addArrangedSubview(checkboxSwitch);
            checkboxSwitch.isUserInteractionEnabled = false;
        }
    }
    
    override func setValue(_ value: Any?) {
        if let boolValue = value as? Bool {
            setValue(boolValue);
        }
    }
    
    func setValue(_ value: Bool = false) {
        self.value = value;
        checkboxSwitch.isOn = value;
    }
    
    @objc func switchValueChanged(theSwitch: UISwitch) {
        delegate?.fieldValueChanged(field, value: theSwitch.isOn);
    }
    
    override func setValid(_ valid: Bool) {
        valid ? (errorLabel.text = "") : (errorLabel.text = getErrorMessage());
        if let safeScheme = scheme {
            if (valid) {
                applyTheme(withScheme: safeScheme);
            } else {
                label.textColor = safeScheme.colorScheme.errorColor;
            }
        }
    }
    
    override func isEmpty() -> Bool {
        return !(self.value as? Bool ?? false);
    }
    
    override func getErrorMessage() -> String {
        return "\(field[FieldKey.title.key] as? String ?? "") is required";
    }
}

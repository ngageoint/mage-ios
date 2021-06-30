//
//  RadioFieldView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class RadioFieldView: BaseFieldView {
    
    var choiceButtons: [String: (button: MDCButton, label: UILabel)] = [:];
    
    lazy var errorLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.textColor = globalErrorContainerScheme().colorScheme.primaryColor;
        label.text = "";
        label.autoSetDimension(.height, toSize: 14.5);
        return label;
    }()

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil) {
        self.init(field: field, editMode: editMode, delegate: delegate, value: nil);
    }
    
    init(field: [String: Any], editMode: Bool = true, delegate: (ObservationFormFieldListener & FieldSelectionDelegate)? = nil, value: String?) {
        super.init(field: field, delegate: delegate, value: value, editMode: editMode);
        self.addFieldView();
        setValue(value);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            if (editMode) {
                for value in choiceButtons.values {
                    value.button.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4), excludingEdge: .right);
                    value.button.autoSetDimensions(to: CGSize(width: 30, height: 30))
                    value.label.autoPinEdge(toSuperviewEdge: .right);
                    value.label.autoAlignAxis(.horizontal, toSameAxisOf: value.button);
                    value.label.autoPinEdge(.left, to: .right, of: value.button, withOffset: 8);
                }
            } else {
                
            }
        }
        super.updateConstraints();
    }
    
    func addFieldView() {
        if (editMode) {
            viewStack.spacing = 0;
            viewStack.addArrangedSubview(fieldNameLabel);
            addChoices();
            viewStack.addArrangedSubview(errorLabel);
            viewStack.setCustomSpacing(8, after: fieldNameLabel);
        } else {
            viewStack.addArrangedSubview(fieldNameLabel);
            viewStack.addArrangedSubview(fieldValue);
            fieldValue.text = getDisplayValue();
        }
    }
    
    func addChoices() {
        guard let choices = field[FieldKey.choices.key] as? [[String: AnyHashable]] else { return }
        for choice in choices {
            let view = UIView(forAutoLayout: ());
            let button = MDCButton(forAutoLayout: ());
            button.setImage(UIImage(named: "radio_button_unchecked")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
            button.setImage(UIImage(named: "radio_button_checked")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .selected);
            button.addTarget(self, action: #selector(handleRadioTap(_:)), for: .touchUpInside);
            
            view.addSubview(button);
            let label = UILabel(forAutoLayout: ());
            label.text = choice[FieldKey.title.key] as? String;
            view.addSubview(label);
            
            button.accessibilityLabel = "\(field[FieldKey.name.key] as? String ?? "") \(label.text ?? "") radio";
            choiceButtons[label.text ?? ""] = (button:button, label:label);
            
            button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
            button.inkMaxRippleRadius = 30;
            button.inkStyle = .unbounded;
            viewStack.addArrangedSubview(view);
        }
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super.applyTheme(withScheme: scheme);
        for value in choiceButtons.values {
            value.button.applyTextTheme(withScheme: scheme);
            value.button.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
            value.button.setImageTintColor(scheme.colorScheme.primaryColor, for: .selected)
            value.label.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
        }
    }
    
    @objc func handleRadioTap(_ button: MDCButton) {
        for cb in choiceButtons {
            if (cb.value.button == button) {
                value = cb.key;
                cb.value.button.isSelected = true;
            } else {
                cb.value.button.isSelected = false;
            }
        }
    }
    
    override func setValue(_ value: Any?) {
        self.value = value
        if (editMode) {
            for cb in choiceButtons {
                if (cb.key == value as? String) {
                    cb.value.button.isSelected = true;
                } else {
                    cb.value.button.isSelected = false;
                }
            }
        } else {
            fieldValue.text = getDisplayValue();
        }
    }
    
    func getDisplayValue() -> String? {
        return getValue();
    }
    
    func getValue() -> String? {
        return value as? String;
    }
    
    override func setValid(_ valid: Bool) {
        valid ? (errorLabel.text = "") : (errorLabel.text = getErrorMessage());
        if let safeScheme = scheme {
            if (valid) {
                applyTheme(withScheme: safeScheme);
            } else {
                errorLabel.textColor = safeScheme.colorScheme.errorColor;
            }
        }
    }
    
    override func getErrorMessage() -> String {
        return "\(field[FieldKey.title.key] as? String ?? "") is required";
    }
    
    override func isEmpty() -> Bool {
        return self.value == nil;
    }
}

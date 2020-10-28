//
//  EditCheckboxFieldView.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/28/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCTextField

class EditCheckboxFieldView : BaseFieldView {
    lazy var checkboxSwitch: UISwitch = {
        let checkboxSwitch = UISwitch(forAutoLayout: ());
        checkboxSwitch.isOn = value as? Bool ?? false;
        checkboxSwitch.addTarget(self, action: #selector(switchValueChanged(theSwitch:)), for: .valueChanged)
        return checkboxSwitch;
    }()

    lazy var label: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.textColor = .label;
        label.font = globalContainerScheme().typographyScheme.body1;
        label.text = field[FieldKey.title.key] as? String ?? "";
        if ((field[FieldKey.required.key] as? Bool) == true) {
            label.text = (label.text ?? "") + " *"
        }
        return label;
    }()
    
    lazy var errorLabel: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.textColor = globalErrorContainerScheme().colorScheme.primaryColor;
        label.font = globalContainerScheme().typographyScheme.caption;
        label.text = "\(field[FieldKey.title.key] as? String ?? "") is required";
        label.isHidden = true;
        return label;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    convenience init(field: [String: Any], delegate: ObservationEditListener? = nil) {
        self.init(field: field, delegate: delegate, value: false);
    }
    
    init(field: [String: Any], delegate: ObservationEditListener? = nil, value: Bool) {
        super.init(field: field, delegate: delegate, value: value);
        self.addFieldView();
    }
    
    func addFieldView() {
        self.addSubview(checkboxSwitch);
        self.addSubview(label);
        checkboxSwitch.autoPinEdge(toSuperviewEdge: .left);
        checkboxSwitch.autoPinEdge(toSuperviewEdge: .top);
        label.autoPinEdge(.leading, to: .trailing, of: checkboxSwitch, withOffset: 16);
        label.autoPinEdge(toSuperviewEdge: .trailing);
        label.autoAlignAxis(.horizontal, toSameAxisOf: checkboxSwitch);
        self.addSubview(errorLabel);
        errorLabel.autoPinEdge(.top, to: .bottom, of: checkboxSwitch, withOffset: 4);
        errorLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top);
    }
    
    func setValue(_ value: Bool = false) {
        self.value = value;
        checkboxSwitch.isOn = value;
    }
    
    @objc func switchValueChanged(theSwitch: UISwitch) {
        delegate?.observationField(field, valueChangedTo: theSwitch.isOn, reloadCell: false);
    }
    
    override func setValid(_ valid: Bool) {
        errorLabel.isHidden = valid;
        if (valid) {
            label.textColor = .label;
        } else {
            label.textColor = .systemRed;
        }
    }
    
    override func isEmpty() -> Bool {
        return !(self.value as? Bool ?? false);
    }
}

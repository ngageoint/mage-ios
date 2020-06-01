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
        label.text = field[FieldKey.title.key] as? String ?? "";
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
        checkboxSwitch.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .trailing);
        label.autoPinEdge(.leading, to: .trailing, of: checkboxSwitch, withOffset: 16);
        label.autoPinEdge(toSuperviewEdge: .trailing);
        label.autoAlignAxis(.horizontal, toSameAxisOf: checkboxSwitch);
    }
    
    func setValue(_ value: Bool = false) {
        self.value = value;
        checkboxSwitch.isOn = value;
    }
    
    @objc func switchValueChanged(theSwitch: UISwitch) {
        delegate?.observationField(field, valueChangedTo: theSwitch.isOn, reloadCell: false);
    }
}

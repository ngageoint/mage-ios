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
    internal var editMode: Bool = true;
    
    private lazy var fieldSelectionCoordinator: FieldSelectionCoordinator? = {
        var fieldSelectionCoordinator: FieldSelectionCoordinator? = nil;
        if let safeDelegate: FieldSelectionDelegate = delegate {
            fieldSelectionCoordinator = FieldSelectionCoordinator(field: field, formField: self, delegate: safeDelegate);
        }
        return fieldSelectionCoordinator;
    }();
    
    lazy var fieldNameSpacerView: UIView = {
        let fieldNameSpacerView = UIView(forAutoLayout: ());
        fieldNameSpacerView.addSubview(fieldNameLabel);
        fieldNameLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
        return fieldNameSpacerView;
    }()
    
    lazy var fieldNameLabel: UILabel = {
        let containerScheme = globalContainerScheme();
        let label = UILabel(forAutoLayout: ());
        label.textColor = UIColor.label.withAlphaComponent(0.6);
        var font = containerScheme.typographyScheme.body1;
        font = font.withSize(font.pointSize * MDCTextInputControllerBase.floatingPlaceholderScaleDefault);
        label.font = font;
        label.autoSetDimension(.height, toSize: 16);
        label.text = (field[FieldKey.title.key] as? String ?? "");
        label.accessibilityLabel = "\((field[FieldKey.name.key] as? String ?? "")) Label";
        return label;
    }()
    
    lazy var fieldValue: UILabel = {
        let containerScheme = globalContainerScheme();
        let label = UILabel(forAutoLayout: ());
        label.textColor = .label;
        var font = containerScheme.typographyScheme.body1;
        label.font = font;
        label.numberOfLines = 0;
        return label;
    }()
    
    lazy var viewStack: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = false;
        stackView.translatesAutoresizingMaskIntoConstraints = true;
        return stackView;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(field: [String: Any], delegate: (ObservationFormFieldListener & FieldSelectionDelegate)?, value: Any?, editMode: Bool = true) {
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.editMode = editMode;
        self.field = field;
        self.delegate = delegate;
        self.value = value;
        self.addSubview(viewStack);
        viewStack.autoPinEdgesToSuperviewEdges();
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
    
    func getErrorMessage() -> String {
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
        if (valid) {
            controller.setErrorText(nil, errorAccessibilityValue: nil);
        } else {
            controller.setErrorText(getErrorMessage(), errorAccessibilityValue: nil);
        }
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

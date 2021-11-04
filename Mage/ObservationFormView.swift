//
//  ObservationFormView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/5/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

import MaterialComponents.MaterialTextFields
import MaterialComponents.MaterialTextControls_OutlinedTextAreasTheming

@objc protocol ObservationFormFieldListener {
    @objc func fieldValueChanged(_ field: [String : Any], value: Any?);
}

class ObservationFormView: UIStackView {
    
    var observation: Observation!;
    public weak var containingCard: ExpandableCard?;
    private var eventForm: [String:Any]?;
    private var form: [String: Any]!;
    private var formIndex: Int!;
    private var fieldViews: [String: BaseFieldView] = [ : ];
    private weak var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    private var attachmentCreationCoordinator: AttachmentCreationCoordinator?;
    private weak var viewController: UIViewController!;
    private weak var fieldSelectionDelegate: FieldSelectionDelegate?;
    private weak var observationFormListener: ObservationFormListener?;
    private weak var observationActionsDelegate: ObservationActionsDelegate?;
    private var editMode: Bool = true;
    private var formFieldAdded: Bool = false;
    private var includeAttachmentFields: Bool = true;
    private var scheme: MDCContainerScheming?;

    private lazy var formFields: [[String: Any]] = {
        let fields: [[String: Any]] = self.eventForm?[FormKey.fields.key] as? [[String: Any]] ?? [];
        
        return fields.filter { (field) -> Bool in
            let archived: Bool = field[FieldKey.archived.key] as? Bool ?? false;
            let hidden : Bool = field[FieldKey.hidden.key] as? Bool ?? false;
            let type : String = field[FieldKey.type.key] as? String ?? "";
            return !archived;
        }.sorted { (field0, field1) -> Bool in
            return (field0[FieldKey.id.key] as? Int ?? Int.max ) < (field1[FieldKey.id.key] as? Int ?? Int.max)
        }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.alignment = .fill;
        self.distribution = .equalSpacing;
        self.axis = .vertical;
        self.spacing = 12;
    }
    
    convenience init(observation: Observation, form: [String: Any], eventForm: [String:Any]? = nil, formIndex: Int, editMode: Bool = true, viewController: UIViewController, observationFormListener: ObservationFormListener? = nil, delegate: FieldSelectionDelegate? = nil, attachmentSelectionDelegate: AttachmentSelectionDelegate? = nil, observationActionsDelegate: ObservationActionsDelegate? = nil, includeAttachmentFields: Bool = true) {
        self.init(frame: .zero)
        self.observation = observation;
        self.form = form;
        self.eventForm = eventForm;
        self.editMode = editMode;
        self.viewController = viewController;
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        self.formIndex = formIndex;
        self.fieldSelectionDelegate = delegate;
        self.observationFormListener = observationFormListener;
        self.observationActionsDelegate = observationActionsDelegate;
        self.includeAttachmentFields = includeAttachmentFields;
        constructView();
        self.accessibilityLabel = "Form \(self.eventForm?[FormKey.id.key] ?? "")";
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview();
        self.viewController = nil;
        self.attachmentSelectionDelegate = nil;
        self.fieldViews = [:];
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
        if let attachmentCreationCoordinator = attachmentCreationCoordinator {
            attachmentCreationCoordinator.applyTheme(withContainerScheme: scheme);
        }
        for (_, fieldView) in self.fieldViews {
            fieldView.applyTheme(withScheme: scheme);
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func constructView() {
        formFieldAdded = false;
        for fieldDictionary in self.formFields {
            let type = fieldDictionary[FieldKey.type.key] as! String;
            var value = self.form?[fieldDictionary[FieldKey.name.key] as! String]
            
            // special case for attachments
            var unsentAttachments: [[String : AnyHashable]] = [];
            if (type == FieldType.attachment.key) {
                if (value != nil) {
                    unsentAttachments = value as? [[String : AnyHashable]] ?? []
                }
                value = (self.observation.attachments as? Set<Attachment>)?.filter() { (attachment: Attachment) in
                    guard let ofi = attachment.observationFormId, let fieldName = attachment.fieldName else { return false }
                    return ofi == form[FormKey.id.key] as? String && fieldName == fieldDictionary[FieldKey.name.key] as? String &&
                        !attachment.markedForDeletion;
                }
                if ((value as! Set<Attachment>).count == 0) {
                    value = nil;
                }
            } else if (!editMode && (value == nil || (value as? String) == "")) {
                continue;
            }
            
            var fieldView: UIView?;
            switch type {
            case FieldType.attachment.key:
                if (!includeAttachmentFields) {
                    continue;
                }
                if (!editMode && value == nil && unsentAttachments.filter {
                    return $0["action"] as? String != "delete";
                }.count == 0) {
                    continue;
                }
                attachmentCreationCoordinator = AttachmentCreationCoordinator(rootViewController: viewController, observation: observation, fieldName: fieldDictionary[FieldKey.name.key] as? String, observationFormId: form[FormKey.id.key] as? String, scheme: scheme);
                fieldView = AttachmentFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: (value as? Set<Attachment>), attachmentSelectionDelegate: attachmentSelectionDelegate, attachmentCreationCoordinator: attachmentCreationCoordinator);
                (fieldView as! AttachmentFieldView).setUnsentAttachments(attachments: unsentAttachments);
            case FieldType.numberfield.key:
                fieldView = NumberFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: (value as? NSNumber)?.stringValue );
            case FieldType.textfield.key:
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case FieldType.textarea.key:
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String, multiline: true);
            case FieldType.email.key:
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String, keyboardType: .emailAddress);
            case FieldType.password.key:
                fieldView = TextFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case FieldType.date.key:
                fieldView = DateView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case FieldType.checkbox.key:
                fieldView = CheckboxFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? Bool ?? false);
            case FieldType.dropdown.key:
                fieldView = DropdownFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case FieldType.multiselectdropdown.key:
                    fieldView = MultiDropdownFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? [String])
            case FieldType.radio.key:
                fieldView = RadioFieldView(field: fieldDictionary, editMode: editMode, delegate: self, value: value as? String);
            case FieldType.geometry.key:
                fieldView = GeometryView(field: fieldDictionary, editMode: editMode, delegate: self, observationActionsDelegate: observationActionsDelegate);
                (fieldView as! GeometryView).setValue(value as? SFGeometry)
            default:
                print("No view is configured for type \(type)")
            }
            if let baseFieldView = fieldView as? BaseFieldView, let key = fieldDictionary[FieldKey.name.key] as? String {
                baseFieldView.applyTheme(withScheme: scheme)
                fieldViews[key] = baseFieldView;
                formFieldAdded = true;
                self.addArrangedSubview(baseFieldView);
            }
        }
    }
    
    func fieldViewForField(field: [String: Any]) -> BaseFieldView? {
        if let key = field[FieldKey.name.key] as? String {
            return fieldViews[key]
        }
        return nil;
    }
    
    public func isEmpty() -> Bool {
        return !formFieldAdded;
    }
    
    public func checkValidity(enforceRequired: Bool = false) -> Bool {
        var valid = true;
        for (_, fieldView) in self.fieldViews {
            let formValid = fieldView.isValid(enforceRequired: enforceRequired);
            fieldView.setValid(formValid);
            valid = valid && formValid;
        }
        containingCard?.markValid(valid);
        return valid;
    }
}

extension ObservationFormView: FieldSelectionDelegate {
    func launchFieldSelectionViewController(viewController: UIViewController) {
        fieldSelectionDelegate?.launchFieldSelectionViewController(viewController: viewController);
    }
}

extension ObservationFormView: ObservationFormFieldListener {
    func fieldValueChanged(_ field: [String : Any], value: Any?) {
        var newProperties = self.observation.properties as? [String: Any];
        if (value == nil) {
            form.removeValue(forKey: field[FieldKey.name.key] as? String ?? "");
        } else {
            form[field[FieldKey.name.key] as? String ?? ""] = value;
        }
        var forms: [[String: Any]] = newProperties?[ObservationKey.forms.key] as! [[String: Any]];
        forms[0] = form;
        newProperties![ObservationKey.forms.key] = forms;
        self.observation.properties = newProperties;
        self.observationFormListener?.formUpdated(form, eventForm: eventForm!, form: formIndex);
    }
}

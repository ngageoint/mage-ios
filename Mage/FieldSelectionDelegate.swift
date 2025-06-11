//
//  FieldSelectionDelegate.swift
//  MAGE
//
//  Created by Daniel Barela on 12/3/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc protocol FieldSelectionDelegate {
    @objc func launchFieldSelectionViewController(viewController: UIViewController);
}

class FieldSelectionCoordinator {
    private let field: [String : Any];
    private weak var formField: BaseFieldView?;
    private weak var delegate: FieldSelectionDelegate?;
    private var currentEditValue: Any?;
    private var editSelect: SelectEditViewController?;
    private var geometryEdit: UIViewController?;
    private var geometryCoordinator: GeometryEditCoordinator!;
    private var scheme: AppContainerScheming?;
    
    public init(field: [String : Any], formField: BaseFieldView?, delegate: FieldSelectionDelegate?, scheme: AppContainerScheming?) {
        self.field = field;
        self.formField = formField;
        self.delegate = delegate;
        self.scheme = scheme;
    }
    
    func applyTheme(withScheme scheme: AppContainerScheming?) {
        self.scheme = scheme;
    }
    
    func fieldSelected() {
        if (field[FieldKey.type.key] as? String == FieldType.dropdown.key ||
                field[FieldKey.type.key] as? String == FieldType.radio.key ||
                field[FieldKey.type.key] as? String == FieldType.multiselectdropdown.key) {
            currentEditValue = formField?.value;
            editSelect = SelectEditViewController(fieldDefinition: field, andValue: formField?.value, andDelegate: self, scheme: self.scheme);
            editSelect?.title = field[FieldKey.title.key] as? String;
            if (field[FieldKey.type.key] as? String == FieldType.multiselectdropdown.key) {
                editSelect?.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply", style: .done, target: self, action: #selector(self.editDone));
            }
            editSelect?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.editCanceled));
            delegate?.launchFieldSelectionViewController(viewController: editSelect!);
        } else if (field[FieldKey.type.key] as? String == FieldType.geometry.key) {
            geometryCoordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: formField?.value as? SFGeometry, andPinImage: nil, andDelegate: self, andNavigationController: nil, scheme: self.scheme);
            geometryEdit = geometryCoordinator?.createViewController();
            delegate?.launchFieldSelectionViewController(viewController: geometryEdit!);
        }
    }
    
    @objc func editDone() {
        self.formField?.setValue(currentEditValue);
        self.formField?.delegate?.fieldValueChanged(field, value: currentEditValue);
        editSelect?.navigationController?.popViewController(animated: true);
        editSelect = nil;
    }
    
    @objc func editCanceled() {
        currentEditValue = nil;
        editSelect?.navigationController?.popViewController(animated: true);
        editSelect = nil;
    }
}

extension FieldSelectionCoordinator: PropertyEditDelegate {
    
    
    func setValue(_ value: Any!, forFieldDefinition fieldDefinition: [AnyHashable : Any]!) {
        self.currentEditValue = value;
        if (field[FieldKey.type.key] as? String != FieldType.multiselectdropdown.key) {
            self.editDone();
        }
    }
    
    func invalidValue(_ value: Any!, forFieldDefinition fieldDefinition: [AnyHashable : Any]!) {
        
    }
    
}

extension FieldSelectionCoordinator: GeometryEditDelegate {
    
    func geometryEditComplete(_ geometry: SFGeometry!, fieldDefintion field: [AnyHashable : Any]!, coordinator: Any!, wasValueChanged changed: Bool) {
        if (changed) {
            self.formField?.setValue(geometry);
            if (self.formField?.isValid() != nil) {
                self.formField?.delegate?.fieldValueChanged(self.field, value: geometry);
                geometryEdit?.navigationController?.popViewController(animated: true);
                geometryEdit = nil;
            }
        } else {
            geometryEdit?.navigationController?.popViewController(animated: true);
            geometryEdit = nil;
        }
    }
    
    func geometryEditCancel(_ coordinator: Any!) {
        geometryEdit?.navigationController?.popViewController(animated: true);
        geometryEdit = nil;
    }
}

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
    private let formField: BaseFieldView;
    private let delegate: FieldSelectionDelegate;
    private var currentEditValue: Any?;
    private var editSelect: SelectEditViewController!;
    private var geometryEdit: UIViewController!;
    private var geometryCoordinator: GeometryEditCoordinator!;
    
    public init(field: [String : Any], formField: BaseFieldView, delegate: FieldSelectionDelegate) {
        self.field = field;
        self.formField = formField;
        self.delegate = delegate;
    }
    
    func fieldSelected() {
        print("field selected in the coordinator \(field[FieldKey.type.key])")
        if (field[FieldKey.type.key] as? String == "dropdown" ||
            field[FieldKey.type.key] as? String == "radio" ||
            field[FieldKey.type.key] as? String == "multiselectdropdown") {
            editSelect = SelectEditViewController(fieldDefinition: field, andValue: formField.value, andDelegate: self);
            editSelect.title = field[FieldKey.title.key] as? String;
            editSelect.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.editDone));
            editSelect.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.editCanceled));
            delegate.launchFieldSelectionViewController(viewController: editSelect);
        } else if (field[FieldKey.type.key] as? String == "geometry") {
            geometryCoordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: formField.value as? SFGeometry, andPinImage: nil, andDelegate: self, andNavigationController: nil);
            geometryEdit = geometryCoordinator?.createViewController();
            delegate.launchFieldSelectionViewController(viewController: geometryEdit);
        }
        
        //        self.currentEditField = field;
        //        NSArray *obsForms = [self.observation.properties objectForKey:@"forms"];
        //        NSNumber *formIndex = [field valueForKey:@"formIndex"];
        //        id name = [field valueForKey:@"name"];
        //        id value = self.currentEditValue = formIndex ? [[obsForms objectAtIndex:[formIndex integerValue]] objectForKey:name] : nil;
        //        if ([[field objectForKey:@"type"] isEqualToString:@"dropdown"] || [[field objectForKey:@"type"] isEqualToString:@"multiselectdropdown"] || [[field objectForKey:@"type"] isEqualToString:@"radio"]) {
        //            SelectEditViewController *editSelect = [[SelectEditViewController alloc] initWithFieldDefinition:field andValue: value andDelegate: self];
        //            editSelect.title = [field valueForKey:@"title"];
        //            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(fieldEditCanceled)];
        //            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(fieldEditDone)];
        //            [editSelect.navigationItem setLeftBarButtonItem:backButton];
        //            [editSelect.navigationItem setRightBarButtonItem:doneButton];
        //            [self.navigationController pushViewController:editSelect animated:YES];
        //        } else if ([[field objectForKey:@"type"] isEqualToString:@"geometry"]) {
        //            if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        //                SFGeometry *geometry = [self.observation getGeometry];
        //                GeometryEditCoordinator *editCoordinator = [[GeometryEditCoordinator alloc] initWithFieldDefinition:field andGeometry: geometry andPinImage:[ObservationImage imageForObservation:self.observation] andDelegate:self andNavigationController:self.navigationController];
        //                [self.childCoordinators addObject:editCoordinator];
        //                [editCoordinator start];
        //            } else {
        //                GeometryEditCoordinator *editCoordinator = [[GeometryEditCoordinator alloc] initWithFieldDefinition:field andGeometry: value andPinImage:nil andDelegate:self andNavigationController:self.navigationController];
        //                [self.childCoordinators addObject:editCoordinator];
        //                [editCoordinator start];
        //            }
        //        }
    }
    
    @objc func editDone() {
        print("edit done current value \(currentEditValue)")
        self.formField.setValue(currentEditValue!);
        // if this comes back without an error, dismiss
        if (self.formField.isValid()) {
            self.formField.delegate?.fieldValueChanged(field, value: currentEditValue);
            editSelect?.navigationController?.popViewController(animated: true);
        }
    }
    
    @objc func editCanceled() {
        currentEditValue = nil;
        editSelect?.navigationController?.popViewController(animated: true);
    }
}

extension FieldSelectionCoordinator: PropertyEditDelegate {
    
    
    func setValue(_ value: Any!, forFieldDefinition fieldDefinition: [AnyHashable : Any]!) {
        self.currentEditValue = value;
    }
    
    func invalidValue(_ value: Any!, forFieldDefinition fieldDefinition: [AnyHashable : Any]!) {
        
    }
    
}

extension FieldSelectionCoordinator: GeometryEditDelegate {
    func geometryEditComplete(_ geometry: SFGeometry!, fieldDefintion field: [AnyHashable : Any]!, coordinator: Any!) {
        let point: SFPoint = geometry as! SFPoint;
        print("Field selection delegate latitude \(point.y) ");
        self.formField.setValue(geometry);
        if (self.formField.isValid()) {
            self.formField.delegate?.fieldValueChanged(self.field, value: geometry);
            geometryEdit.navigationController?.popViewController(animated: true);
        }
    }
    
    func geometryEditCancel(_ coordinator: Any!) {
        
    }
}

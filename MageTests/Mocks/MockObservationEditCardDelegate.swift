//
//  MockObservationDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/5/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class MockObservationEditCardDelegate: ObservationEditCardDelegate, FieldSelectionDelegate, ObservationEditListener {
    func reorderForms(observation: Observation) {
        
    }
    
    func fieldValueChanged(_ field: [String : Any], value: Any?) {
        
    }
    
    func launchFieldSelectionViewController(viewController: UIViewController) {
        
    }
    
    var addVoiceAttachmentCalled = false;
    var addVideoAttachmentCalled = false;
    var addCameraAttachmentCalled = false;
    var addGalleryAttachmentCalled = false;
    var deleteObservationCalled = false;
    var fieldSelectedCalled = false;
    var attachmentSelectedCalled = false;
    var addFormCalled = false;
    var saveObservationCalled = false;
    var cancelEditCalled = false;
    
    var selectedAttachment: Attachment?;
    var selectedField: [String : Any]?;
    var selectedFieldCurrentValue: Any?;
    var observationSaved: Observation?;
    
    func addVoiceAttachment() {
        addVoiceAttachmentCalled = true;
    }
    
    func addVideoAttachment() {
        addVideoAttachmentCalled = true;
    }
    
    func addCameraAttachment() {
        addCameraAttachmentCalled = true;
    }
    
    func addGalleryAttachment() {
        addGalleryAttachmentCalled = true;
    }
    
    func deleteObservation() {
        deleteObservationCalled = true;
    }
    
    func fieldSelected(field: [String : Any], currentValue: Any?) {
        fieldSelectedCalled = true;
        selectedField = field;
    }
    
    func attachmentSelected(attachment: Attachment) {
        attachmentSelectedCalled = true;
        selectedAttachment = attachment;
    }
    
    func addForm() {
        addFormCalled = true;
    }
    
    func saveObservation(observation: Observation) {
        saveObservationCalled = true;
        observationSaved = observation;
    }
    
    func cancelEdit() {
        cancelEditCalled = true;
    }
}

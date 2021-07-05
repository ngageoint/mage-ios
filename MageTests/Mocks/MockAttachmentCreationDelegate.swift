//
//  MockAttachmentCreationDelegate.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/5/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@testable import MAGE

class MockAttachmentCreationDelegate: AttachmentCreationDelegate {
    var addVoiceAttachmentCalled = false;
    var addVideoAttachmentCalled = false;
    var addCameraAttachmentCalled = false;
    var addGalleryAttachmentCalled = false;
    
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
}

class MockAttachmentCreationCoordinator: AttachmentCreationCoordinator {
    var addVoiceAttachmentCalled = false;
    var addVideoAttachmentCalled = false;
    var addCameraAttachmentCalled = false;
    var addGalleryAttachmentCalled = false;
    
    override func addVoiceAttachment() {
        addVoiceAttachmentCalled = true;
    }
    
    override func addVideoAttachment() {
        addVideoAttachmentCalled = true;
    }
    
    override func addCameraAttachment() {
        addCameraAttachmentCalled = true;
    }
    
    override func addGalleryAttachment() {
        addGalleryAttachmentCalled = true;
    }
}

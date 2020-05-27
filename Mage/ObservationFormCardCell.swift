//
//  ObservationFormCardCell.swift
//  MAGE
//
//  Created by Daniel Barela on 5/4/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

import Foundation

import UIKit
import MaterialComponents.MaterialTypographyScheme
import MaterialComponents.MaterialCards
import PureLayout

class ObservationFormCardCell: MDCCardCollectionCell, ObservationEditViewControllerDelegate {
    func addVoiceAttachment() {
        
    }
    
    func addVideoAttachment() {
        
    }
    
    func addCameraAttachment() {
        
    }
    
    func addGalleryAttachment() {
        
    }
    
    func deleteObservation() {
        
    }
    
    func fieldSelected(_ field: [AnyHashable : Any]!) {
        
    }
    
    func attachmentSelected(_ attachment: Attachment!) {
        
    }
    
    func addForm() {
        
    }
    
    
    private var editController: ObservationEditViewController?;
    private var formIndex: Int?;
    
    private lazy var card: ExpandableCard = {
        let card = ExpandableCard(frame: CGRect.zero);
        card.translatesAutoresizingMaskIntoConstraints = false
        card.set(container: self.contentView);
        return card;
    }()

    func configure(observationForm: NSDictionary, eventForm: NSDictionary, width: CGFloat, observation: Observation, formIndex: Int) {
        self.formIndex = formIndex;
        var formPrimaryValue = "";
        var formSecondaryValue = "";
        if let primaryField = eventForm.object(forKey: "primaryFeedField") as! NSString? {
            if let obsfield = observationForm.object(forKey: primaryField) as! String? {
                formPrimaryValue = obsfield;
            }
        }
        if let secondaryField = eventForm.object(forKey: "secondaryFeedField") as! NSString? {
            if let obsfield = observationForm.object(forKey: secondaryField) as! String? {
                formSecondaryValue = obsfield;
            }
        }
        
        NSLog("FORM %@", observationForm);
        NSLog("EVENT FORM %@", eventForm);
//        NSLog("Event form primary key %@", formPrimaryValue);
//        NSLog("Event form secondary key %@", secondaryField);
        
        card.setWidth(width: width);
        let formView = ObservationFormView(observation: observation, form: observationForm, eventForm: eventForm as! [String : Any], formIndex: formIndex);
        
        card.configure(header: formPrimaryValue, subheader: formSecondaryValue, imageName: "form", expandedView: formView, cell: self);
    }

    func apply(containerScheme: MDCContainerScheming, typographyScheme: MDCTypographyScheming) {
        card.apply(containerScheme: containerScheme, typographyScheme: typographyScheme);
    }
    
    func somethingChanged() {
        self.setNeedsLayout();
        let cv = (self.superview as! UICollectionView);
        cv.reloadData();
    }
    
    private var container: UIView?;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.translatesAutoresizingMaskIntoConstraints = false;
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.translatesAutoresizingMaskIntoConstraints = false;
    }
}

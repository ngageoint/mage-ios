//
//  ObservationEditCardCollection.swift
//  MAGE
//
//  Created by Daniel Barela on 5/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialCollections
import MaterialComponents.MDCCard

import MaterialComponents.MaterialColorScheme
import MaterialComponents.MaterialContainerScheme
import MaterialComponents.MaterialTypographyScheme

@objc protocol ObservationEditCardDelegate {
    @objc func addVoiceAttachment();
    @objc func addVideoAttachment();
    @objc func addCameraAttachment();
    @objc func addGalleryAttachment();
    @objc func deleteObservation();
    @objc func fieldSelected(field: NSDictionary);
    @objc func attachmentSelected(attachment: Attachment);
    @objc func addForm();
}

@objc class ObservationEditCardCollectionViewController: UIViewController { //}: MDCCollectionViewController {
    
    override func themeDidChange(_ theme: MageTheme) {
        self.navigationController?.navigationBar.isTranslucent = false;
        self.navigationController?.navigationBar.barTintColor = .primary();
        self.navigationController?.navigationBar.tintColor = .white;
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        self.view.backgroundColor = .tableBackground();
    }
    
    var delegate: ObservationEditCardDelegate?;
    var observation: Observation?;
    var newObservation: Bool?;
    
    private lazy var eventForms: NSArray = {
        let eventForms = Event.getById(self.observation?.eventId as Any, in: (self.observation?.managedObjectContext)!).forms as! NSArray;
        return eventForms;
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        return scrollView;
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = true;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        return stackView;
    }()
    
    private func addStackViewConstraints() {
        NSLayoutConstraint.activate([
            // Attaching the content's edges to the scroll view's edges
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            // Satisfying size constraints
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func addScrollViewConstraints() {
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(scrollView)
        addScrollViewConstraints();
        scrollView.addSubview(stackView)
        addStackViewConstraints();
        
        addFormViews(stackView: stackView);
        self.registerForThemeChanges();
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc convenience public init(delegate: ObservationEditCardDelegate, observation: Observation, newObservation: Bool) {
        self.init(frame: CGRect.zero);
        self.delegate = delegate;
        self.observation = observation;
        self.newObservation = newObservation;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func addFormViews(stackView: UIStackView) {
      
        let forms: NSArray = ((self.observation?.properties as! NSDictionary).object(forKey: "forms") as! NSArray);

        for (index, form) in forms.enumerated() {
            let observationForm = form as! NSDictionary;
            let predicate: NSPredicate = NSPredicate(format: "SELF.id = %@", argumentArray: [observationForm.object(forKey: "formId")!]);
            let eventForm: NSDictionary = self.eventForms.filtered(using: predicate).first as! NSDictionary;
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
            let formView = ObservationFormView(observation: self.observation!, form: observationForm, eventForm: eventForm as! [String: Any], formIndex: index);
            let card = ExpandableCard(forAutoLayout: ());
            card.configure(header: formPrimaryValue, subheader: formSecondaryValue, imageName: "form", expandedView: formView, cell: nil);
            stackView.addArrangedSubview(card);
        }
    }
}

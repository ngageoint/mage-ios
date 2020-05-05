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
import UIKit

import MaterialComponents.MaterialColorScheme
import MaterialComponents.MaterialContainerScheme
import MaterialComponents.MaterialTypographyScheme

//@protocol ObservationEditViewControllerDelegate
//
//- (void) addVoiceAttachment;
//- (void) addVideoAttachment;
//- (void) addCameraAttachment;
//- (void) addGalleryAttachment;
//- (void) deleteObservation;
//- (void) fieldSelected: (NSDictionary *) field;
//- (void) attachmentSelected: (Attachment *) attachment;
//- (void) addForm;
//
//@end

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

@objc class ObservationEditCardCollectionViewController: MDCCollectionViewController {
    
    var delegate: ObservationEditCardDelegate?;
    var observation: Observation?;
    var newObservation: Bool?;
    
    @objc public func setDelegate(delegate: ObservationEditCardDelegate, observation: Observation, newObservation: Bool) {
        self.delegate = delegate;
        self.observation = observation;
        self.newObservation = newObservation;
    }
    
    private lazy var eventForms: NSArray = {
        let eventForms = Event.getById(self.observation?.eventId, in: (self.observation?.managedObjectContext)!).forms as! NSArray;
        return eventForms;
    }()
    

    enum ToggleMode: Int {
        case edit = 1, reorder
    }

    var toggle = ToggleMode.edit

    @objc var containerScheme: MDCContainerScheming = MDCContainerScheme()

    let images = [
        (image: "amsterdam-kadoelen",     title: "Kadoelen"),
        (image: "amsterdam-zeeburg",      title: "Zeeburg"),
        (image: "venice-st-marks-square", title: "St. Mark's Square"),
        (image: "venice-grand-canal",     title: "Grand Canal"),
        (image: "austin-u-texas-pond",    title: "Austin U"),
    ]
    var dataSource: [(image: String, title: String, selected: Bool)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.frame = view.bounds
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = containerScheme.colorScheme.backgroundColor
        collectionView.alwaysBounceVertical = true
        collectionView.register(ObservationFormCardCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.allowsMultipleSelection = true
        
        if (collectionView.collectionViewLayout.isKind(of: UICollectionViewFlowLayout.self)) {
            (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).estimatedItemSize = UICollectionViewFlowLayout.automaticSize;
        }
        
        view.addSubview(collectionView)

        let count = Int(images.count)
        for index in 0 ..< 30 {
            let ind = index % count
            dataSource.append((image: images[ind].image, title: images[ind].title, selected: false))
        }

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            collectionView.leftAnchor.constraint(equalTo: guide.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: guide.rightAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: guide.bottomAnchor)])
        collectionView.contentInsetAdjustmentBehavior = .always

    }
}

// Collection View methods
extension ObservationEditCardCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        guard let cardCell = cell as? ObservationFormCardCell else { return cell }
        cardCell.apply(containerScheme: containerScheme,
                       typographyScheme: containerScheme.typographyScheme)
        
        let form: NSDictionary = ((self.observation?.properties as! NSDictionary).object(forKey: "forms") as! NSArray).object(at: indexPath.section) as! NSDictionary;
        let predicate: NSPredicate = NSPredicate(format: "SELF.id = %@", argumentArray: [form.object(forKey: "formId")]);
        let eventForm: NSDictionary = self.eventForms.filtered(using: predicate).first as! NSDictionary;
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.id = %@", [observationForm objectForKey:@"formId"]];
//        NSDictionary *eventForm = [[self.eventForms filteredArrayUsingPredicate:predicate] firstObject];
        
        cardCell.configure(observationForm: form, eventForm: eventForm, width: self.cellWidth(atSectionIndex: indexPath.section));

        cardCell.isSelectable = (toggle == .edit)
        if self.dataSource[indexPath.item].selected {
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            cardCell.isSelected = true
        }

        cardCell.isAccessibilityElement = true
        cardCell.accessibilityLabel = title

        return cardCell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard toggle == .edit else { return }
        dataSource[indexPath.item].selected = true
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard toggle == .edit else { return }
        dataSource[indexPath.item].selected = false
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        let formCount = ((self.observation?.properties as! NSDictionary).object(forKey: "forms") as! NSArray).count;
        return formCount;
    }

    override func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return 1;
    }
    
    override func cellWidth(atSectionIndex section: Int) -> CGFloat {
        return self.collectionView.bounds.size.width - 16;
    }

    override func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }

    override func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    override func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    override func collectionView(_ collectionView: UICollectionView,
                        canMoveItemAt indexPath: IndexPath) -> Bool {
        return toggle == .reorder
    }

    override func collectionView(_ collectionView: UICollectionView,
                        moveItemAt sourceIndexPath: IndexPath,
                        to destinationIndexPath: IndexPath) {
        let sourceItem = dataSource[sourceIndexPath.item]

        // reorder all cells in between source and destination, moving each by 1 position
        if sourceIndexPath.item < destinationIndexPath.item {
            for ind in sourceIndexPath.item ..< destinationIndexPath.item {
                dataSource[ind] = dataSource[ind + 1]
            }
        } else {
            for ind in (destinationIndexPath.item + 1 ... sourceIndexPath.item).reversed() {
                dataSource[ind] = dataSource[ind - 1]
            }
        }

        dataSource[destinationIndexPath.item] = sourceItem
    }

    @available(iOS 9.0, *)
    @objc func reorderCards(gesture: UILongPressGestureRecognizer) {

        switch(gesture.state) {
        case .began:
            guard let selectedIndexPath = collectionView.indexPathForItem(at:
                gesture.location(in: collectionView)) else { break }
            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            guard let gestureView = gesture.view else { break }
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gestureView))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }

}

extension ObservationEditCardCollectionViewController {

    @objc class func catalogMetadata() -> [String: Any] {
        return [
            "breadcrumbs": ["Cards", "Edit/Reorder"],
            "primaryDemo": false,
            "presentable": true,
        ]
    }
}

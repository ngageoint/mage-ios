//
//  ObservationViewCardCollectionViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 12/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import UIKit
import MaterialComponents.MaterialCollections
import MaterialComponents.MDCCard


@objc class ObservationViewCardCollectionViewController: UIViewController {
    
    var didSetupConstraints = false;
    
    override func themeDidChange(_ theme: MageTheme) {
        self.navigationController?.navigationBar.isTranslucent = false;
        self.navigationController?.navigationBar.barTintColor = globalContainerScheme().colorScheme.primaryColor;
        self.navigationController?.navigationBar.tintColor = .white;
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        self.view.backgroundColor = .tableBackground();
    }
    
    var observation: Observation?;
    var observationForms: [[String: Any]] = [];
    var cards: [ExpandableCard] = [];
    var attachmentViewCoordinator: AttachmentViewCoordinator?;
    var headerCard: ObservationHeaderView!;
    
    private lazy var eventForms: [[String: Any]] = {
        let eventForms = Event.getById(self.observation?.eventId as Any, in: (self.observation?.managedObjectContext)!).forms as? [[String: Any]] ?? [];
        return eventForms;
    }()
    
    private lazy var scrollView: UIScrollView = {
        return UIScrollView.newAutoLayout();
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView.newAutoLayout();
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = true;
        return stackView;
    }()
    
    private lazy var syncStatusView: ObservationSyncStatus = {
        let syncStatusView = ObservationSyncStatus(observation: observation);
        return syncStatusView;
    }()
    
    override func loadView() {
        view = UIView();
        
        view.addSubview(scrollView);
        view.addSubview(syncStatusView);
        scrollView.addSubview(stackView);
        
        view.setNeedsUpdateConstraints();
    }
    
    override func updateViewConstraints() {
        if (!didSetupConstraints) {
            syncStatusView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
            if (syncStatusView.isHidden) {
                scrollView.autoPinEdgesToSuperviewEdges(with: .zero);
            } else {
                scrollView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
                scrollView.autoPinEdge(.top, to: .bottom, of: syncStatusView);
            }
            stackView.autoPinEdgesToSuperviewEdges();
            stackView.autoMatch(.width, to: .width, of: view);
            didSetupConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.accessibilityIdentifier = "ObservationViewCardCollection"
        self.view.accessibilityLabel = "ObservationViewCardCollection"

        self.registerForThemeChanges();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.title = observation?.primaryFeedFieldText();
        ObservationPushService.singleton()?.add(self);
        for v in stackView.arrangedSubviews {
            v.removeFromSuperview();
        }
        addHeaderCard(stackView: stackView);
        addLegacyAttachmentCard(stackView: stackView);
        addFormViews(stackView: stackView);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        ObservationPushService.singleton()?.remove(self);
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc convenience public init(observation: Observation) {
        self.init(frame: CGRect.zero);
//        self.delegate = delegate;
        self.observation = observation;
        if let safeProperties = self.observation?.properties as? [String: Any] {
            if (safeProperties.keys.contains("forms")) {
                observationForms = safeProperties["forms"] as! [[String: Any]];
            }
        } else {
            observationForms = [];
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    func setupEditButton() {
        let user = User.fetchCurrentUser(in: NSManagedObjectContext.mr_default());
        if (user.hasEditPermission()) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.editObservation(sender:)));
        }
    }
    
    func addHeaderCard(stackView: UIStackView) {
        if let safeObservation = observation {
            headerCard = ObservationHeaderView(observation: safeObservation, observationActionsDelegate: self);
            stackView.addArrangedSubview(headerCard);
        }
    }
    
    // for legacy servers add the attachment field to common
    // TODO: Verify the correct version of the server and this can be removed once all servers are upgraded
    func addLegacyAttachmentCard(stackView: UIStackView) {
        if (UserDefaults.standard.serverMajorVersion < 6) {
            if let safeObservation = observation {
                if (safeObservation.attachments?.count != 0) {
                    let attachmentCard: ObservationAttachmentCard = ObservationAttachmentCard(observation: safeObservation, attachmentSelectionDelegate: self, viewController: self);
                    stackView.addArrangedSubview(attachmentCard);
                }
            }
        }
    }
    
    func addFormViews(stackView: UIStackView) {
        for (index, form) in self.observationForms.enumerated() {
            let card: ExpandableCard = addObservationFormView(observationForm: form, index: index);
            card.expanded = index == 0;
        }
    }
    
    func addObservationFormView(observationForm: [String: Any], index: Int) -> ExpandableCard {
        let eventForm: [String: Any]? = self.eventForms.first { (form) -> Bool in
            return form["id"] as? Int == observationForm["formId"] as? Int
        }
        
        var formPrimaryValue: String? = nil;
        var formSecondaryValue: String? = nil;
        if let primaryField = eventForm?["primaryField"] as! String? {
            if let obsfield = observationForm[primaryField] as! String? {
                formPrimaryValue = obsfield;
            }
        }
        if let secondaryField = eventForm?["variantField"] as! String? {
            if let obsfield = observationForm[secondaryField] as! String? {
                formSecondaryValue = obsfield;
            }
        }
        let formView = ObservationFormView(observation: self.observation!, form: observationForm, eventForm: eventForm, formIndex: index, editMode: false, viewController: self, observationFormListener: self, attachmentSelectionDelegate: self);
        var formSpacerView: UIView?;
        if (!formView.isEmpty()) {
            formSpacerView = UIView(forAutoLayout: ());
            formSpacerView?.addSubview(formView);
            formView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16));
        }
        
        let card = ExpandableCard(header: formPrimaryValue, subheader: formSecondaryValue, imageName: "form", title: eventForm?["name"] as? String, expandedView: formSpacerView)
        stackView.addArrangedSubview(card);
        cards.append(card);
        return card;
    }
    
    @objc func editObservation(sender: UIBarButtonItem) {
        
    }
}

extension ObservationViewCardCollectionViewController: ObservationFormListener {
    func formUpdated(_ form: [String : Any], eventForm: [String : Any], form index: Int) {
//        observationForms[index] = form
//        observationProperties["forms"] = observationForms;
//        observation?.properties = observationProperties;
//        setExpandableCardHeaderInformation(form: form, index: index);
    }
}

extension ObservationViewCardCollectionViewController: AttachmentSelectionDelegate {
    func selectedAttachment(_ attachment: Attachment!) {
        attachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: self.navigationController!, attachment: attachment, delegate: self);
        attachmentViewCoordinator?.start();
    }
}

extension ObservationViewCardCollectionViewController: AttachmentViewDelegate {
    func doneViewing(coordinator: NSObject) {
        attachmentViewCoordinator = nil;
    }
}

extension ObservationViewCardCollectionViewController: ObservationPushDelegate {
    func didPush(_ observation: Observation!, success: Bool, error: Error!) {
        if (observation.objectID != self.observation?.objectID) {
            return;
        }
        syncStatusView.updateObservationStatus();
        view.setNeedsUpdateConstraints();
    }
}

extension ObservationViewCardCollectionViewController: ObservationActionsDelegate {
    func showFavorites(_ observation: Observation) {
        var userIds: [String] = [];
        if let favorites = observation.favorites {
            for favorite in favorites {
                if let userId = favorite.userId {
                    userIds.append(userId)
                }
            }
        }
        if (userIds.count != 0) {
            let userViewController = UserTableViewController();
            userViewController.userIds = userIds;
            userViewController.title = "Favorited By";
            self.navigationController?.pushViewController(userViewController, animated: true);
        }
    }
    
    func favorite(_ observation: Observation) {
        observation.toggleFavorite() { success, error in
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            self.headerCard.populate(observation: observation);
        }
    }
    
    func getDirections(_ observation: Observation) {
        let appleMapsQueryString = "daddr=\(observation.location().coordinate.latitude),\(observation.location().coordinate.longitude)&ll=\(observation.location().coordinate.latitude),\(observation.location().coordinate.longitude)&q=\(observation.primaryFeedFieldText())".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed);
        let appleMapsUrl = URL(string: "https://maps.apple.com/?\(appleMapsQueryString ?? "")");
        
        let googleMapsUrl = URL(string: "https://maps.google.com/?\(appleMapsQueryString ?? "")");
        
        let alert = UIAlertController(title: "Get Directions With...", message: nil, preferredStyle: .actionSheet);
        alert.addAction(UIAlertAction(title: "Apple Maps", style: .default, handler: { (action) in
            UIApplication.shared.open(appleMapsUrl!, options: [:]) { (success) in
                print("opened? \(success)")
            }
        }))
        alert.addAction(UIAlertAction(title:"Google Maps", style: .default, handler: { (action) in
            UIApplication.shared.open(googleMapsUrl!, options: [:]) { (success) in
                print("opened? \(success)")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
        self.present(alert, animated: true, completion: nil);
    }
    
    func makeImportant(_ observation: Observation, reason: String) {
        observation.flagImportant(withDescription: reason) { success, error in
            // update the view
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            self.headerCard.populate(observation: observation);
        }
    }
    
    func removeImportant(_ observation: Observation) {
        observation.removeImportant() { success, error in
            // update the view
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            self.headerCard.populate(observation: observation);
        }
    }
}
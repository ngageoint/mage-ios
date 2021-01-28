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
import MaterialComponents.MDCContainerScheme;

@objc class ObservationViewCardCollectionViewController: UIViewController {
    
    var didSetupConstraints = false;
    
    var observation: Observation?;
    var observationForms: [[String: Any]] = [];
    var cards: [ExpandableCard] = [];
    var attachmentViewCoordinator: AttachmentViewCoordinator?;
    var headerCard: ObservationHeaderView?;
    var observationEditCoordinator: ObservationEditCoordinator?;
    var bottomSheet: MDCBottomSheetController?;
    var scheme: MDCContainerScheming?;
    
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
    
    @objc public func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
        self.scheme = containerScheme;
        self.navigationController?.navigationBar.isTranslucent = false;
        self.navigationController?.navigationBar.barTintColor = containerScheme.colorScheme.primaryColorVariant;
        self.navigationController?.navigationBar.tintColor = containerScheme.colorScheme.onPrimaryColor;
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : containerScheme.colorScheme.onPrimaryColor];
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onPrimaryColor];
        let appearance = UINavigationBarAppearance();
        appearance.configureWithOpaqueBackground();
        appearance.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onPrimaryColor,
            NSAttributedString.Key.backgroundColor: containerScheme.colorScheme.primaryColorVariant
        ];
        appearance.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: containerScheme.colorScheme.onPrimaryColor,
            NSAttributedString.Key.backgroundColor: containerScheme.colorScheme.primaryColorVariant
        ];
        
        self.navigationController?.navigationBar.standardAppearance = appearance;
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController?.navigationBar.standardAppearance.backgroundColor = containerScheme.colorScheme.primaryColorVariant;
        self.navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = containerScheme.colorScheme.primaryColorVariant;
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.syncStatusView.applyTheme(withScheme: containerScheme);
        headerCard?.applyTheme(withScheme: containerScheme);
    }
    
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
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc convenience public init(observation: Observation, scheme: MDCContainerScheming) {
        self.init(frame: CGRect.zero);
        self.observation = observation;
        self.scheme = scheme;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.accessibilityIdentifier = "ObservationViewCardCollection"
        self.view.accessibilityLabel = "ObservationViewCardCollection"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        ObservationPushService.singleton()?.add(self);
        setupObservation();
        if let safeScheme = self.scheme {
            applyTheme(withContainerScheme: safeScheme);
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        ObservationPushService.singleton()?.remove(self);
    }
    
    func setupObservation() {
        self.title = observation?.primaryFeedFieldText();

        if let safeProperties = self.observation?.properties as? [String: Any] {
            if (safeProperties.keys.contains("forms")) {
                observationForms = safeProperties["forms"] as! [[String: Any]];
            }
        } else {
            observationForms = [];
        }
        for v in stackView.arrangedSubviews {
            v.removeFromSuperview();
        }
        addHeaderCard(stackView: stackView);
        addLegacyAttachmentCard(stackView: stackView);
        addFormViews(stackView: stackView);
    }
    
    func addHeaderCard(stackView: UIStackView) {
        if let safeObservation = observation {
            headerCard = ObservationHeaderView(observation: safeObservation, observationActionsDelegate: self);
            if let safeScheme = self.scheme {
                headerCard!.applyTheme(withScheme: safeScheme);
            }
            stackView.addArrangedSubview(headerCard!);
        }
    }
    
    // for legacy servers add the attachment field to common
    // TODO: Verify the correct version of the server and this can be removed once all servers are upgraded
    func addLegacyAttachmentCard(stackView: UIStackView) {
        if (UserDefaults.standard.serverMajorVersion < 6) {
            if let safeObservation = observation {
                if (safeObservation.attachments?.count != 0) {
                    let attachmentCard: ObservationAttachmentCard = ObservationAttachmentCard(observation: safeObservation, attachmentSelectionDelegate: self, viewController: self);
                    if let safeScheme = self.scheme {
                        attachmentCard.applyTheme(withScheme: safeScheme);
                    }
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
        if let safeScheme = self.scheme {
            formView.applyTheme(withScheme: safeScheme);
        }
        var formSpacerView: UIView?;
        if (!formView.isEmpty()) {
            formSpacerView = UIView(forAutoLayout: ());
            formSpacerView?.addSubview(formView);
            formView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16));
        }
        var tintColor: UIColor? = nil;
        if let safeColor = eventForm?["color"] as? String {
            tintColor = UIColor(hex: safeColor);
        } else {
            tintColor = scheme?.colorScheme.primaryColor
        }
        let card = ExpandableCard(header: formPrimaryValue, subheader: formSecondaryValue, imageName: "description", title: eventForm?["name"] as? String, imageTint: tintColor, expandedView: formSpacerView);
        if let safeScheme = self.scheme {
            card.applyTheme(withScheme: safeScheme);
        }
        stackView.addArrangedSubview(card);
        cards.append(card);
        return card;
    }
    
    @objc func editObservation(sender: UIBarButtonItem) {
        observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: self.observation!);
        observationEditCoordinator?.applyTheme(withContainerScheme: self.scheme);
        observationEditCoordinator?.start();
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
    
    func moreActionsTapped(_ observation: Observation) {
        let actionsSheet: ObservationActionsSheetController = ObservationActionsSheetController(observation: observation, delegate: self);
        actionsSheet.applyTheme(withContainerScheme: scheme);
        bottomSheet = MDCBottomSheetController(contentViewController: actionsSheet);
        self.navigationController?.present(bottomSheet!, animated: true, completion: nil);
    }
    
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
            let userViewController = UserTableViewController(scheme: self.scheme)!;
            userViewController.userIds = userIds;
            userViewController.title = "Favorited By";
            self.navigationController?.pushViewController(userViewController, animated: true);
        }
    }
    
    func favorite(_ observation: Observation) {
        observation.toggleFavorite() { success, error in
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            self.headerCard?.populate(observation: observation);
        }
    }
    
    func copyLocation(_ locationString: String) {
        UIPasteboard.general.string = locationString;
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location copied to clipboard"))
    }
    
    
    func getDirections(_ observation: Observation) {
        ObservationActionHandler.getDirections(latitude: observation.location().coordinate.latitude, longitude: observation.location().coordinate.longitude, title: observation.primaryFeedFieldText(), viewController: self);
    }
    
    func makeImportant(_ observation: Observation, reason: String) {
        observation.flagImportant(withDescription: reason) { success, error in
            // update the view
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            self.headerCard?.populate(observation: observation);
        }
    }
    
    func removeImportant(_ observation: Observation) {
        observation.removeImportant() { success, error in
            // update the view
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            self.headerCard?.populate(observation: observation);
        }
    }
    
    func editObservation(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: self.observation!);
        observationEditCoordinator?.applyTheme(withContainerScheme: self.scheme);
        observationEditCoordinator!.start();
    }
    
    func reorderForms(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: self.observation!);
        observationEditCoordinator?.applyTheme(withContainerScheme: self.scheme);
        observationEditCoordinator!.startFormReorder();
    }
    
    func deleteObservation(_ observation: Observation) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        ObservationActionHandler.deleteObservation(observation: observation, viewController: self) { (success, error) in
            self.navigationController?.popViewController(animated: true);
        }
    }
    
    func cancelAction() {
        bottomSheet?.dismiss(animated: true, completion: nil);
    }
}

extension ObservationViewCardCollectionViewController: ObservationEditDelegate {
    func editCancel(_ coordinator: NSObject) {
        observationEditCoordinator = nil;
    }
    
    func editComplete(_ observation: Observation, coordinator: NSObject) {
        observationEditCoordinator = nil;
        self.observation!.managedObjectContext?.refresh(self.observation!, mergeChanges: false);
        // reload the observation
        setupObservation();
    }
    
    func observationDeleted(_ observation: Observation, coordinator: NSObject) {
        observationEditCoordinator = nil;
        self.navigationController?.popViewController(animated: false);
    }
}

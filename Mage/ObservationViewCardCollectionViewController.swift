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
    
    weak var observation: Observation?;
    var observationForms: [[String: Any]] = [];
    var cards: [ExpandableCard] = [];
    var attachmentViewCoordinator: AttachmentViewCoordinator?;
    var headerCard: ObservationHeaderView?;
    var observationEditCoordinator: ObservationEditCoordinator?;
    var bottomSheet: MDCBottomSheetController?;
    var scheme: MDCContainerScheming?;
    var attachmentCard: ObservationAttachmentCard?;
    
    private lazy var eventForms: [[String: Any]] = {
        let eventForms = Event.getById(self.observation?.eventId as Any, in: (self.observation?.managedObjectContext)!).forms as? [[String: Any]] ?? [];
        return eventForms;
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.newAutoLayout();
        scrollView.accessibilityIdentifier = "card scroll";
        return scrollView;
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
        attachmentCard?.applyTheme(withScheme: containerScheme);
    }
    
    override func loadView() {
        view = UIView();
        
        view.addSubview(scrollView);
        scrollView.addSubview(stackView);
        
        view.setNeedsUpdateConstraints();
    }
    
    override func updateViewConstraints() {
        if (!didSetupConstraints) {
            scrollView.autoPinEdgesToSuperviewEdges(with: .zero);
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
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.startObservationEditCoordinator));
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
        headerCard?.stop();
        headerCard = nil;
        
        let removedSubviews = cards.reduce([]) { (allSubviews, subview) -> [UIView] in
            stackView.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        for v in removedSubviews {
            if v.superview != nil {
                v.removeFromSuperview()
            }
        }
        cards = [];
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
        stackView.addArrangedSubview(syncStatusView);
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
    // TODO: this can be removed once all servers are upgraded
    func addLegacyAttachmentCard(stackView: UIStackView) {
        if (MageServer.isServerVersion5()) {
            if let safeObservation = observation {
                if (safeObservation.attachments?.count != 0) {
                    attachmentCard = ObservationAttachmentCard(observation: safeObservation, attachmentSelectionDelegate: self);
                    if let safeScheme = self.scheme {
                        attachmentCard!.applyTheme(withScheme: safeScheme);
                    }
                    stackView.addArrangedSubview(attachmentCard!);
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
            return form[FormKey.id.key] as? Int == observationForm[EventKey.formId.key] as? Int
        }
        
        var formPrimaryValue: String? = nil;
        var formSecondaryValue: String? = nil;
        if let primaryField = eventForm?[FormKey.primaryFeedField.key] as! String? {
            if let obsfield = observationForm[primaryField] as! String? {
                formPrimaryValue = obsfield;
            }
        }
        if let secondaryField = eventForm?[FormKey.secondaryFeedField.key] as! String? {
            if let obsfield = observationForm[secondaryField] as! String? {
                formSecondaryValue = obsfield;
            }
        }
        let formView = ObservationFormView(observation: self.observation!, form: observationForm, eventForm: eventForm, formIndex: index, editMode: false, viewController: self, attachmentSelectionDelegate: self, observationActionsDelegate: self);
        if let safeScheme = self.scheme {
            formView.applyTheme(withScheme: safeScheme);
        }
        var formSpacerView: UIView?;
        if (!formView.isEmpty()) {
            formSpacerView = UIView(forAutoLayout: ());
            let divider = UIView(forAutoLayout: ());
            divider.backgroundColor = UIColor.black.withAlphaComponent(0.12);
            divider.autoSetDimension(.height, toSize: 1);
            formSpacerView?.addSubview(divider);
            formSpacerView?.addSubview(formView);
            divider.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
            formView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16));
        }
        var tintColor: UIColor? = nil;
        if let safeColor = eventForm?[FormKey.color.key] as? String {
            tintColor = UIColor(hex: safeColor);
        } else {
            tintColor = scheme?.colorScheme.primaryColor
        }
        let card = ExpandableCard(header: formPrimaryValue, subheader: formSecondaryValue, imageName: "description", title: eventForm?[EventKey.name.key] as? String, imageTint: tintColor, expandedView: formSpacerView);
        if let safeScheme = self.scheme {
            card.applyTheme(withScheme: safeScheme);
        }
        stackView.addArrangedSubview(card);
        cards.append(card);
        return card;
    }
    
    @objc func startObservationEditCoordinator() {
        observationEditCoordinator = ObservationEditCoordinator(rootViewController: self.navigationController, delegate: self, observation: self.observation!);
        observationEditCoordinator?.applyTheme(withContainerScheme: self.scheme);
        observationEditCoordinator!.start();
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
        if let safeScheme = self.scheme {
            syncStatusView.applyTheme(withScheme: safeScheme);
        }
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
    
    func favoriteObservation(_ observation: Observation) {
        observation.toggleFavorite() { success, error in
            observation.managedObjectContext?.refresh(observation, mergeChanges: false);
            self.headerCard?.populate(observation: observation);
        }
    }
    
    func copyLocation(_ locationString: String) {
        UIPasteboard.general.string = locationString;
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location copied to clipboard"))
    }
    
    
    func getDirectionsToObservation(_ observation: Observation) {
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
        startObservationEditCoordinator()
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
    
    func viewUser(_ user: User) {
        bottomSheet?.dismiss(animated: true, completion: nil);
        let uvc = UserViewController(user: user, scheme: self.scheme!);
        self.navigationController?.pushViewController(uvc, animated: true);
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
}

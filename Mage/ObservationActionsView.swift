//
//  ObservationActionsView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/17/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import MaterialComponents.MDCPalettes

class ObservationActionsView: UIView {
    var didSetupConstraints = false;
    weak var observation: Observation?;
    weak var observationActionsDelegate: ObservationActionsDelegate?;
    internal var currentUserFavorited: Bool = false;
    internal var isImportant: Bool = false;
    var bottomSheet: MDCBottomSheetController?;
    internal var scheme: MDCContainerScheming?;
    
    var favoriteCountText: NSAttributedString {
        get {
            let favoriteCountText = NSMutableAttributedString();
            if let favorites = observation?.favorites {
                let favoriteCount: Int = favorites.reduce(0) { (result, favorite) -> Int in
                    if (favorite.favorite) {
                        return result + 1;
                    }
                    return result;
                }
                let favoriteLabelAttributes: [NSAttributedString.Key: Any] = [
                    .font: scheme?.typographyScheme.overline ?? UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                    .foregroundColor: scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6) ?? UIColor.label.withAlphaComponent(0.6)
                ];
                let favoriteCountAttributes: [NSAttributedString.Key: Any] = [
                    .font: scheme?.typographyScheme.overline ?? UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
                    .foregroundColor: scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87) ?? UIColor.label.withAlphaComponent(0.87)
                ];
                favoriteCountText.append(NSAttributedString(string: "\(favoriteCount)", attributes: favoriteCountAttributes))
                favoriteCountText.append(NSAttributedString(string: favoriteCount == 1 ? " FAVORITE" : " FAVORITES", attributes: favoriteLabelAttributes))
            }
            return favoriteCountText;
        }
    }
    
    private lazy var divider: UIView = {
        let divider = UIView(forAutoLayout: ());
        divider.autoSetDimension(.height, toSize: 1);
        return divider;
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = .zero;
        stackView.isLayoutMarginsRelativeArrangement = true;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        return stackView;
    }()
    
    private lazy var actionButtonView: UIView = {
        let actionButtonView = UIView.newAutoLayout();
        actionButtonView.addSubview(favoriteCountButton);
        actionButtonView.addSubview(importantButton);
        actionButtonView.addSubview(directionsButton);
        actionButtonView.addSubview(favoriteButton);
        actionButtonView.addSubview(moreButton);
        return actionButtonView;
    }()
    
    private lazy var favoriteCountButton: MDCButton = {
        let button = MDCButton();
        button.accessibilityLabel = "show favorites";
        button.addTarget(self, action: #selector(showFavorites), for: .touchUpInside);
        button.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        return button;
    }()
    
    private lazy var moreButton: MDCButton = {
        let moreButton = MDCButton();
        moreButton.accessibilityLabel = "more";
        moreButton.setImage(UIImage(named: "more")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside);
        moreButton.autoSetDimensions(to: CGSize(width: 40, height: 40));
        moreButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        moreButton.inkMaxRippleRadius = 30;
        moreButton.inkStyle = .unbounded;
        return moreButton;
    }()
    
    private lazy var favoriteButton: MDCButton = {
        let favoriteButton = MDCButton();
        favoriteButton.accessibilityLabel = "favorite";
        favoriteButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        favoriteButton.addTarget(self, action: #selector(favoriteObservation), for: .touchUpInside);
        favoriteButton.autoSetDimensions(to: CGSize(width: 40, height: 40));
        favoriteButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        favoriteButton.inkMaxRippleRadius = 30;
        favoriteButton.inkStyle = .unbounded;
        return favoriteButton;
    }()
    
    private lazy var directionsButton: MDCButton = {
        let directionsButton = MDCButton();
        directionsButton.accessibilityLabel = "directions";
        directionsButton.setImage(UIImage(systemName: "arrow.triangle.turn.up.right.diamond", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        directionsButton.addTarget(self, action: #selector(getDirectionsToObservation), for: .touchUpInside);
        directionsButton.autoSetDimensions(to: CGSize(width: 40, height: 40));
        directionsButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        directionsButton.inkMaxRippleRadius = 30;
        directionsButton.inkStyle = .unbounded;
        return directionsButton;
    }()
    
    private lazy var importantButton: MDCButton = {
        let importantButton = MDCButton();
        importantButton.accessibilityLabel = "important";
        importantButton.setImage(UIImage(systemName: "flag", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        importantButton.addTarget(self, action: #selector(toggleImportant), for: .touchUpInside);
        importantButton.autoSetDimensions(to: CGSize(width: 40, height: 40));
        importantButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        importantButton.inkMaxRippleRadius = 30;
        importantButton.inkStyle = .unbounded;
        return importantButton;
    }()
    
    private lazy var importantInputView: MDCFilledTextField = {
        let textField = MDCFilledTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        textField.autocapitalizationType = .none;
        textField.accessibilityLabel = "Important Description";
        textField.label.text = "Important Description"
        textField.placeholder = "Important Description"
        textField.inputAccessoryView = accessoryView;
        textField.sizeToFit();
        return textField;
    }()
    
    private lazy var accessoryView: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44));
        toolbar.autoSetDimension(.height, toSize: 44);
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed));
        doneBarButton.accessibilityLabel = "Done";
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed));
        cancelBarButton.accessibilityLabel = "Cancel";
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        
        toolbar.items = [cancelBarButton, flexSpace, doneBarButton];
        return toolbar;
    }()
    
    private lazy var setImportantButton: MDCButton = {
        let setImportantButton = MDCButton(forAutoLayout: ());
        setImportantButton.accessibilityLabel = "Flag as important";
        setImportantButton.setTitle("Flag as important", for: .normal);
        setImportantButton.addTarget(self, action: #selector(makeImportant), for: .touchUpInside);
        setImportantButton.clipsToBounds = true;
        return setImportantButton;
    }()
    
    private lazy var cancelOrRemoveButton: MDCButton = {
        let cancelOrRemoveButton = MDCButton(forAutoLayout: ());
        cancelOrRemoveButton.accessibilityLabel = "Cancel";
        cancelOrRemoveButton.setTitle("Cancel", for: .normal);
        cancelOrRemoveButton.addTarget(self, action: #selector(removeImportant), for: .touchUpInside);
        cancelOrRemoveButton.clipsToBounds = true;
        return cancelOrRemoveButton;
    }()
    
    private lazy var importantWrapperView: UIView = {
        let importantWrapperView = UIView.newAutoLayout();
        importantWrapperView.accessibilityLabel = "edit important";
        importantWrapperView.isHidden = true;
        importantWrapperView.clipsToBounds = true;
        
        let buttonView = UIView.newAutoLayout();
        buttonView.clipsToBounds = true;
        buttonView.addSubview(setImportantButton);
        setImportantButton.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .left);
        buttonView.addSubview(cancelOrRemoveButton);
        cancelOrRemoveButton.autoPinEdge(.right, to: .left, of: setImportantButton, withOffset: 8)
        cancelOrRemoveButton.autoAlignAxis(.horizontal, toSameAxisOf: setImportantButton)
        
        importantWrapperView.addSubview(importantInputView);
        importantInputView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 8, bottom: 0, right: 8), excludingEdge: .bottom);

        importantWrapperView.addSubview(buttonView);
        buttonView.autoPinEdge(.top, to: .bottom, of: importantInputView, withOffset: 12);
        buttonView.autoPinEdge(toSuperviewEdge: .left, withInset: 8);
        buttonView.autoPinEdge(toSuperviewEdge: .right, withInset: 8);
        
        importantWrapperView.addSubview(divider);
        divider.autoPinEdge(.top, to: .bottom, of: buttonView, withOffset: 16);
        divider.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
        
        return importantWrapperView;
    }()
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme;
        divider.backgroundColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.12);

        favoriteButton.applyTextTheme(withScheme: scheme);
        importantButton.applyTextTheme(withScheme: scheme);
        directionsButton.applyTextTheme(withScheme: scheme);
        moreButton.applyTextTheme(withScheme: scheme);
        favoriteCountButton.applyTextTheme(withScheme: scheme);
        favoriteButton.setImageTintColor(currentUserFavorited ? MDCPalette.green.accent700 : scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal);
        favoriteButton.inkColor = MDCPalette.green.accent700?.withAlphaComponent(0.2);
        importantButton.setImageTintColor(isImportant ? MDCPalette.orange.accent400 : scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal);
        importantButton.inkColor = MDCPalette.orange.accent400?.withAlphaComponent(0.2);
        directionsButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
        moreButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)

        cancelOrRemoveButton.applyTextTheme(withScheme: scheme);
        setImportantButton.applyContainedTheme(withScheme: scheme);
        self.backgroundColor = scheme.colorScheme.surfaceColor
    }
    
    public convenience init(observation: Observation?, observationActionsDelegate: ObservationActionsDelegate?, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.observation = observation;
        self.observationActionsDelegate = observationActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        if let observation = observation {
            populate(observation: observation);
        }
        applyTheme(withScheme: scheme);
        self.accessibilityLabel = "actions";
    }
    
    func layoutView() {
        self.addSubview(stackView);
        stackView.autoPinEdgesToSuperviewEdges();
        stackView.addArrangedSubview(importantWrapperView);
        stackView.addArrangedSubview(actionButtonView);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            moreButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 24), excludingEdge: .left);
            directionsButton.autoPinEdge(.right, to: .left, of: moreButton, withOffset: -16);
            directionsButton.autoAlignAxis(.horizontal, toSameAxisOf: moreButton);
            favoriteButton.autoPinEdge(.right, to: .left, of: directionsButton, withOffset: -16);
            favoriteButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
            importantButton.autoPinEdge(.right, to: .left, of: favoriteButton, withOffset: -16);
            importantButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
            
            favoriteCountButton.autoAlignAxis(toSuperviewAxis: .horizontal);
            favoriteCountButton.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    public func populate(observation: Observation!) {
        self.observation = observation;
        favoriteCountButton.isHidden = true;
        favoriteCountButton.setAttributedTitle(favoriteCountText, for: .normal);
        importantButton.isHidden = !(self.observation?.currentUserCanUpdateImportant ?? false);
        
        currentUserFavorited = false;
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return }
        
        if let favorites = observation.favorites, let user = User.fetchCurrentUser(context: context) {
            currentUserFavorited = favorites.contains { (favorite) -> Bool in
                favoriteCountButton.isHidden = !(!favoriteCountButton.isHidden || favorite.favorite);
                return favorite.userId == user.remoteId && favorite.favorite;
            }
        }
        if (currentUserFavorited) {
            favoriteButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal);
        } else {
            favoriteButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal);
        }
        
        isImportant = false;
        if (!self.importantWrapperView.isHidden) {
            UIView.animate(withDuration: 0.2) {
                self.importantWrapperView.isHidden = true;
            }
        }
        importantInputView.text = nil;
        importantButton.setImage(UIImage(systemName: "flag", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal);
        setImportantButton.accessibilityLabel = "Flag as important";
        setImportantButton.setTitle("Flag as important", for: .normal);
        setImportantButton.isEnabled = true;
        cancelOrRemoveButton.accessibilityLabel = "Cancel";
        cancelOrRemoveButton.setTitle("Cancel", for: .normal);
        cancelOrRemoveButton.isEnabled = true;
        if let important = observation.observationImportant {
            if (important.important) {
                isImportant = true;
                importantButton.setImage(UIImage(systemName: "flag.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal);
                importantInputView.text = important.reason;
                setImportantButton.accessibilityLabel = "Update Important";
                setImportantButton.setTitle("Update", for: .normal);
                cancelOrRemoveButton.accessibilityLabel = "Remove";
                cancelOrRemoveButton.setTitle("Remove", for: .normal);
            }
        }
        if let scheme = scheme {
            applyTheme(withScheme: scheme);
        }
    }
    
    @objc func showFavorites() {
        observationActionsDelegate?.showFavorites?(observation!);
    }
    
    @objc func moreTapped() {
        observationActionsDelegate?.moreActionsTapped?(observation!);
    }
    
    @objc func favoriteObservation() {
        if let observation = observation {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.observationActionsDelegate?.favoriteObservation?(observation, completion: { savedObservation in
                    if let savedObservation = savedObservation {
                        self.observation = savedObservation;
                        self.populate(observation: savedObservation)
                    }
                });
            }
        }
    }
    
    @objc func getDirectionsToObservation(_ sender: UIButton) {
        observationActionsDelegate?.getDirectionsToObservation?(observation!, sourceView: sender);
    }
    
    @objc func toggleImportant() {
        UIView.animate(withDuration: 0.2) {
            self.importantWrapperView.isHidden = !self.importantWrapperView.isHidden;
        }
    }
    
    @objc func makeImportant() {
        importantInputView.resignFirstResponder();
        observationActionsDelegate?.makeImportant?(observation!, reason: self.importantInputView.text ?? "");
        setImportantButton.setTitle("Saving", for: .normal);
        setImportantButton.isEnabled = false;
    }
    
    @objc func removeImportant() {
        importantInputView.resignFirstResponder();
        if (observation?.isImportant == true) {
            observationActionsDelegate?.removeImportant?(observation!);
            cancelOrRemoveButton.setTitle("Removing", for: .normal);
            cancelOrRemoveButton.isEnabled = false;
        } else {
            toggleImportant();
        }
    }
    
    @objc func doneButtonPressed() {
        importantInputView.resignFirstResponder();
    }
    
    @objc func cancelButtonPressed() {
        importantInputView.resignFirstResponder();
    }
}

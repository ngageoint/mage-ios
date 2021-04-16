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
    internal var controller: MDCTextInputControllerFilled = MDCTextInputControllerFilled();
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
        divider.backgroundColor = UIColor.black.withAlphaComponent(0.12);
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
    
    private lazy var favoriteCountButton: UIButton = {
        let button = UIButton(type: .custom);
        button.accessibilityLabel = "show favorites";
        button.addTarget(self, action: #selector(showFavorites), for: .touchUpInside);
        return button;
    }()
    
    private lazy var moreButton: UIButton = {
        let moreButton = UIButton(type: .custom);
        moreButton.accessibilityLabel = "more";
        moreButton.setImage(UIImage(named: "more"), for: .normal);
        moreButton.addTarget(self, action: #selector(moreTapped), for: .touchUpInside);
        return moreButton;
    }()
    
    private lazy var favoriteButton: UIButton = {
        let favoriteButton = UIButton(type: .custom);
        favoriteButton.accessibilityLabel = "favorite";
        favoriteButton.setImage(UIImage(named: "favorite_large"), for: .normal);
        favoriteButton.addTarget(self, action: #selector(favoriteObservation), for: .touchUpInside);
        return favoriteButton;
    }()
    
    private lazy var directionsButton: UIButton = {
        let directionsButton = UIButton(type: .custom);
        directionsButton.accessibilityLabel = "directions";
        directionsButton.setImage(UIImage(named: "directions_large"), for: .normal);
        directionsButton.addTarget(self, action: #selector(getDirectionsToObservation), for: .touchUpInside);
        return directionsButton;
    }()
    
    private lazy var importantButton: UIButton = {
        let importantButton = UIButton(type: .custom);
        importantButton.accessibilityLabel = "important";
        importantButton.setImage(UIImage(named: "flag"), for: .normal);
        importantButton.addTarget(self, action: #selector(toggleImportant), for: .touchUpInside);
        return importantButton;
    }()
    
    private lazy var importantInputView: MDCTextField = {
        let textField = MDCTextField(forAutoLayout: ());
        textField.autocapitalizationType = .none;
        controller.textInput = textField;
        controller.placeholderText = "Important Description"
        textField.accessibilityLabel = "Important Description";
        return textField;
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
        
        importantWrapperView.addSubview(importantInputView);
        importantInputView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 8, bottom: 0, right: 8), excludingEdge: .bottom);

        importantWrapperView.addSubview(buttonView);
        buttonView.autoPinEdge(.top, to: .bottom, of: importantInputView, withOffset: -12);
        buttonView.autoPinEdge(toSuperviewEdge: .left, withInset: 8);
        buttonView.autoPinEdge(toSuperviewEdge: .right, withInset: 8);
        
        importantWrapperView.addSubview(divider);
        divider.autoPinEdge(.top, to: .bottom, of: buttonView, withOffset: 16);
        divider.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
        
        return importantWrapperView;
    }()
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
        favoriteButton.tintColor = currentUserFavorited ? MDCPalette.green.accent700 : scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        importantButton.tintColor = isImportant ? MDCPalette.orange.accent400 : scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        cancelOrRemoveButton.applyTextTheme(withScheme: scheme);
        setImportantButton.applyContainedTheme(withScheme: scheme);
        directionsButton.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        moreButton.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
    }
    
    public convenience init(observation: Observation?, observationActionsDelegate: ObservationActionsDelegate?, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.observation = observation;
        self.observationActionsDelegate = observationActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        if let safeObservation = observation {
            populate(observation: safeObservation);
        }
        if let safeScheme = self.scheme {
            applyTheme(withScheme: safeScheme);
        }
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
            directionsButton.autoPinEdge(.right, to: .left, of: moreButton, withOffset: -32);
            directionsButton.autoAlignAxis(.horizontal, toSameAxisOf: moreButton);
            favoriteButton.autoPinEdge(.right, to: .left, of: directionsButton, withOffset: -32);
            favoriteButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
            importantButton.autoPinEdge(.right, to: .left, of: favoriteButton, withOffset: -32);
            importantButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
            
            moreButton.autoSetDimensions(to: CGSize(width: 24, height: 24));
            directionsButton.autoSetDimensions(to: CGSize(width: 24, height: 24));
            favoriteButton.autoSetDimensions(to: CGSize(width: 24, height: 24));
            importantButton.autoSetDimensions(to: CGSize(width: 24, height: 24));
            
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
        importantButton.isHidden = !(self.observation?.currentUserCanUpdateImportant() ?? false);
        
        currentUserFavorited = false;
        if let favorites = observation.favorites {
            let user = User.fetchCurrentUser(in: NSManagedObjectContext.mr_default());
            currentUserFavorited = favorites.contains { (favorite) -> Bool in
                favoriteCountButton.isHidden = !(!favoriteCountButton.isHidden || favorite.favorite);
                return favorite.userId == user.remoteId && favorite.favorite;
            }
        }
        
        isImportant = false;
        importantInputView.text = nil;
        if let important = observation.observationImportant {
            if (important.important == NSNumber(booleanLiteral: true)) {
                isImportant = true;
                importantInputView.text = important.reason;
                setImportantButton.accessibilityLabel = "Update Important";
                setImportantButton.setTitle("Update", for: .normal);
                cancelOrRemoveButton.accessibilityLabel = "Remove";
                cancelOrRemoveButton.setTitle("Remove", for: .normal);
            }
        }
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    @objc func showFavorites() {
        observationActionsDelegate?.showFavorites?(observation!);
    }
    
    @objc func moreTapped() {
        observationActionsDelegate?.moreActionsTapped?(observation!);
    }
    
    @objc func favoriteObservation() {
        observationActionsDelegate?.favoriteObservation?(observation!);
    }
    
    @objc func getDirectionsToObservation() {
        observationActionsDelegate?.getDirectionsToObservation?(observation!);
    }
    
    @objc func toggleImportant() {
        UIView.animate(withDuration: 0.2) {
            self.importantWrapperView.isHidden = !self.importantWrapperView.isHidden;
        }
    }
    
    @objc func makeImportant() {
        observationActionsDelegate?.makeImportant?(observation!, reason: self.importantInputView.text ?? "");
        toggleImportant();
    }
    
    @objc func removeImportant() {
        if (observation?.isImportant() == true) {
            observationActionsDelegate?.removeImportant?(observation!);
        }
        
        toggleImportant();
    }
}

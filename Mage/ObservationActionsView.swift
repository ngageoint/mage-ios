//
//  ObservationActionsView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/17/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import PureLayout
import CoreData

class ObservationActionsView: UIView {
    private var didSetupConstraints = false
    weak var observation: Observation?
    weak var observationActionsDelegate: ObservationActionsDelegate?
    private var currentUserFavorited: Bool = false
    private var isImportant: Bool = false

    private var scheme: AppContainerScheming?
    
    private lazy var divider: UIView = {
        let view = UIView(forAutoLayout: ())
        view.autoSetDimension(.height, toSize: 1)
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ())
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.distribution = .fill
        return stackView
    }()
    
    private lazy var actionButtonView: UIView = {
        let view = UIView.newAutoLayout()
        actionButtonView.addSubview(favoriteCountButton)
        actionButtonView.addSubview(importantButton)
        actionButtonView.addSubview(directionsButton)
        actionButtonView.addSubview(favoriteButton)
        actionButtonView.addSubview(moreButton)
        return actionButtonView
    }()
    
    private lazy var favoriteCountButton: UIButton = {
        let button = UIButton(type: .system)
        button.accessibilityLabel = "show favorites"
        button.addTarget(self, action: #selector(showFavorites), for: .touchUpInside)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()
    
    private lazy var moreButton: UIButton = makeIconButton(named: "more", action: #selector(moreTapped))
    
    private lazy var favoriteButton: UIButton = makeIconButton(
        systemName: "heart",
        filledSystemName: "heart.fill",
        action: #selector(favoriteObservation)
    )
    
    private lazy var directionsButton: UIButton = makeIconButton(
        systemName: "arrow.triangle.turn.up.right.diamond",
        action: #selector(getDirectionsToObservation)
    )
    
    private lazy var importantButton: UIButton = makeIconButton(
        systemName: "flag",
        filledSystemName: "flag.fill",
        action: #selector(toggleImportant)
    )
    
    private lazy var importantInputView: UITextField = {
        let field = UITextField(forAutoLayout: ())
        field.borderStyle = .roundedRect
        field.placeholder = "Important Description"
        field.accessibilityLabel = "Important Description"
        field.inputAccessoryView = accessoryView
        return field
    }()
    
    
//    var favoriteCountText: NSAttributedString {
//        get {
//            let favoriteCountText = NSMutableAttributedString()
//            if let favorites = observation?.favorites {
//                let favoriteCount: Int = favorites.reduce(0) { (result, favorite) -> Int in
//                    if (favorite.favorite) {
//                        return result + 1
//                    }
//                    return result
//                }
//                let favoriteLabelAttributes: [NSAttributedString.Key: Any] = [
//                    .font: scheme?.typographyScheme.overline ?? UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
//                    .foregroundColor: scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6) ?? UIColor.label.withAlphaComponent(0.6)
//                ]
//                let favoriteCountAttributes: [NSAttributedString.Key: Any] = [
//                    .font: scheme?.typographyScheme.overline ?? UIFont.systemFont(ofSize: UIFont.smallSystemFontSize),
//                    .foregroundColor: scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87) ?? UIColor.label.withAlphaComponent(0.87)
//                ]
//                favoriteCountText.append(NSAttributedString(string: "\(favoriteCount)", attributes: favoriteCountAttributes))
//                favoriteCountText.append(NSAttributedString(string: favoriteCount == 1 ? " FAVORITE" : " FAVORITES", attributes: favoriteLabelAttributes))
//            }
//            return favoriteCountText
//        }
//    }
//    
   

    private lazy var accessoryView: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [cancel, flex, done]
        return toolbar
    }()
    
    private lazy var setImportantButton: UIButton = {
        let button = UIButton(forAutoLayout: ())
        button.setTitle("Flag as important", for: .normal)
        button.accessibilityLabel = "Flag as important"
        button.addTarget(self, action: #selector(makeImportant), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelOrRemoveButton: UIButton = {
        let button = UIButton(forAutoLayout: ())
        button.setTitle("Cancel", for: .normal)
        button.accessibilityLabel = "Cancel"
        button.addTarget(self, action: #selector(removeImportant), for: .touchUpInside)
        return button
    }()
    
    private lazy var importantWrapperView: UIView = {
        let view = UIView.newAutoLayout()
        view.isHidden = true
        view.accessibilityLabel = "edit important"
        
        let buttonContainer = UIView.newAutoLayout()
        buttonContainer.addSubview(setImportantButton)
        buttonContainer.addSubview(cancelOrRemoveButton)

        setImportantButton.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .left)
        cancelOrRemoveButton.autoPinEdge(.right, to: .left, of: setImportantButton, withOffset: 8)
        cancelOrRemoveButton.autoAlignAxis(.horizontal, toSameAxisOf: setImportantButton)
        
        view.addSubview(importantInputView)
        importantInputView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 8, bottom: 0, right: 8), excludingEdge: .bottom)

        view.addSubview(buttonContainer)
        buttonContainer.autoPinEdge(.top, to: .bottom, of: importantInputView, withOffset: 12)
        buttonContainer.autoPinEdge(toSuperviewEdge: .left, withInset: 8)
        buttonContainer.autoPinEdge(toSuperviewEdge: .right, withInset: 8)
        
        view.addSubview(divider)
        divider.autoPinEdge(.top, to: .bottom, of: buttonContainer, withOffset: 16)
        divider.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
        return view
    }()
    
    
    public convenience init(observation: Observation?, observationActionsDelegate: ObservationActionsDelegate?, scheme: AppContainerScheming?) {
        self.init(frame: CGRect.zero)
        self.observation = observation
        self.observationActionsDelegate = observationActionsDelegate
        self.scheme = scheme
        configureForAutoLayout()
        populate(observation: observation)
        applyTheme(withScheme: scheme)
        self.accessibilityLabel = "actions"
    }
    
    func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme else { return }

        backgroundColor = scheme.colorScheme.surfaceColor
        divider.backgroundColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.12)

        [favoriteButton, importantButton, directionsButton, moreButton].forEach {
            $0.tintColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        }
        
        favoriteButton.tintColor = currentUserFavorited ? UIColor.systemGreen : favoriteButton.tintColor
        importantButton.tintColor = isImportant ? UIColor.systemOrange : importantButton.tintColor
    }

    
    // MARK: - Population

    func populate(observation: Observation?) {
        self.observation = observation
        favoriteCountButton.setAttributedTitle(favoriteCountText(), for: .normal)

        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?

        currentUserFavorited = observation?.isCurrentUserFavorited(in: context) ?? false
        isImportant = observation?.observationImportant?.important ?? false

        favoriteButton.setImage(UIImage(systemName: currentUserFavorited ? "heart.fill" : "heart"), for: .normal)
        importantButton.setImage(UIImage(systemName: isImportant ? "flag.fill" : "flag"), for: .normal)

        importantInputView.text = observation?.observationImportant?.reason
        importantWrapperView.isHidden = true
    }

//    public func populate(observation: Observation!) {
//        self.observation = observation
//        favoriteCountButton.isHidden = true
//        favoriteCountButton.setAttributedTitle(favoriteCountText, for: .normal)
//        importantButton.isHidden = !(self.observation?.currentUserCanUpdateImportant ?? false)
//        
//        currentUserFavorited = false
//        @Injected(\.nsManagedObjectContext)
//        var context: NSManagedObjectContext?
//        
//        guard let context = context else { return }
//        
//        if let favorites = observation.favorites, let user = User.fetchCurrentUser(context: context) {
//            currentUserFavorited = favorites.contains { (favorite) -> Bool in
//                favoriteCountButton.isHidden = !(!favoriteCountButton.isHidden || favorite.favorite)
//                return favorite.userId == user.remoteId && favorite.favorite
//            }
//        }
//        if (currentUserFavorited) {
//            favoriteButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
//        } else {
//            favoriteButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
//        }
//        
//        isImportant = false
//        if (!self.importantWrapperView.isHidden) {
//            UIView.animate(withDuration: 0.2) {
//                self.importantWrapperView.isHidden = true
//            }
//        }
//        importantInputView.text = nil
//        importantButton.setImage(UIImage(systemName: "flag", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
//        setImportantButton.accessibilityLabel = "Flag as important"
//        setImportantButton.setTitle("Flag as important", for: .normal)
//        setImportantButton.isEnabled = true
//        cancelOrRemoveButton.accessibilityLabel = "Cancel"
//        cancelOrRemoveButton.setTitle("Cancel", for: .normal)
//        cancelOrRemoveButton.isEnabled = true
//        if let important = observation.observationImportant {
//            if (important.important) {
//                isImportant = true
//                importantButton.setImage(UIImage(systemName: "flag.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
//                importantInputView.text = important.reason
//                setImportantButton.accessibilityLabel = "Update Important"
//                setImportantButton.setTitle("Update", for: .normal)
//                cancelOrRemoveButton.accessibilityLabel = "Remove"
//                cancelOrRemoveButton.setTitle("Remove", for: .normal)
//            }
//        }
//        if let scheme = scheme {
//            applyTheme(withScheme: scheme)
//        }
//    }
    
    
    
    private func favoriteCountText() -> NSAttributedString {
          guard let count = observation?.favoriteCount else { return NSAttributedString(string: "") }

          let normalAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: UIColor.secondaryLabel]
          let boldAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: UIColor.label]

          let result = NSMutableAttributedString(string: "\(count)", attributes: boldAttrs)
          result.append(NSAttributedString(string: count == 1 ? " FAVORITE" : " FAVORITES", attributes: normalAttrs))
          return result
      }
    
    
    
    func layoutView() {
        self.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        stackView.addArrangedSubview(importantWrapperView)
        stackView.addArrangedSubview(actionButtonView)
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            moreButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 24), excludingEdge: .left)
            directionsButton.autoPinEdge(.right, to: .left, of: moreButton, withOffset: -16)
            directionsButton.autoAlignAxis(.horizontal, toSameAxisOf: moreButton)
            favoriteButton.autoPinEdge(.right, to: .left, of: directionsButton, withOffset: -16)
            favoriteButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton)
            importantButton.autoPinEdge(.right, to: .left, of: favoriteButton, withOffset: -16)
            importantButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton)
            
            favoriteCountButton.autoAlignAxis(toSuperviewAxis: .horizontal)
            favoriteCountButton.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            didSetupConstraints = true
        }
        super.updateConstraints()
    }
    
    
    @objc func showFavorites() {
        observationActionsDelegate?.showFavorites?(observation!)
    }
    
    @objc func moreTapped() {
        observationActionsDelegate?.moreActionsTapped?(observation!)
    }
    
    @objc func favoriteObservation() {
        if let observation = observation {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.observationActionsDelegate?.favoriteObservation?(observation, completion: { savedObservation in
                    if let savedObservation = savedObservation {
                        self.observation = savedObservation
                        self.populate(observation: savedObservation)
                    }
                })
            }
        }
    }
    
    @objc func getDirectionsToObservation(_ sender: UIButton) {
        observationActionsDelegate?.getDirectionsToObservation?(observation!, sourceView: sender)
    }
    
    @objc func toggleImportant() {
        UIView.animate(withDuration: 0.2) {
            self.importantWrapperView.isHidden = !self.importantWrapperView.isHidden
        }
    }
    
    @objc func makeImportant() {
        importantInputView.resignFirstResponder()
        observationActionsDelegate?.makeImportant?(observation!, reason: self.importantInputView.text ?? "")
        setImportantButton.setTitle("Saving", for: .normal)
        setImportantButton.isEnabled = false
    }
    
    @objc func removeImportant() {
        importantInputView.resignFirstResponder()
        if (observation?.isImportant == true) {
            observationActionsDelegate?.removeImportant?(observation!)
            cancelOrRemoveButton.setTitle("Removing", for: .normal)
            cancelOrRemoveButton.isEnabled = false
        } else {
            toggleImportant()
        }
    }
    
    @objc func doneButtonPressed() {
        importantInputView.resignFirstResponder()
    }
    
    @objc func cancelButtonPressed() {
        importantInputView.resignFirstResponder()
    }
}

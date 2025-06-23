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
    
    // MARK: - Initializers
    public convenience init(observation: Observation?, observationActionsDelegate: ObservationActionsDelegate?, scheme: AppContainerScheming?) {
        self.init(frame: CGRect.zero)
        self.observation = observation
        self.observationActionsDelegate = observationActionsDelegate
        self.scheme = scheme
        configureForAutoLayout()
        populate(observation: observation)
        applyTheme()
        self.accessibilityLabel = "actions"
    }

    
    // MARK: - Layout and Theming
    private func configureLayout() {
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges()
        stackView.addArrangedSubview(importantWrapperView)
        stackView.addArrangedSubview(actionButtonView)
        
        updateConstraintsIfNeeded()
    }

    override func updateConstraints() {
        if !didSetupConstraints {
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
    
    func applyTheme() {
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
    
    private func favoriteCountText() -> NSAttributedString {
          guard let count = observation?.favoriteCount else { return NSAttributedString(string: "") }

          let normalAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: UIColor.secondaryLabel]
          let boldAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote), .foregroundColor: UIColor.label]

          let result = NSMutableAttributedString(string: "\(count)", attributes: boldAttrs)
          result.append(NSAttributedString(string: count == 1 ? " FAVORITE" : " FAVORITES", attributes: normalAttrs))
          return result
      }
    
    
    // MARK: - Button Builders
    
    private func makeIconButton(named imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        
        button.setImage(image, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.autoSetDimensions(to: CGSize(width: 40, height: 40))
        
        return button
    }
    
    private func makeIconButton(systemName: String, filledSystemName: String? = nil, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))

        button.setImage(image, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.autoSetDimensions(to: CGSize(width: 40, height: 40))
        
        return button
    }
    
    
    // MARK: - Actions
    
    @objc private func showFavorites() {
        guard let observation else { return }
        observationActionsDelegate?.showFavorites?(observation)
    }
    
    @objc private func moreTapped() {
        guard let observation else { return }
        observationActionsDelegate?.moreActionsTapped?(observation)
    }
    
    @objc private func favoriteObservation() {
        guard let observation else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.observationActionsDelegate?.favoriteObservation?(observation) { updated in
                if let updated {
                    self.populate(observation: updated)
                }
            }
        }
    }
    
    @objc func getDirectionsToObservation(_ sender: UIButton) {
        guard let observation else { return }
        observationActionsDelegate?.getDirectionsToObservation?(observation, sourceView: sender)
    }
    
    @objc func toggleImportant() {
        UIView.animate(withDuration: 0.2) {
            self.importantWrapperView.isHidden.toggle()
        }
    }
    
    @objc func makeImportant() {
        guard let observation else { return }
        
        importantInputView.resignFirstResponder()
        observationActionsDelegate?.makeImportant?(observation, reason: importantInputView.text ?? "")
        setImportantButton.setTitle("Saving", for: .normal)
        setImportantButton.isEnabled = false
    }
    
    @objc func removeImportant() {
        guard let observation else { return }
        
        importantInputView.resignFirstResponder()
        
        if isImportant {
            observationActionsDelegate?.removeImportant?(observation)
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

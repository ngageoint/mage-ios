//
//  ObservationListActionsView.swift
//  MAGE
//
//  Created by Daniel Barela on 1/22/21.
//  Updated by Brent Michalski on 6/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import UIKit
import CoreLocation

class ObservationListActionsView: UIView {
    var didSetupConstraints = false
    var observation: Observation?
    weak var observationActionsDelegate: ObservationActionsDelegate?
    internal var currentUserFavorited = false
    internal var isImportant = false
    internal var scheme: AppContainerScheming?

    @Injected(\.userRepository)
    var userRepository: UserRepository

    private lazy var actionButtonView: UIView = {
        let view = UIView.newAutoLayout()
        view.addSubview(latitudeLongitudeButton)
        view.addSubview(directionsButton)
        view.addSubview(favoriteButton)
        view.addSubview(favoriteCount)
        return view
    }()

    lazy var latitudeLongitudeButton = LatitudeLongitudeButton()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityLabel = "favorite"
        
        let config = UIImage.SymbolConfiguration(weight: .semibold)
        let icon = UIImage(systemName: "heart", withConfiguration: config)
        button.setImage(icon, for: .normal)
        
        button.addTarget(self, action: #selector(favoriteObservation), for: .touchUpInside)
        return button
    }()

    private lazy var favoriteCount: UILabel = {
        let label = UILabel.newAutoLayout()
        return label
    }()

    private lazy var directionsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityLabel = "directions"
        
        let config = UIImage.SymbolConfiguration(weight: .semibold)
        let icon = UIImage(systemName: "arrow.triangle.turn.up.right.diamond", withConfiguration: config)
        button.setImage(icon, for: .normal)
        
        button.addTarget(self, action: #selector(getDirectionsToObservation), for: .touchUpInside)
        return button
    }()

    func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme else { return }

        self.scheme = scheme
        favoriteCount.textColor = currentUserFavorited ? .systemGreen : scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)

        let favoriteIconName = currentUserFavorited ? "heart.fill" : "heart"
        let config = UIImage.SymbolConfiguration(weight: .semibold)
        let icon = UIImage(systemName: favoriteIconName, withConfiguration: config)
        favoriteButton.setImage(icon, for: .normal)
        favoriteButton.tintColor = favoriteCount.textColor

        directionsButton.tintColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)

        latitudeLongitudeButton.applyTheme(withScheme: scheme)
        backgroundColor = scheme.colorScheme.surfaceColor
    }

    convenience init(observation: Observation?, observationActionsDelegate: ObservationActionsDelegate?, scheme: AppContainerScheming?) {
        self.init(frame: .zero)
        self.scheme = scheme
        self.observation = observation
        self.observationActionsDelegate = observationActionsDelegate
        configureForAutoLayout()
        layoutView()
        if let observation {
            populate(observation: observation, delegate: observationActionsDelegate)
        }
        applyTheme(withScheme: scheme)
    }

    func layoutView() {
        addSubview(actionButtonView)
    }

    override func updateConstraints() {
        if !didSetupConstraints {
            actionButtonView.autoSetDimension(.height, toSize: 56)
            actionButtonView.autoPinEdgesToSuperviewEdges()

            directionsButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
            directionsButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 24), excludingEdge: .left)

            favoriteButton.autoSetDimensions(to: CGSize(width: 40, height: 40))
            favoriteButton.autoPinEdge(.right, to: .left, of: directionsButton, withOffset: -16)
            favoriteButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton)

            favoriteCount.autoPinEdge(.left, to: .right, of: favoriteButton)
            favoriteCount.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton)

            latitudeLongitudeButton.autoAlignAxis(toSuperviewAxis: .horizontal)
            latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .left)

            didSetupConstraints = true
        }
        super.updateConstraints()
    }

    func populate(observation: Observation, delegate: ObservationActionsDelegate?) {
        self.observation = observation
        self.observationActionsDelegate = delegate

        latitudeLongitudeButton.coordinate = observation.geometry?.centroid()?.coordinate

        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?

        guard let context, let user = User.fetchCurrentUser(context: context), let favorites = observation.favorites else { return }

        currentUserFavorited = favorites.contains { $0.userId == user.remoteId && $0.favorite }
        let count = favorites.filter(\.favorite).count
        favoriteCount.text = count > 0 ? "\(count)" : nil

        applyTheme(withScheme: scheme)
    }

    @objc func favoriteObservation() {
        guard let observation else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            ObservationActions.favorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: self.userRepository.getCurrentUser()?.remoteId)()
            NotificationCenter.default.post(name: .ObservationUpdated, object: observation)
        }
    }

    @objc func getDirectionsToObservation(_ sender: UIButton) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        NotificationCenter.default.post(name: .DismissBottomSheet, object: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let notification = DirectionsToItemNotification(
                location: self.observation?.location,
                itemKey: self.observation?.objectID.uriRepresentation().absoluteString,
                dataSource: DataSources.observation,
                includeCopy: false
            )
            NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
        }
    }
}

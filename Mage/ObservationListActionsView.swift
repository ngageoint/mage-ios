//
//  ObservationListActionsView.swift
//  MAGE
//
//  Created by Daniel Barela on 1/22/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import MaterialComponents.MDCPalettes

class ObservationListActionsView: UIView {
    var didSetupConstraints = false;
    var observation: Observation?;
    weak var observationActionsDelegate: ObservationActionsDelegate?;
    internal var currentUserFavorited: Bool = false;
    internal var isImportant: Bool = false;
    var bottomSheet: MDCBottomSheetController?;
    internal var scheme: MDCContainerScheming?;
    
    private lazy var actionButtonView: UIView = {
        let actionButtonView = UIView.newAutoLayout();
        actionButtonView.addSubview(latitudeLongitudeButton);
        actionButtonView.addSubview(directionsButton);
        actionButtonView.addSubview(favoriteButton);
        actionButtonView.addSubview(favoriteCount);
        return actionButtonView;
    }()
    
    lazy var latitudeLongitudeButton: LatitudeLongitudeButton = LatitudeLongitudeButton()
    
    private lazy var favoriteButton: MDCButton = {
        let favoriteButton = MDCButton();
        favoriteButton.accessibilityLabel = "favorite";
        favoriteButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        favoriteButton.addTarget(self, action: #selector(favoriteObservation), for: .touchUpInside);
        favoriteButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        favoriteButton.inkMaxRippleRadius = 30;
        favoriteButton.inkStyle = .unbounded;
        return favoriteButton;
    }()
    
    private lazy var favoriteCount: UILabel = {
        let favoriteCount = UILabel(forAutoLayout: ());
        return favoriteCount;
    }()
    
    private lazy var directionsButton: MDCButton = {
        let directionsButton = MDCButton();
        directionsButton.accessibilityLabel = "directions";
        directionsButton.setImage(UIImage(systemName: "arrow.triangle.turn.up.right.diamond", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        directionsButton.addTarget(self, action: #selector(getDirectionsToObservation), for: .touchUpInside);
        directionsButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        directionsButton.inkMaxRippleRadius = 30;
        directionsButton.inkStyle = .unbounded;
        return directionsButton;
    }()
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme;
        favoriteCount.textColor = currentUserFavorited ? MDCPalette.green.accent700 : scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        favoriteCount.font = scheme.typographyScheme.overline;
        favoriteButton.applyTextTheme(withScheme: scheme);
        favoriteButton.setImageTintColor(currentUserFavorited ? MDCPalette.green.accent700 : scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal);
        favoriteButton.inkColor = MDCPalette.green.accent700?.withAlphaComponent(0.2);
        directionsButton.applyTextTheme(withScheme: scheme);
        directionsButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)

        latitudeLongitudeButton.applyTheme(withScheme: scheme);
        self.backgroundColor = scheme.colorScheme.surfaceColor;
    }
    
    public convenience init(observation: Observation?, observationActionsDelegate: ObservationActionsDelegate?, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.observation = observation;
        self.observationActionsDelegate = observationActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        if let observation = observation {
            populate(observation: observation, delegate: observationActionsDelegate);
        }
        applyTheme(withScheme: scheme);
    }
    
    func layoutView() {
        self.addSubview(actionButtonView);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            actionButtonView.autoSetDimension(.height, toSize: 56);
            actionButtonView.autoPinEdgesToSuperviewEdges();
            
            directionsButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 24), excludingEdge: .left);
            favoriteButton.autoPinEdge(.right, to: .left, of: directionsButton, withOffset: -16);
            favoriteButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
            favoriteCount.autoPinEdge(.left, to: .right, of: favoriteButton);
            favoriteCount.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
            
            directionsButton.autoSetDimensions(to: CGSize(width: 40, height: 40));
            favoriteButton.autoSetDimensions(to: CGSize(width: 40, height: 40));

            latitudeLongitudeButton.autoAlignAxis(toSuperviewAxis: .horizontal);
            latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .left, withInset: 0);
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    public func populate(observation: Observation!, delegate: ObservationActionsDelegate?) {
        self.observation = observation;
        self.observationActionsDelegate = delegate;
        if let geometry = self.observation?.geometry {
            if let point: SFPoint = geometry.centroid() {
                let coordinate = CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue)
                latitudeLongitudeButton.coordinate = coordinate
            }
        } else {
            latitudeLongitudeButton.coordinate = nil
        }
        
        currentUserFavorited = false;
        var favoriteCounter = 0;
        if let favorites = observation.favorites {
            if let user = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()) {
                currentUserFavorited = favorites.contains { (favorite) -> Bool in
                    return favorite.userId == user.remoteId && favorite.favorite;
                }
            }
            if (currentUserFavorited) {
                favoriteButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal);
            } else {
                favoriteButton.setImage(UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal);
            }
            favorites.forEach { favorite in
                if (favorite.favorite) {
                    favoriteCounter = favoriteCounter + 1
                }
            }
        }
        
        if (favoriteCounter != 0) {
            favoriteCount.text = "\(favoriteCounter)"
        } else {
            favoriteCount.text = nil;
        }
        
        isImportant = false;
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
        if let observation = observation {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                
                observation.toggleFavorite { (_, _) in
                    observation.managedObjectContext?.refresh(observation, mergeChanges: false);
                    self.populate(observation: observation, delegate: self.observationActionsDelegate)
                    NotificationCenter.default.post(name: .ObservationUpdated, object: observation)
                }
            }
        }
    }
    
    @objc func getDirectionsToObservation(_ sender: UIButton) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        NotificationCenter.default.post(name: .DismissBottomSheet, object: nil)
        // let the bottom sheet dismiss because we cannot present two alert dialogs
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let notification = DirectionsToItemNotification(observation: self.observation, user: nil, feedItem: nil)
            NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
        }
    }
}

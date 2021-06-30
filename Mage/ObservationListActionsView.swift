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
    var observationActionsDelegate: ObservationActionsDelegate?;
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
    
    private lazy var latitudeLongitudeButton: MDCButton = {
        let button = MDCButton(forAutoLayout: ());
        button.accessibilityLabel = "location";
        button.setImage(UIImage(named: "location_tracking_on")?.resized(to: CGSize(width: 14, height: 14)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.setInsets(forContentPadding: button.defaultContentEdgeInsets, imageTitlePadding: 5);
        button.addTarget(self, action: #selector(copyLocation), for: .touchUpInside);
        return button;
    }()
    
    private lazy var favoriteButton: UIButton = {
        let favoriteButton = UIButton(type: .custom);
        favoriteButton.accessibilityLabel = "favorite";
        favoriteButton.setImage(UIImage(named: "favorite_border"), for: .normal);
        favoriteButton.addTarget(self, action: #selector(favoriteObservation), for: .touchUpInside);
        return favoriteButton;
    }()
    
    private lazy var favoriteCount: UILabel = {
        let favoriteCount = UILabel(forAutoLayout: ());
        return favoriteCount;
    }()
    
    private lazy var directionsButton: UIButton = {
        let directionsButton = UIButton(type: .custom);
        directionsButton.accessibilityLabel = "directions";
        directionsButton.setImage(UIImage(named: "directions_large"), for: .normal);
        directionsButton.addTarget(self, action: #selector(getDirectionsToObservation), for: .touchUpInside);
        return directionsButton;
    }()
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
        favoriteCount.textColor = currentUserFavorited ? MDCPalette.green.accent700 : scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        favoriteCount.font = scheme.typographyScheme.overline;
        favoriteButton.tintColor = currentUserFavorited ? MDCPalette.green.accent700 : scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        latitudeLongitudeButton.applyTextTheme(withScheme: scheme);
        directionsButton.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
    }
    
    public convenience init(observation: Observation?, observationActionsDelegate: ObservationActionsDelegate?, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.observation = observation;
        self.observationActionsDelegate = observationActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        if let safeObservation = observation {
            populate(observation: safeObservation, delegate: observationActionsDelegate);
        }
        if let safeScheme = self.scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    func layoutView() {
        self.addSubview(actionButtonView);
        actionButtonView.autoSetDimension(.height, toSize: 56);
        actionButtonView.autoPinEdgesToSuperviewEdges();
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            directionsButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 24), excludingEdge: .left);
            favoriteButton.autoPinEdge(.right, to: .left, of: directionsButton, withOffset: -32);
            favoriteButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
            favoriteCount.autoPinEdge(.left, to: .right, of: favoriteButton);
            favoriteCount.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
            
            directionsButton.autoSetDimensions(to: CGSize(width: 24, height: 24));
            favoriteButton.autoSetDimensions(to: CGSize(width: 24, height: 24));
            
            latitudeLongitudeButton.autoAlignAxis(toSuperviewAxis: .horizontal);
            latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .left, withInset: 0);
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    public func populate(observation: Observation!, delegate: ObservationActionsDelegate?) {
        self.observation = observation;
        self.observationActionsDelegate = delegate;
        if (self.observation?.getGeometry() != nil) {
            if let point: SFPoint = self.observation?.getGeometry().centroid() {
                if (UserDefaults.standard.showMGRS) {
                    latitudeLongitudeButton.setTitle(MGRS.mgrSfromCoordinate(CLLocationCoordinate2D.init(latitude: point.y as! CLLocationDegrees, longitude: point.x as! CLLocationDegrees)), for: .normal);
                } else {
                    latitudeLongitudeButton.setTitle(String(format: "%.5f, %.5f", point.y.doubleValue, point.x.doubleValue), for: .normal);
                }
                latitudeLongitudeButton.isEnabled = true;
            }
        } else {
            latitudeLongitudeButton.setTitle("No Location Set", for: .normal);
            latitudeLongitudeButton.isEnabled = false;
        }
        
        currentUserFavorited = false;
        var favoriteCounter = 0;
        if let favorites = observation.favorites {
            let user = User.fetchCurrentUser(in: NSManagedObjectContext.mr_default());
            currentUserFavorited = favorites.contains { (favorite) -> Bool in
                return favorite.userId == user.remoteId && favorite.favorite;
            }
            if (currentUserFavorited) {
                favoriteButton.setImage(UIImage(named: "favorite_large"), for: .normal);
            } else {
                favoriteButton.setImage(UIImage(named: "favorite_border"), for: .normal);
            }
            favorites.forEach { favorite in
                if (favorite.favorite) {
                    favoriteCounter = favoriteCounter + 1
                }
            }
        }
        
        if (favoriteCounter != 0) {
            favoriteCount.text = "\(favoriteCounter)"
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
        observationActionsDelegate?.favoriteObservation?(observation!);
    }
    
    @objc func getDirectionsToObservation() {
        observationActionsDelegate?.getDirectionsToObservation?(observation!);
    }
    
    @objc func copyLocation() {
        observationActionsDelegate?.copyLocation?(latitudeLongitudeButton.currentTitle ?? "No Location");
    }
}

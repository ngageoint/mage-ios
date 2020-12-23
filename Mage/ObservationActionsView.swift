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

protocol ObservationActionsDelegate {
    func showFavorites(_ observation: Observation);
    func favorite(_ observation: Observation);
    func getDirections(_ observation: Observation);
    func makeImportant(_ observation: Observation);
}

class ObservationActionsView: UIView {
    var didSetupConstraints = false;
    var observation: Observation?;
    var observationActionsDelegate: ObservationActionsDelegate?;
    
    var favoriteCountText: NSAttributedString {
        get {
            let favoriteCountText = NSMutableAttributedString();
            if let favoriteCount = observation?.favorites?.count {
                favoriteCountText.append(NSAttributedString(string: "\(favoriteCount)", attributes: favoriteCountAttributes))
                favoriteCountText.append(NSAttributedString(string: favoriteCount == 1 ? " FAVORITE" : " FAVORITES", attributes: favoriteLabelAttributes))
            }
            return favoriteCountText;
        }
    }
    
    private lazy var favoriteCountButton: UIButton = {
        let button = UIButton(type: .custom);
        button.addTarget(self, action: #selector(showFavorites), for: .touchUpInside);
        return button;
    }()
    
    private lazy var favoriteCountAttributes: [NSAttributedString.Key: Any] = {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: globalContainerScheme().typographyScheme.overline,
            .foregroundColor: UIColor.label.withAlphaComponent(0.87)
        ];
        return attributes;
    }()
    
    private lazy var favoriteLabelAttributes: [NSAttributedString.Key: Any] = {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: globalContainerScheme().typographyScheme.overline,
            .foregroundColor: UIColor.label.withAlphaComponent(0.6)
        ];
        return attributes;
    }()
    
    private lazy var favoriteButton: UIButton = {
        let favoriteButton = UIButton(type: .custom);
        favoriteButton.setImage(UIImage(named: "favorite_large"), for: .normal);
        favoriteButton.addTarget(self, action: #selector(favorite), for: .touchUpInside);
        return favoriteButton;
    }()
    
    private lazy var directionsButton: UIButton = {
        let directionsButton = UIButton(type: .custom);
        directionsButton.setImage(UIImage(named: "directions_large"), for: .normal);
        directionsButton.tintColor = UIColor.label.withAlphaComponent(0.6);
        directionsButton.addTarget(self, action: #selector(getDirections), for: .touchUpInside);
        return directionsButton;
    }()
    
    private lazy var importantButton: UIButton = {
        let importantButton = UIButton(type: .custom);
        importantButton.setImage(UIImage(named: "flag"), for: .normal);
        importantButton.addTarget(self, action: #selector(makeImportant), for: .touchUpInside);
        return importantButton;
    }()
    
    override func themeDidChange(_ theme: MageTheme) {
    }
    
    public convenience init(observation: Observation, observationActionsDelegate: ObservationActionsDelegate?) {
        self.init(frame: CGRect.zero);
        self.observation = observation;
        self.observationActionsDelegate = observationActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        populate(observation: observation);
        
        registerForThemeChanges();
    }
    
    func layoutView() {
        self.addSubview(favoriteCountButton);
        self.addSubview(importantButton);
        self.addSubview(directionsButton);
        self.addSubview(favoriteButton);
        
        directionsButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 32), excludingEdge: .left);
        favoriteButton.autoPinEdge(.right, to: .left, of: directionsButton, withOffset: -32);
        favoriteButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
        importantButton.autoPinEdge(.right, to: .left, of: favoriteButton, withOffset: -32);
        importantButton.autoAlignAxis(.horizontal, toSameAxisOf: directionsButton);
        
        favoriteCountButton.autoAlignAxis(toSuperviewAxis: .horizontal);
        favoriteCountButton.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
    }
    
    public func populate(observation: Observation) {
        favoriteCountButton.setAttributedTitle(favoriteCountText, for: .normal);
        importantButton.isHidden = !(self.observation?.currentUserCanUpdateImportant() ?? false);
        
        if (observation.observationImportant != nil) {
            importantButton.tintColor = MDCPalette.orange.accent400;
        } else {
            importantButton.tintColor = UIColor.label.withAlphaComponent(0.6);
        }
        
        favoriteButton.tintColor = UIColor.label.withAlphaComponent(0.6);
        if let favorites = observation.favorites {
            let user = User.fetchCurrentUser(in: NSManagedObjectContext.mr_default());
            let currentUserFavorited = favorites.contains { (favorite) -> Bool in
                return favorite.userId == user.remoteId;
            }
            favoriteButton.tintColor = currentUserFavorited ? MDCPalette.green.accent700 : UIColor.label.withAlphaComponent(0.6);
        }
    }
    
    @objc func showFavorites() {
        observationActionsDelegate?.showFavorites(observation!);
    }
    
    @objc func favorite() {
        observationActionsDelegate?.favorite(observation!);
    }
    
    @objc func getDirections() {
        observationActionsDelegate?.getDirections(observation!);
    }
    
    @objc func makeImportant() {
        observationActionsDelegate?.makeImportant(observation!);
    }
}

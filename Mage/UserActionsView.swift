//
//  UserActionsView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import MaterialComponents.MDCPalettes
import UIKit

class UserActionsView: UIView {
    var didSetupConstraints = false;
    var user: User?;
    var userActionsDelegate: UserActionsDelegate?;
    var bottomSheet: MDCBottomSheetController?;
    internal var scheme: MDCContainerScheming?;
    
    private lazy var actionButtonView: UIStackView = {
        let stack = UIStackView.newAutoLayout()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = 24
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true;
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.addArrangedSubview(latitudeLongitudeButton)
        stack.setCustomSpacing(0, after: latitudeLongitudeButton)
        stack.addArrangedSubview(fillerView)
        stack.setCustomSpacing(0, after: fillerView)
        stack.addArrangedSubview(emailButton);
        stack.addArrangedSubview(phoneButton);
        stack.addArrangedSubview(directionsButton);
        stack.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return stack;
    }()
    
    private lazy var fillerView: UIView = {
        let fillerView = UIView()
        fillerView.setContentHuggingPriority(.defaultHigh, for: .horizontal);
        return fillerView
    }()
    
    private lazy var latitudeLongitudeButton: MDCButton = {
        let button = MDCButton(forAutoLayout: ());
        button.accessibilityLabel = "location";
        button.setImage(UIImage(named: "location_tracking_on")?.resized(to: CGSize(width: 14, height: 14)).withRenderingMode(.alwaysTemplate), for: .normal);
        button.setInsets(forContentPadding: button.defaultContentEdgeInsets, imageTitlePadding: 5);
        button.addTarget(self, action: #selector(copyLocation), for: .touchUpInside);
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.lineBreakMode = .byClipping
        button.titleLabel?.numberOfLines = 1
        return button;
    }()
    
    private lazy var directionsButton: MDCButton = {
        let directionsButton = MDCButton(forAutoLayout: ())
        directionsButton.accessibilityLabel = "directions";
        directionsButton.setImage(UIImage(named: "directions_large")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        directionsButton.addTarget(self, action: #selector(getDirectionsToUser), for: .touchUpInside);
        directionsButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        directionsButton.inkMaxRippleRadius = 30;
        directionsButton.inkStyle = .unbounded;
        directionsButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return directionsButton;
    }()
    
    private lazy var phoneButton: MDCButton = {
        let phoneButton = MDCButton(forAutoLayout: ())
        phoneButton.accessibilityLabel = "phone";
        phoneButton.setImage(UIImage(named: "phone")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        phoneButton.addTarget(self, action: #selector(callUser), for: .touchUpInside);
        phoneButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        phoneButton.inkMaxRippleRadius = 30;
        phoneButton.inkStyle = .unbounded;
        phoneButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return phoneButton;
    }()
    
    private lazy var emailButton: MDCButton = {
        let emailButton = MDCButton(forAutoLayout: ())
        emailButton.accessibilityLabel = "email";
        emailButton.setImage(UIImage(named: "email")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        emailButton.addTarget(self, action: #selector(emailUser), for: .touchUpInside);
        emailButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        emailButton.inkMaxRippleRadius = 30;
        emailButton.inkStyle = .unbounded;
        emailButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return emailButton;
    }()
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme;
        emailButton.applyTextTheme(withScheme: scheme);
        emailButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
        phoneButton.applyTextTheme(withScheme: scheme);
        phoneButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
        directionsButton.applyTextTheme(withScheme: scheme);
        directionsButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
        
        latitudeLongitudeButton.applyTextTheme(withScheme: scheme);
    }
    
    public convenience init(user: User?, userActionsDelegate: UserActionsDelegate?, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.user = user;
        self.userActionsDelegate = userActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        if let user = user {
            populate(user: user, delegate: userActionsDelegate);
        }
        if let scheme = self.scheme {
            applyTheme(withScheme: scheme);
        }
    }
    
    func layoutView() {
        self.addSubview(actionButtonView);
//        self.addSubview(latitudeLongitudeButton);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            actionButtonView.autoSetDimension(.height, toSize: 56);
            actionButtonView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16))//, excludingEdge: .left);

//            latitudeLongitudeButton.autoAlignAxis(toSuperviewAxis: .horizontal);
//            latitudeLongitudeButton.autoPinEdge(toSuperviewEdge: .left, withInset: 0);
//            actionButtonView.autoPinEdge(.left, to: .right, of: latitudeLongitudeButton, withOffset: 8, relation: .greaterThanOrEqual);
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    public func populate(user: User!, delegate: UserActionsDelegate?) {
        self.user = user;
        self.userActionsDelegate = delegate;
        if (self.user?.email == nil) {
            emailButton.isHidden = true;
        } else {
            emailButton.isHidden = false;
        }
        if (self.user?.phone == nil) {
            phoneButton.isHidden = true;
        } else {
            phoneButton.isHidden = false;
        }
        
        if (user.location != nil) {
            let geometry = user.location?.geometry;
            if let point: SFPoint = geometry?.centroid() {
                let coordinate = CLLocationCoordinate2D(latitude: point.y.doubleValue, longitude: point.x.doubleValue)
                latitudeLongitudeButton.setTitle(coordinate.toDisplay(short: true), for: .normal)
            }
            latitudeLongitudeButton.isHidden = false;
        } else {
            latitudeLongitudeButton.isHidden = true;
        }

        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    @objc func getDirectionsToUser(_ sender: UIButton) {
        NotificationCenter.default.post(name: .MapAnnotationFocused, object: nil)
        NotificationCenter.default.post(name: .DismissBottomSheet, object: nil)
        // let the bottom sheet dismiss
        var notification = DirectionsToItemNotification()
        if let cacheIconUrl = user?.cacheIconUrl {
            notification.imageUrl = URL(string: cacheIconUrl)
        }
        notification.user = user
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: .DirectionsToItem, object: notification)
        }
    }
    
    @objc func callUser() {
        guard let number = URL(string: "tel:\(user?.phone ?? "")") else { return }
        UIApplication.shared.open(number)
    }
    
    @objc func emailUser() {
        guard let number = URL(string: "mailto:\(user?.email ?? "")") else { return }
        UIApplication.shared.open(number)
    }
    
    @objc func copyLocation() {
        UIPasteboard.general.string = latitudeLongitudeButton.currentTitle ?? "No Location";
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location \(latitudeLongitudeButton.currentTitle ?? "No Location") copied to clipboard"))
    }
}

//
//  UserTableHeaderView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import CoreData
import Kingfisher

class UserTableHeaderView : UIView, UINavigationControllerDelegate {
    var didSetupConstraints = false;

    var viewWasInitialized = false;
    var userLastLocation: CLLocation?;
    var user: User?;
    var currentUserIsMe: Bool = false;
    var childCoordinators: [Any] = [];
    weak var navigationController: UINavigationController?;
    var scheme: MDCContainerScheming?;
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            avatarImage.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5));
            locationIcon.autoPinEdge(toSuperviewEdge: .leading);
            locationIcon.autoAlignAxis(.horizontal, toSameAxisOf: locationLabel);
            locationLabel.autoPinEdge(.leading, to: .trailing, of: locationIcon, withOffset: 0);
            locationLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), excludingEdge: .leading);
            phoneIcon.autoPinEdge(toSuperviewEdge: .leading);
            phoneIcon.autoAlignAxis(.horizontal, toSameAxisOf: phoneLabel);
            phoneLabel.autoPinEdge(.leading, to: .trailing, of: phoneIcon, withOffset: 0);
            phoneLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), excludingEdge: .leading);
            emailIcon.autoPinEdge(toSuperviewEdge: .leading);
            emailIcon.autoAlignAxis(.horizontal, toSameAxisOf: emailLabel);
            emailLabel.autoPinEdge(.leading, to: .trailing, of: emailIcon, withOffset: 0);
            emailLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), excludingEdge: .leading);
            
            mapView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), excludingEdge: .bottom);
            avatarBorder.autoPinEdge(toSuperviewEdge: .leading, withInset: 8);
            avatarBorder.autoPinEdge(.top, to: .bottom, of: mapView, withOffset: -32);
            stack.autoPinEdge(.top, to: .bottom, of: avatarBorder, withOffset: 4);
            stack.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8), excludingEdge: .top);
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        self.scheme = containerScheme;
        guard let scheme = self.scheme else {
            return
        }
        self.backgroundColor = scheme.colorScheme.backgroundColor;
        
        avatarBorder.backgroundColor = scheme.colorScheme.backgroundColor;
        avatarImage.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        nameField.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        
        locationIcon.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        locationLabel.textColor = scheme.colorScheme.primaryColor;
        locationLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor : scheme.colorScheme.primaryColor];
        
        emailIcon.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        emailLabel.textColor = scheme.colorScheme.primaryColor;
        emailLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor : scheme.colorScheme.primaryColor];
        
        phoneIcon.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        phoneLabel.textColor = scheme.colorScheme.primaryColor;
        phoneLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor : scheme.colorScheme.primaryColor];
    }
    
    private lazy var mapDelegate: MapDelegate = {
        let mapDelegate: MapDelegate = MapDelegate();
        return mapDelegate;
    }()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView(forAutoLayout: ());
        mapView.autoSetDimension(.height, toSize: 150);
        mapView.delegate = mapDelegate;
        mapDelegate.mapView = mapView;
        return mapView;
    }()
    
    private lazy var avatarBorder: UIView = {
        let border = UIView(forAutoLayout: ());
        border.autoSetDimensions(to: CGSize(width: 80, height: 80));
        border.addSubview(avatarImage);
        border.layer.cornerRadius = 4.0;
        
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(portraitClick));
        singleTap.numberOfTapsRequired = 1;
        border.addGestureRecognizer(singleTap);
        return border;
    }()
    
    private lazy var avatarImage: UserAvatarUIImageView = {
        let avatarImage = UserAvatarUIImageView(image: nil);
        return avatarImage;
    }()
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true;
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.addArrangedSubview(nameField);
        stack.addArrangedSubview(locationView);
        stack.addArrangedSubview(phoneView);
        stack.addArrangedSubview(emailView);
        return stack;
    }()
    
    private lazy var nameField: UILabel = {
        let nameField = UILabel(forAutoLayout: ());
        nameField.accessibilityLabel = "name";
        nameField.font = UIFont.systemFont(ofSize: 18.0, weight: .bold);
        nameField.textColor = UIColor.label.withAlphaComponent(0.87);
        nameField.autoSetDimension(.height, toSize: 24);
        return nameField;
    }()
    
    private lazy var locationIcon: UITextView = {
        let locationIcon = UITextView(forAutoLayout: ());
        locationIcon.autoSetDimensions(to: CGSize(width: 24, height: 24));
        locationIcon.font = UIFont(name: "FontAwesome", size: 15);
        locationIcon.text = "\u{0000f0ac}";
        locationIcon.backgroundColor = UIColor.clear;
        return locationIcon;
    }()
    
    private lazy var locationView: UIView = {
        let locationView = UIView(forAutoLayout: ());
        locationView.backgroundColor = UIColor.clear;
        locationView.addSubview(locationIcon);
        locationView.addSubview(locationLabel);
        
        let singleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(launchMapApp));
        singleTap.numberOfTapsRequired = 1;
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(launchMapApp));
        
        locationLabel.addGestureRecognizer(singleTap);
        locationLabel.addGestureRecognizer(longPress);
        
        return locationView;
    }()
    
    private lazy var locationLabel: UITextView = {
        let locationLabel = UITextView(forAutoLayout: ());
        locationLabel.autoSetDimension(.height, toSize: 30);
        locationLabel.backgroundColor = UIColor.clear;
        locationLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular);
        locationLabel.isEditable = false;
        locationLabel.dataDetectorTypes = .all;
        locationLabel.textContentType = .location;
        locationLabel.accessibilityLabel = "location";
        return locationLabel;
    }()
    
    private lazy var phoneIcon: UITextView = {
        let phoneIcon = UITextView(forAutoLayout: ());
        phoneIcon.autoSetDimensions(to: CGSize(width: 24, height: 24));
        phoneIcon.font = UIFont(name: "FontAwesome", size: 15);
        phoneIcon.text = "\u{0000f095}";
        phoneIcon.backgroundColor = UIColor.clear;
        return phoneIcon;
    }()
    
    private lazy var phoneView: UIView = {
        let phoneView = UIView(forAutoLayout: ());
        phoneView.backgroundColor = UIColor.clear;
       
        phoneView.addSubview(phoneIcon);
        phoneView.addSubview(phoneLabel);

        return phoneView;
    }()
    
    private lazy var phoneLabel: UITextView = {
        let phoneLabel = UITextView(forAutoLayout: ());
        phoneLabel.autoSetDimension(.height, toSize: 30);
        phoneLabel.backgroundColor = UIColor.clear;
        phoneLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular);
        phoneLabel.dataDetectorTypes = .phoneNumber;
        phoneLabel.textContentType = .telephoneNumber;
        phoneLabel.isEditable = false;
        phoneLabel.accessibilityLabel = "phone";
        return phoneLabel;
    }()
    
    private lazy var emailIcon: UITextView = {
        let emailIcon = UITextView(forAutoLayout: ());
        emailIcon.autoSetDimensions(to: CGSize(width: 24, height: 24));
        emailIcon.font = UIFont(name: "FontAwesome", size: 15);
        emailIcon.text = "\u{0000f0e0}";
        emailIcon.backgroundColor = UIColor.clear;
        return emailIcon;
    }()
    
    private lazy var emailView: UIView = {
        let emailView = UIView(forAutoLayout: ());
        emailView.backgroundColor = UIColor.clear;
        
        emailView.addSubview(emailIcon);
        emailView.addSubview(emailLabel);
        return emailView;
    }()
    
    private lazy var emailLabel: UITextView = {
        let emailLabel = UITextView(forAutoLayout: ());
        emailLabel.autoSetDimension(.height, toSize: 30);
        emailLabel.backgroundColor = UIColor.clear;
        emailLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular);
        emailLabel.dataDetectorTypes = .all;
        emailLabel.textContentType = .emailAddress;
        emailLabel.isEditable = false;
        emailLabel.accessibilityLabel = "email";
        return emailLabel;
    }()
    
    @objc public convenience init(user: User, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.configureForAutoLayout();
        layoutView();
        applyTheme(withContainerScheme: self.scheme);
        populate(user: user);
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserDefaults(notification:)), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self);
        self.mapDelegate.cleanup();
        self.mapView.delegate = nil;
    }
    
    func layoutView() {
        if (viewWasInitialized) {
            return;
        }
        self.addSubview(mapView);
        self.addSubview(avatarBorder);
        self.addSubview(stack);
        
        viewWasInitialized = true;
    }
    
    func start() {
        mapDelegate.setupListeners();
        mapDelegate.allowEnlarge = false;
        mapDelegate.observations = Observations.init(for: user);
        mapDelegate.locations = Locations.init(for: user);
        
        if (currentUserIsMe) {
            let locations: [GPSLocation] = GPSLocation.fetchGPSLocations(limit: 1, context: NSManagedObjectContext.mr_default())
            if (locations.count != 0) {
                let location: GPSLocation = locations[0]
                let centroid: SFPoint = SFGeometryUtils.centroid(of: location.geometry);
                let dictionary: [String : Any] = location.properties as! [String : Any];
                userLastLocation = CLLocation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: centroid.y as! CLLocationDegrees,
                        longitude: centroid.x as! CLLocationDegrees),
                    altitude: dictionary["altitude"] as! CLLocationDistance,
                    horizontalAccuracy: dictionary["accuracy"] as! CLLocationAccuracy,
                    verticalAccuracy: dictionary["accuracy"] as!CLLocationAccuracy,
                    timestamp: location.timestamp!);
                self.mapDelegate.update(location, for: user);
            }
            
        }
        if (userLastLocation == nil) {
            if let locations = mapDelegate.locations.fetchedResultsController.fetchedObjects {
                if (locations.count != 0) {
                    let location: Location = locations[0] as Location
                    let dictionary: [String : Any] = location.properties as! [String : Any];
                    userLastLocation = CLLocation(
                        coordinate: location.location().coordinate,
                        altitude: dictionary["altitude"] as? CLLocationDistance ?? 0.0,
                        horizontalAccuracy: dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0,
                        verticalAccuracy: dictionary["accuracy"] as? CLLocationAccuracy ?? 0.0,
                        timestamp: location.timestamp!);
                }
            }
            mapDelegate.locations.fetchedResultsController.delegate = self;
        }
        
        if (userLastLocation != nil) {
            setLocationText(userLastLocation: userLastLocation!);
            locationView.isHidden = false;
            zoomAndCenterMap(location: userLastLocation!);
        } else {
            locationView.isHidden = true;
        }
    }
    
    func stop() {
        mapDelegate.cleanup();
    }
    
    @objc public func populate(user: User) {
        layoutView();
        self.user = user;
        currentUserIsMe = UserDefaults.standard.currentUserId == user.remoteId;
        
        nameField.text = user.name;
        
        phoneLabel.text = user.phone;
        phoneView.isHidden = user.phone == nil ? true : false;
        
        emailLabel.text = user.email;
        emailView.isHidden = user.email == nil ? true : false;
        
        self.avatarImage.kf.indicatorType = .activity;
        avatarImage.setUser(user: user);
        let cacheOnly = DataConnectionUtilities.shouldFetchAvatars();
        avatarImage.showImage(cacheOnly: cacheOnly);
    }
    
    func zoomAndCenterMap(location: CLLocation) {
        let latitudeMeters: CLLocationDistance = location.horizontalAccuracy * 2.5;
        let longitudeMeters: CLLocationDistance = location.horizontalAccuracy * 2.5;
        let region: MKCoordinateRegion = mapView.regionThatFits(MKCoordinateRegion(center: location.coordinate, latitudinalMeters: latitudeMeters, longitudinalMeters: longitudeMeters));
        mapDelegate.selectedUser(self.user, region: region);
    }
    
    @objc public func updateUserDefaults(notification: Notification) {
        if let userLastLocation = userLastLocation {
            setLocationText(userLastLocation: userLastLocation);
        }
    }

    func setLocationText(userLastLocation: CLLocation) {
        let location = CoordinateDisplay.displayFromCoordinate(coordinate: userLastLocation.coordinate);
        
        let locationFont = UIFont.systemFont(ofSize: 14);
        let accuracyFont = UIFont.systemFont(ofSize: 11);
        
        let locationText = NSMutableAttributedString();
        locationText.append(NSAttributedString(string: location, attributes: [NSAttributedString.Key.font:locationFont, NSAttributedString.Key.foregroundColor: self.scheme?.colorScheme.primaryColor ?? .label]));
        locationText.append(NSAttributedString(string: String(format: "  GPS +/- %.02fm", userLastLocation.horizontalAccuracy), attributes: [NSAttributedString.Key.font:accuracyFont, NSAttributedString.Key.foregroundColor: (self.scheme?.colorScheme.onSurfaceColor ?? .label).withAlphaComponent(0.6)]));
        
        self.locationLabel.attributedText = locationText;
    }
    
    func getLaunchableUrls() -> [String: URL?] {
        let appleMapsQueryString: String = "ll=\(userLastLocation?.coordinate.latitude ?? 0),\(userLastLocation?.coordinate.longitude ?? 0)&q=\(user?.name ?? "User")";
        let appleMapsQueryStringEncoded: String = appleMapsQueryString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "";
        let appleMapsUrl = URL(string: "http://maps.apple.com/?\(appleMapsQueryStringEncoded)");
        
        let googleMapsUrl = URL(string:"https://www.google.com/maps/dir/?api=1&destination=\(userLastLocation?.coordinate.latitude ?? 0),\(userLastLocation?.coordinate.longitude ?? 0)");
        
        var urlMap : [String: URL?] = ["Apple Maps": appleMapsUrl];
        if (googleMapsUrl != nil && UIApplication.shared.canOpenURL(googleMapsUrl!)) {
            urlMap["Google Maps"] = googleMapsUrl;
        }
        return urlMap;
    }
    
    @objc func launchMapApp() {
        let urlMap = getLaunchableUrls();
        if (urlMap.count > 1) {
            presentMapsActionSheetForURLs(urlMap: urlMap);
        } else {
            if let url = urlMap["Apple Maps"] {
                UIApplication.shared.open(url!, options: [:]) { (success) in
                    print("Opened \(success)")
                }
            }
        }
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
    
    func presentMapsActionSheetForURLs(urlMap: [String: URL?]) {
        let alert = UIAlertController(title: "Navigate With...", message: nil, preferredStyle: .actionSheet);
        alert.addAction(UIAlertAction(title: "Copy To Clipboard", style: .default, handler: { (action) in
            if let coordinate = self.userLastLocation?.coordinate {
                UIPasteboard.general.string = CoordinateDisplay.displayFromCoordinate(coordinate: coordinate);
                MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location copied to clipboard"))
            }
        }));
        for (app, url) in urlMap {
            if let url = url {
                alert.addAction(UIAlertAction(title: app, style: .default, handler: { (action) in
                    UIApplication.shared.open(url, options: [:]) { (success) in
                        print("Opened \(success)")
                    }
                }));
            }
        }
        alert.addAction(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            guard let location: CLLocationCoordinate2D = self.user?.location?.location().coordinate else {
                return;
            }
            var image: UIImage? = UIImage(named: "me")
            if let iconUrl = self.user?.iconUrl {
                let lastUpdated = String(format:"%.0f", (self.user?.lastUpdated?.timeIntervalSince1970.rounded() ?? 0))
                let url = URL(string: "\(iconUrl)?_lastUpdated=\(lastUpdated)")!;

                KingfisherManager.shared.retrieveImage(with: url, options: [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ]) { result in
                    switch result {
                    case .success(let value):
                        let scale = value.image.size.width / 37;
                        image = UIImage(cgImage: value.image.cgImage!, scale: scale, orientation: value.image.imageOrientation);
                    case .failure(_):
                        image = UIImage.init(named: "me")?.withRenderingMode(.alwaysTemplate);
                    }
                    NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: image, coordinate: location, user: self.user))
                }
            } else {
                NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: image, coordinate: location, user: self.user))
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self
            popoverController.sourceRect = CGRect(x: self.bounds.midX, y: self.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.present(alert, animated: true, completion: nil)

    }
}

extension UserTableHeaderView : UIImagePickerControllerDelegate {
    
    func presentAvatar() {
        if let avatarUrl = user?.avatarUrl {
            let lastUpdated = String(format:"%.0f", (user?.lastUpdated?.timeIntervalSince1970.rounded() ?? 0))
            let url = URL(string: "\(avatarUrl)?_lastUpdated=\(lastUpdated)")!;
            if let saveNavigationController = navigationController {
                let coordinator: AttachmentViewCoordinator = AttachmentViewCoordinator(rootViewController: saveNavigationController, url: url, contentType: "image", delegate: nil, scheme: scheme);
                childCoordinators.append(coordinator);
                coordinator.start();
            }
        }
    }
    
    @objc func portraitClick() {
        if (!currentUserIsMe) {
            presentAvatar();
            return;
        }
        
        let alert = UIAlertController(title: "Avatar", message: "Change or view your avatar", preferredStyle: .actionSheet);
        alert.addAction(UIAlertAction(title: "View Avatar", style: .default, handler: { (action) in
            self.presentAvatar();
        }));
        alert.addAction(UIAlertAction(title: "New Avatar Photo", style: .default, handler: { (action) in
            ExternalDevice.checkCameraPermissions(for: self.navigationController) { (granted) in
                let picker = UIImagePickerController();
                picker.delegate = self;
                picker.allowsEditing = true;
                picker.sourceType = .camera;
                picker.cameraDevice = .front;
                self.navigationController?.present(picker, animated: true, completion: nil);
            }
        }));
        alert.addAction(UIAlertAction(title: "New Avatar From Gallery", style: .default, handler: { (action) in
            ExternalDevice.checkGalleryPermissions(for: self.navigationController) { (granted) in
                let picker = UIImagePickerController();
                picker.delegate = self;
                picker.allowsEditing = true;
                picker.sourceType = .photoLibrary;
                self.navigationController?.present(picker, animated: true, completion: nil);
            }
        }));
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil));

        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self
            popoverController.sourceRect = CGRect(x: self.bounds.midX, y: self.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController?.presentedViewController?.present(alert, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil);
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let chosenImage: UIImage = info[.editedImage] as? UIImage {
            avatarImage.image = chosenImage;
            if let imageData = chosenImage.jpegData(compressionQuality: 1.0) {
                let documentsDirectories: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                if (documentsDirectories.count != 0 && FileManager.default.fileExists(atPath: documentsDirectories[0])) {
                    let userAvatarPath = "\(documentsDirectories[0])/userAvatars/\(user?.remoteId ?? "temp")";
                    do {
                        try imageData.write(to: URL(fileURLWithPath: userAvatarPath))
                    } catch {
                        print("Could not write image file to destination")
                    }
                }
                
                picker.dismiss(animated: true, completion: nil);
                
                let manager = MageSessionManager.shared();
                let url = "\(MageServer.baseURL()!.absoluteString)/api/users/myself";
                if let request: URLRequest = manager?.httpRequestSerializer()?.multipartFormRequest(withMethod: "PUT", urlString: url, parameters: nil, constructingBodyWith: { (formData) in
                    formData.appendPart(withFileData: imageData, name: "avatar", fileName: "avatar.jpeg", mimeType: "image/jpeg")
                }, error: nil) as URLRequest? {
                
                    if let uploadTask: URLSessionUploadTask = manager?.uploadTask(withStreamedRequest: request, progress: nil, completionHandler: { (response, responseObject, error) in
                        // store the image data for the updated avatar in the cache here
                        if let avatarUrl = (responseObject as? [AnyHashable: Any])?["avatarUrl"], let image = UIImage(data: imageData) {
                            let lastUpdated = String(format:"%.0f", (self.user?.lastUpdated?.timeIntervalSince1970.rounded() ?? 0))
                            let url = URL(string: "\(avatarUrl)?_lastUpdated=\(lastUpdated)")!;
                            ImageCache.default.store(image, original:imageData, forKey: url.absoluteString)
                        }
                    }) as URLSessionUploadTask? {
                        manager?.addTask(uploadTask);
                    }
                }
            }
        }
    }
    
}

extension UserTableHeaderView : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let locations: [Location] = mapDelegate.locations.fetchedResultsController.fetchedObjects {
            self.mapDelegate.updateLocations(locations);
            if (locations.count != 0) {
                let centroid: SFPoint = SFGeometryUtils.centroid(of: locations[0].getGeometry());
                let location: CLLocation = CLLocation(latitude: centroid.y as! CLLocationDegrees, longitude: centroid.x as! CLLocationDegrees);
                zoomAndCenterMap(location: location);
            }
        }
        
    }
}


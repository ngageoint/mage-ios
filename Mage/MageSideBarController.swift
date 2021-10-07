//
//  MageTabBarController.m
//  MAGE
//
//

import Foundation
import Kingfisher
import PureLayout

class SidebarUIButton: UIButton {
    
    public enum SidebarType: String {
        case observations, locations, feed
    }
    
    var feed: Feed?
    var sidebarType: SidebarType?
    var viewController: UIViewController?
    var title: String?
}

@objc class MageSideBarController : UIViewController {
    
    var activeButton: SidebarUIButton?;
    var scheme: MDCContainerScheming?;
    
    typealias Delegate = AttachmentSelectionDelegate & ObservationSelectionDelegate & UserActionsDelegate & UserSelectionDelegate & FeedItemSelectionDelegate & ObservationActionsDelegate
    @objc public var delegate: Delegate?;
    
    private lazy var railScroll : UIScrollView = {
        let scroll : UIScrollView = UIScrollView(forAutoLayout: ());
        scroll.addSubview(navigationRail);
        navigationRail.autoPinEdge(toSuperviewEdge: .left);
        navigationRail.autoPinEdge(toSuperviewEdge: .right);
        return scroll;
    }()
    
    private lazy var border : UIView = {
        let border : UIView = UIView(forAutoLayout: ());
        border.autoSetDimension(.width, toSize: 1.0);
        border.backgroundColor = UIColor(white: 0.0, alpha: 0.2);
        return border;
    }()
    
    private lazy var dataContainer : UIView = {
        let container : UIView = UIView(forAutoLayout: ());
        return container;
    }()
    
    private lazy var navigationRail : UIStackView = {
        let rail : UIStackView = UIStackView(forAutoLayout: ());
        rail.axis = .vertical
        rail.alignment = .fill
        rail.spacing = 0
        rail.distribution = .fill
        rail.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        rail.isLayoutMarginsRelativeArrangement = true;
        rail.translatesAutoresizingMaskIntoConstraints = false;
        
        return rail;
    }()
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
        self.scheme = containerScheme;
        navigationRail.backgroundColor = containerScheme.colorScheme.surfaceColor;
        view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        railScroll.backgroundColor = containerScheme.colorScheme.surfaceColor;
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc convenience public init(containerScheme: MDCContainerScheming) {
        self.init(frame: CGRect.zero);
        self.scheme = containerScheme;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        view.addSubview(railScroll);
        railScroll.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), excludingEdge: .right);
        railScroll.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0);
        railScroll.autoSetDimension(.height, toSize: view.frame.size.height);
        railScroll.autoSetDimension(.width, toSize: 56);
        railScroll.contentSize = navigationRail.frame.size;
        railScroll.autoresizingMask = UIView.AutoresizingMask.flexibleHeight;
        
        view.addSubview(border);
        border.autoPinEdge(.leading, to: .trailing, of: railScroll);
        border.autoPinEdge(.top, to: .top, of: railScroll);
        border.autoMatch(.height, to: .height, of: railScroll);
        
        view.addSubview(dataContainer);
        dataContainer.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), excludingEdge: .left);
        dataContainer.autoPinEdge(.left, to: .right, of: border);
        
        createRailItems();
        applyTheme(withContainerScheme: self.scheme);
    }
    
    func activateSidebarDataController(viewController: UIViewController?, title: String?) {
        guard let controller = viewController else {
            return;
        }
        self.title = title;
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        if (dataContainer.subviews.count != 0) {
            dataContainer.subviews[0].removeFromSuperview();
        }
        dataContainer.addSubview(controller.view)
        controller.view.autoPinEdgesToSuperviewEdges();
        
        controller.didMove(toParent: self)
    }
    
    func createRailItem(sidebarType: SidebarUIButton.SidebarType, title: String?, iconUrl: URL? = nil, imageName: String? = nil) -> SidebarUIButton {
        let size = 24;
        let button : SidebarUIButton = SidebarUIButton(forAutoLayout: ());
        button.autoSetDimensions(to: CGSize(width: 56, height: 56));
        button.tintColor = self.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        button.sidebarType = sidebarType;
        button.title = title;
        
        if let safeUrl: URL = iconUrl {
            let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size));
            button.kf.setImage(
                with: safeUrl,
                for: .normal,
                placeholder: UIImage(named: "rss"),
                options: [
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ], completionHandler:  { result in
                    switch result {
                    case .success(let value):
                        var image: UIImage = value.image.aspectResize(to: CGSize(width: size, height: size));
                        image = image.withRenderingMode(.alwaysTemplate);
                        button.setImage(image, for: .normal)
                    case .failure(let error):
                        print(error);
                    }
                })
        } else if let safeImageName: String = imageName {
            button.setImage(UIImage(named: safeImageName), for: .normal);
        }
        
        return button;
    }
    
    func createRailItems() {
        let observationButton: SidebarUIButton = createObservationsRailView();
        let locationButton: SidebarUIButton = createLocationsRailView();
        
        var allRailItems: [SidebarUIButton] = [observationButton, locationButton];

        for feed in Feed.mr_findAll()! as! [Feed] {
            let feedButton: SidebarUIButton = createFeedRailView(feed: feed);
            feedButton.feed = feed;
            allRailItems.append(feedButton);
        }

        for view in allRailItems {
            navigationRail.addArrangedSubview(view);
        }
        activateButton(button: allRailItems[0])
    }
    
    func createLocationsRailView() -> SidebarUIButton {
        let locationButton: SidebarUIButton = createRailItem(sidebarType: SidebarUIButton.SidebarType.locations, title: "People", imageName: "people");
        locationButton.addTarget(self, action: #selector(activateButton(button:)), for: .touchUpInside);
        let locationViewController : LocationsTableViewController = LocationsTableViewController(scheme: self.scheme);
//        locationViewController.actionsDelegate = delegate;
        locationButton.viewController = locationViewController;
        return locationButton;
    }

    func createObservationsRailView() -> SidebarUIButton {
        let observationButton: SidebarUIButton = createRailItem(sidebarType: SidebarUIButton.SidebarType.observations, title: "Observations", imageName: "observations");
        observationButton.addTarget(self, action: #selector(activateButton(button:)), for: .touchUpInside);
//        let observationViewController : ObservationTableViewController = ObservationTableViewController(attachmentDelegate: delegate, observationActionsDelegate: delegate, scheme: self.scheme);
        let observationViewController : ObservationTableViewController = ObservationTableViewController(scheme: self.scheme);
        observationButton.viewController = observationViewController;
        return observationButton;
    }
    
    func createFeedRailView(feed: Feed) -> SidebarUIButton {
        let feedButton: SidebarUIButton = createRailItem(sidebarType: SidebarUIButton.SidebarType.feed, title: feed.title, iconUrl: feed.iconURL, imageName: "rss");
        feedButton.feed = feed;
        feedButton.addTarget(self, action: #selector(activateButton(button:)), for: .touchUpInside);
        let feedItemsViewController: FeedItemsViewController = FeedItemsViewController(feed: feed, selectionDelegate: delegate, scheme: self.scheme);
        feedButton.viewController = feedItemsViewController;
        return feedButton;
    }
    
    @objc func activateButton(button: SidebarUIButton) {
        if let safeButton = activeButton {
            safeButton.tintColor = self.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        }
        button.tintColor = self.scheme?.colorScheme.primaryColor;
        activeButton = button;
        activateSidebarDataController(viewController: button.viewController, title: button.title);
    }
    
    @objc func observationButtonTapped(sender: SidebarUIButton) {
        activateButton(button: sender);
    }
    
    @objc func locationButtonTapped(sender: SidebarUIButton) {
        activateButton(button: sender);
    }
    
    @objc func feedButtonTapped(sender: SidebarUIButton) {
        activateButton(button: sender);

    }
}

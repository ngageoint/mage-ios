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
    
    typealias Delegate = AttachmentSelectionDelegate & ObservationSelectionDelegate & UserSelectionDelegate & FeedItemSelectionDelegate
    @objc public var delegate: Delegate?;
    
    private lazy var railScroll : UIScrollView = {
        let scroll : UIScrollView = UIScrollView(forAutoLayout: ());
        scroll.addSubview(navigationRail);
        navigationRail.autoPinEdge(toSuperviewEdge: .left);
        navigationRail.autoPinEdge(toSuperviewEdge: .right);
        scroll.backgroundColor = .white;
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
        container.backgroundColor = .red;
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
        rail.backgroundColor = .white;
        return rail;
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad();
        view.backgroundColor = .white;
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
        button.tintColor = .inactiveTabIcon();
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
            ]) { result in
                switch result {
                case .success(let value):
                    var image: UIImage = value.image.aspectResize(to: CGSize(width: size, height: size));
                    image = image.withRenderingMode(.alwaysTemplate);
                    button.setImage(image, for: .normal)
                case .failure(let error):
                    print(error);
                }
            }
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
        let locationViewController : LocationTableViewController = LocationTableViewController();
        locationViewController.delegate = delegate;
        locationButton.viewController = locationViewController;
        return locationButton;
    }

    func createObservationsRailView() -> SidebarUIButton {
        let observationButton: SidebarUIButton = createRailItem(sidebarType: SidebarUIButton.SidebarType.observations, title: "Observations", imageName: "observations");
        observationButton.addTarget(self, action: #selector(activateButton(button:)), for: .touchUpInside);
        let observationViewController : ObservationTableViewController = ObservationTableViewController(scheme: MAGEScheme.scheme());
        observationButton.viewController = observationViewController;
        observationViewController.observationSelectionDelegate = delegate;
        observationViewController.attachmentDelegate = delegate;
        return observationButton;
    }
    
    func createFeedRailView(feed: Feed) -> SidebarUIButton {
        let feedButton: SidebarUIButton = createRailItem(sidebarType: SidebarUIButton.SidebarType.feed, title: feed.title, iconUrl: feed.iconURL(), imageName: "rss");
        feedButton.feed = feed;
        feedButton.addTarget(self, action: #selector(activateButton(button:)), for: .touchUpInside);
        let feedItemsViewController: FeedItemsViewController = FeedItemsViewController(feed: feed, selectionDelegate: delegate);
        feedButton.viewController = feedItemsViewController;
        return feedButton;
    }
    
    @objc func activateButton(button: SidebarUIButton) {
        if let safeButton = activeButton {
            safeButton.tintColor = UIColor.inactiveTabIcon();
        }
        button.tintColor = UIColor.activeTabIcon();
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

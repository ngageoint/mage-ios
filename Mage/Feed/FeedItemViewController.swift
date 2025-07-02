//
//  FeedItemViewViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 6/15/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit
import PureLayout

private final class IntrinsicTableView: UITableView {
    
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
    
}

@objc class FeedItemViewController : UIViewController {
    var didSetupConstraints = false

    let HEADER_SECTION = 0
    let PROPERTIES_SECTION = 1
    
    let cellReuseIdentifier = "propertyCell"
    let headerCellIdentifier = "headerCell"
    
    var scheme: AppContainerScheming?
    
    var feedItem : FeedItem?
    var properties: [String: Any]?
    let propertiesHeader: CardHeader = CardHeader(headerText: "PROPERTIES")
    
    private lazy var propertiesCard: UIView = {
        let card = UIView()
        card.addSubview(tableView)
        return card
    }()
    
    private lazy var tableView : IntrinsicTableView = {
        let tableView = IntrinsicTableView(frame: CGRect.zero, style: .plain)
        tableView.allowsSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(FeedItemPropertyCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        return tableView
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.newAutoLayout()
        scrollView.accessibilityIdentifier = "card scroll"
        scrollView.contentInset.bottom = 100
        return scrollView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView.newAutoLayout()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    override func updateViewConstraints() {
        if (!didSetupConstraints) {
            scrollView.autoPinEdgesToSuperviewEdges(with: .zero)
            stackView.autoPinEdgesToSuperviewEdges()
            stackView.autoMatch(.width, to: .width, of: view)
            tableView.autoPinEdgesToSuperviewEdges()
            propertiesCard.autoMatch(.height, to: .height, of: tableView)
            didSetupConstraints = true
        }
        
        super.updateViewConstraints()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc convenience public init(feedItem:FeedItem, scheme: AppContainerScheming?) {
        self.init(frame: CGRect.zero)
        self.scheme = scheme
        self.feedItem = feedItem
        self.properties = feedItem.properties as? [String: Any]
        self.applyTheme(withScheme: scheme)
    }
    
    override func loadView() {
        view = UIView()
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.setNeedsUpdateConstraints()
    }
    
    public func applyTheme(withScheme scheme: AppContainerScheming? = nil) {
        guard let scheme = scheme else {
            return
        }

        self.view.backgroundColor = scheme.colorScheme.backgroundColor
        propertiesHeader.applyTheme(withScheme: scheme)
//        propertiesCard.applyTheme(withScheme: scheme)
        tableView.backgroundColor = .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cell: FeedItemCard = FeedItemCard(item: feedItem, actionsDelegate: self, hideSummaryImage: true)
        cell.applyTheme(withScheme: self.scheme)
        
        self.stackView.addArrangedSubview(cell)
        self.stackView.addArrangedSubview(propertiesHeader)
        self.stackView.addArrangedSubview(propertiesCard)
    }
}

extension FeedItemViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension FeedItemViewController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return properties?.count ?? 0
    }

    func numberOfSections(in: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: FeedItemPropertyCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! FeedItemPropertyCell
        cell.applyTheme(withScheme: self.scheme)

        let key = properties?.keys.sorted()[indexPath.row] ?? ""

        if let itemPropertiesSchema = feedItem?.feed?.itemPropertiesSchema as? [String : Any], let propertySchema = itemPropertiesSchema["properties"] as? [String : Any], let keySchema = propertySchema[key] as? [String : Any] {
            cell.keyField.text = keySchema["title"] as? String
        } else {
            cell.keyField.text = key
        }

        cell.valueField.text = feedItem?.valueForKey(key: key) ?? ""
        return cell
    }
}

extension FeedItemViewController: FeedItemActionsDelegate {
    
    func getDirectionsToFeedItem(_ feedItem: FeedItem, sourceView: UIView? = nil) {
        var extraActions: [UIAlertAction] = []
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in
            
            // TODO: BRENT - MAKE THESE COLORS CORRECT
            var image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: NamedColorTheme().colorScheme.primaryColor ?? UIColor.magenta)
            if let url: URL = feedItem.iconURL {
                let size = 24
                
                let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
                KingfisherManager.shared.retrieveImage(with: url, options: [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ]) { result in
                    switch result {
                    case .success(let value):
                        image = value.image.aspectResize(to: CGSize(width: size, height: size))
                    case .failure(_):
                        // TODO: BRENT - MAKE THESE COLORS CORRECT
                        image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: NamedColorTheme().colorScheme.primaryColor ?? UIColor.magenta)
                    }
                }
            }
            
            NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: image, coordinate: feedItem.coordinate))
        }))
        ObservationActionHandler.getDirections(latitude: feedItem.coordinate.latitude, longitude: feedItem.coordinate.longitude, title: feedItem.title ?? "Feed item", viewController: self, extraActions: extraActions, sourceView: sourceView)
    }
    
    func copyLocation(_ location: String) {
        UIPasteboard.general.string = location
        AlertManager.shared.show(title: "Location Copied", message: "Location \(location) copied to clipboard")
    }
}

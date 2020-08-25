//
//  FeedItemViewViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 6/15/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

infix operator ???: NilCoalescingPrecedence

public func ???<T>(optional: T?, defaultValue: @autoclosure () -> String) -> String {
    switch optional {
    case let value?: return String(describing: value)
    case nil: return defaultValue()
    }
}

@objc class FeedItemViewController : UITableViewController {
    let HEADER_SECTION = 0;
    let PROPERTIES_SECTION = 1;
    
    let cellReuseIdentifier = "propertyCell"
    let temporalCellReuseIdentifer = "temporalCell";
    let headerCellIdentifier = "headerCell"
    
    let feedItem : FeedItem
    let properties: [String: Any]?
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public init(feedItem:FeedItem) {
        self.feedItem = feedItem
        self.properties = feedItem.properties as? [String: Any];
        super.init(style: .grouped)
        tableView.allowsSelection = false;
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FeedItemCard.self, forCellReuseIdentifier: headerCellIdentifier)
        tableView.register(FeedItemPropertyCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == HEADER_SECTION) {
            return 1;
        } else {
            return properties?.count ?? 0;
        }
    }
    
    override func numberOfSections(in: UITableView) -> Int {
        return 2;
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView();
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.section == HEADER_SECTION) {
            let cell: FeedItemCard = tableView.dequeueReusableCell(withIdentifier: headerCellIdentifier, for: indexPath) as! FeedItemCard;
            cell.bind(feedItem: feedItem);
            return cell;
        }
        
        let cell: FeedItemPropertyCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! FeedItemPropertyCell;
        
        let key = properties?.keys.sorted()[indexPath.row] ?? ""
        let value = properties?[key];
        
        cell.keyField.text = key;
        if (feedItem.feed?.itemTemporalProperty == key) {
            if let itemDate: NSDate = feedItem.timestamp as NSDate? {
                cell.valueField.text = itemDate.formattedDisplay();
            }
        } else if (value is Date) {
            cell.valueField.text = (value as? NSDate)!.formattedDisplay();
        } else {
            cell.valueField.text = value ??? " "
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension;
    }
}

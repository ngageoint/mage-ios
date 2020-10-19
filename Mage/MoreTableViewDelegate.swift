//
//  MoreTableViewDelegate.swift
//  MAGE
//
//  Created by William Newman on 8/27/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

class MoreTableViewDelegate : NSObject, UITableViewDelegate {
    var proxyDelegate: UITableViewDelegate
    
    init(proxyDelegate delegate: UITableViewDelegate) {
        proxyDelegate = delegate
        super.init()
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if MoreTableViewDelegate.instancesRespond(to: aSelector) {
            return true
        }
        
        return proxyDelegate.responds(to: aSelector)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return proxyDelegate
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (proxyDelegate.responds(to: #function) == true) {
            proxyDelegate.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
        }

        cell.backgroundColor = UIColor.background()
        cell.textLabel?.textColor = UIColor.primaryText()
        cell.accessoryType = .none
            
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 11, height: 14)
        button.setBackgroundImage(UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)), for: .normal)
        button.tintColor = UIColor.tableCellDisclosure()
        cell.accessoryView = button
    }
}


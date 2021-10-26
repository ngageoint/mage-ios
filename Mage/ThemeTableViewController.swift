//
//  ThemeTableViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 10/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit

@objc class ThemeTableViewController: UITableViewController {
    var scheme: MDCContainerScheming?;

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public init(scheme: MDCContainerScheming?) {
        self.scheme = scheme;
        super.init(style: .grouped)
        applyTheme(withScheme: self.scheme)
    }
    
    public func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return
        }
        self.scheme = scheme;
        
        self.view.backgroundColor = scheme.colorScheme.backgroundColor;
        self.tableView.backgroundColor = scheme.colorScheme.backgroundColor;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        
        self.navigationItem.title = "Theme Settings"
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func numberOfSections(in: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView();
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellReuseIdentifier");
        if (indexPath.row == UIUserInterfaceStyle.unspecified.rawValue) {
            cell.textLabel?.text = "Follow system theme";
            cell.accessoryType = UserDefaults.standard.themeOverride == UIUserInterfaceStyle.unspecified.rawValue ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none;
        } else if (indexPath.row == UIUserInterfaceStyle.light.rawValue) {
            cell.textLabel?.text = "Light";
            cell.accessoryType = UserDefaults.standard.themeOverride == UIUserInterfaceStyle.light.rawValue ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none;
        } else if (indexPath.row == UIUserInterfaceStyle.dark.rawValue) {
            cell.textLabel?.text = "Dark";
            cell.accessoryType = UserDefaults.standard.themeOverride == UIUserInterfaceStyle.dark.rawValue ? UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none;
        }

        cell.tintColor = self.scheme?.colorScheme.primaryColor;
        cell.textLabel?.textColor = self.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        cell.detailTextLabel?.textColor = self.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension;
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UserDefaults.standard.themeOverride = indexPath.row
        tableView.reloadData();
        UIWindow.updateThemeFromPreferences();
    }
}

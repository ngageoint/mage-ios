//
//  NavigationSettingsViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 5/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class NavigationSettingsViewController: UITableViewController {
    
    var scheme: MDCContainerScheming?;
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public init(scheme: MDCContainerScheming?) {
        self.scheme = scheme;
        super.init(style: .grouped)
        tableView.register(cellClass: ColorPickerCell.self)
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
        
        self.navigationItem.title = "Navigation Settings"
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.bearingTargetColor), options: .new, context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: #keyPath(UserDefaults.headingColor), options: .new, context: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.bearingTargetColor))
        UserDefaults.standard.removeObserver(self, forKeyPath: #keyPath(UserDefaults.headingColor))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        tableView.reloadData()
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
        var cell: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellReuseIdentifier");
        if (indexPath.row == 2) {
            cell.textLabel?.text = "Always show heading on map"
            cell.accessoryType = UserDefaults.standard.showHeading ? .checkmark : .none
            cell.textLabel?.textColor = self.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
            cell.detailTextLabel?.textColor = self.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
            return cell;
        }
        let colorCell: ColorPickerCell = tableView.dequeue(cellClass: ColorPickerCell.self, forIndexPath: indexPath)
        if (indexPath.row == 0) {
            colorCell.colorPreference = #keyPath(UserDefaults.bearingTargetColor)
        }
        if (indexPath.row == 1) {
            colorCell.colorPreference = #keyPath(UserDefaults.headingColor)
        }
        cell = colorCell
        
        if (indexPath.row == 0) {
            cell.textLabel?.text = "Relative Bearing Line Color";
            cell.textLabel?.textColor = UserDefaults.standard.bearingTargetColor;
        }
        if (indexPath.row == 1) {
            cell.textLabel?.text = "Heading Line Color";
            cell.textLabel?.textColor = UserDefaults.standard.headingColor;
        }
        
        cell.textLabel?.textColor = self.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        cell.detailTextLabel?.textColor = self.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        cell.accessoryType = .none;
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension;
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath.row == 2) {
            UserDefaults.standard.showHeading = !UserDefaults.standard.showHeading
            tableView.reloadData()
        }
    }
    
}

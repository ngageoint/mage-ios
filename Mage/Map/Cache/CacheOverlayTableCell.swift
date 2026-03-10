//
//  CacheOverlayTableCell.m
//  MAGE
//
//  Created by Brian Osborn on 1/11/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation
import UIKit

class CacheOverlayTableCell: UITableViewCell {
    var active: CacheActiveSwitch?
    var tableType: UIImageView?
    var name: UILabel?
    var overlay: CacheOverlay?
    var mageLayer: Layer?
    var mainTable: UITableView?
    weak var excludedListener: (any CacheOverlayListener)? // Used to prevent duplicate reloads when tapping toggles
    var tableView: UITableView
    
    var scheme: MDCContainerScheming?
    
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, scheme: MDCContainerScheming) {
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.tableView.tag = 100
        self.scheme = scheme
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.addSubview(self.tableView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let subMenuTableView = self.viewWithTag(100)
        subMenuTableView?.frame = CGRect(x: 0.2, y: 0.3, width: self.bounds.size.width, height: self.bounds.size.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        tableView.reloadData()
    }
    
    @objc func activeChanged(sender: CacheActiveSwitch) {
        guard let cacheOverlay = sender.overlay else { return }
        cacheOverlay.enabled = sender.isOn
        
        var modified = false
        for childCache in cacheOverlay.getChildren() {
            if childCache.enabled != cacheOverlay.enabled {
                childCache.enabled = cacheOverlay.enabled
                modified = true
            }
        }
        
        if modified {
            // Refresh the parent row for expanded layers (GeoPackage)
            tableView.reloadRows(at: rowIndexPathsForLayers(overlay: cacheOverlay), with: .none)
        }
        Task {
            await updateSelectedAndNotify()
        }
    }

    @objc func childActiveChanged(sender: CacheActiveSwitch) {
        guard let cacheOverlay = sender.overlay else { return }
        guard let parentOverlay = cacheOverlay.getParent() else { return }
        
        cacheOverlay.enabled = sender.isOn
        
        var parentEnabled = true
        if !cacheOverlay.enabled {
            parentEnabled = false
            for childCache in parentOverlay.getChildren() {
                if childCache.enabled {
                    parentEnabled = true
                    break
                }
            }
        }
        
        if parentEnabled != parentOverlay.enabled {
            parentOverlay.enabled = parentEnabled
            // Refresh the parent row for expanded layers (GeoPackage)
            if let parentRow = rowIndexPathForExpandableGroupIfPresent(overlay: parentOverlay) {
                tableView.reloadRows(at: [parentRow], with: .none)
            }
        }
        Task {
            await updateSelectedAndNotify()
        }
    }
    
    func updateSelectedAndNotify() async {
        var overlays: [String] = []
        var cacheOverlaysOverlays: [CacheOverlay] = []
        cacheOverlaysOverlays.append(contentsOf: await CacheOverlays.shared.getOverlays())
        
        for cacheOverlay in cacheOverlaysOverlays {
            var childAdded = false
            for childCache in cacheOverlay.getChildren() {
                if childCache.enabled {
                    overlays.append(childCache.cacheName)
                    childAdded = true
                }
            }
            
            if !childAdded && cacheOverlay.enabled {
                overlays.append(cacheOverlay.cacheName)
            }
        }
        
        UserDefaults.standard.selectedCaches = overlays
        await CacheOverlays.shared.notifyListenersExceptCaller(caller: excludedListener)
    }

    private func isExpandableGroup(_ overlay: CacheOverlay) -> Bool {
        overlay.getChildren().count > 1
    }

    private func rowIndexPathsForLayers(overlay: CacheOverlay) -> [IndexPath] {
        // Single-child overlays do not have an expand/collapse parent row; child lives at row 0.
        if !isExpandableGroup(overlay) {
            return [IndexPath(row: 0, section: 0)]
        }

        // Multi-child overlays use row 0 as the expandable parent and rows 1...n as children.
        return overlay.getChildren().indices.map { IndexPath(row: $0 + 1, section: 0) }
    }

    private func rowIndexPathForExpandableGroupIfPresent(overlay: CacheOverlay) -> IndexPath? {
        // Multi-child overlays have a parent row at index 0; single-child overlays do not.
        isExpandableGroup(overlay) ? IndexPath(row: 0, section: 0) : nil
    }

    private var layerToggleOnColor: UIColor {
        UIColor(named: "layerToggleOn") ?? .systemBlue
    }
}

extension CacheOverlayTableCell: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let overlay = overlay else { return 0 }
        return overlay.getChildren().count == 1 ? 1 : overlay.getChildren().count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        58.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView(frame: .zero)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let overlay = overlay else { return }
        if indexPath.row == 0 && isExpandableGroup(overlay) {
            overlay.expanded.toggle()
            tableView.reloadData()
            if let mainTable = mainTable {
                mainTable.reloadData()
            }
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cacheOverlayCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        
        cell.textLabel?.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
        cell.detailTextLabel?.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        cell.backgroundColor = scheme?.colorScheme.surfaceColor
        cell.imageView?.tintColor = scheme?.colorScheme.primaryColorVariant
        
        if let overlay = overlay {
            let children = overlay.getChildren()
            let count = children.count
            
            if count != 1 && indexPath.row == 0 {
                // Parent row
                let cacheSwitch = CacheActiveSwitch(frame: .zero)
                cacheSwitch.isOn = overlay.enabled
                cacheSwitch.overlay = overlay
                cacheSwitch.onTintColor = layerToggleOnColor
                cacheSwitch.addTarget(self, action: #selector(activeChanged), for: .valueChanged)
                cell.accessoryView = cacheSwitch
                
                cell.textLabel?.text = (self.mageLayer != nil) ? self.mageLayer!.name : overlay.name
                cell.detailTextLabel?.text = "\(count) layer\(count == 1 ? "" : "s")"
                cell.imageView?.image = UIImage(systemName: "folder")
                
            } else {
                // Child row
                let childIndex = (count == 1) ? indexPath.row : indexPath.row - 1
                let cacheOverlay = children[childIndex]
                
                let imageName = cacheOverlay.iconImageName
                if let imageName = imageName {
                    cell.imageView?.image = UIImage(named: imageName)
                }
                
                cell.textLabel?.text = overlay.getChildren().count == 1 ? (self.mageLayer != nil ? self.mageLayer!.name : overlay.name) : cacheOverlay.name
                cell.detailTextLabel?.text = cacheOverlay.getInfo()
                
                let cacheSwitch = CacheActiveSwitch(frame: .zero)
                cacheSwitch.isOn = cacheOverlay.enabled
                cacheSwitch.overlay = cacheOverlay
                cacheSwitch.onTintColor = layerToggleOnColor
                cacheSwitch.addTarget(self, action: #selector(childActiveChanged), for: .valueChanged)
                cell.accessoryView = cacheSwitch
            }
        }
        return cell
    }
}

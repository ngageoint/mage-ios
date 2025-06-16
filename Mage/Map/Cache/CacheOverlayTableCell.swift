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
    var tableView: UITableView
    
    var scheme: AppContainerScheming?
    
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, scheme: AppContainerScheming) {
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
            tableView.reloadData()
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
            tableView.reloadData()
        }
        Task {
            await updateSelectedAndNotify()
        }
    }
    
    func updateSelectedAndNotify() async {
        var overlays: [String] = []
        let cacheOverlays = CacheOverlays.getInstance()
        var cacheOverlaysOverlays: [CacheOverlay] = []
        cacheOverlaysOverlays.append(contentsOf: await cacheOverlays.getOverlays())
        
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
        await cacheOverlays.notifyListeners()
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
        if indexPath.row == 0 && overlay?.getChildren().count != 1 {
            overlay?.expanded.toggle()
            tableView.reloadData()
            mainTable?.reloadData()
        }
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cacheOverlayCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cacheOverlayCell")
        }
        cell?.textLabel?.textColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.87)
        cell?.detailTextLabel?.textColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        cell?.backgroundColor = scheme?.colorScheme.surfaceColor
        cell?.imageView?.tintColor = scheme?.colorScheme.primaryColorVariant
        
        if let overlay {
            if overlay.getChildren().count != 1 && indexPath.row == 0 {
                let cacheSwitch = CacheActiveSwitch(frame: .zero)
                cacheSwitch.isOn = overlay.enabled
                cacheSwitch.overlay = overlay
                cacheSwitch.onTintColor = scheme?.colorScheme.primaryColorVariant
                cacheSwitch.addTarget(self, action: #selector(activeChanged), for: .touchUpInside)
                cell?.accessoryView = cacheSwitch
                cell?.textLabel?.text = (self.mageLayer != nil) ? self.mageLayer!.name : overlay.name
                cell?.detailTextLabel?.text = "\(overlay.getChildren().count) layer\(overlay.getChildren().count == 1 ? "" : "s")"
                cell?.imageView?.image = UIImage(systemName: "folder")
            } else {
                let cacheOverlay = overlay.getChildren()[overlay.getChildren().count == 1 ? indexPath.row : indexPath.row - 1]
                var cellImage: UIImage?
                if let typeImage = cacheOverlay.iconImageName {
                    cellImage = UIImage(named: typeImage)
                }
                if let cellImage {
                    cell?.imageView?.image = cellImage
                }
                cell?.textLabel?.text = overlay.getChildren().count == 1 ? (self.mageLayer != nil ? self.mageLayer!.name : overlay.name) : cacheOverlay.name
                cell?.detailTextLabel?.text = cacheOverlay.getInfo()
                
                let cacheSwitch = CacheActiveSwitch(frame: .zero)
                cacheSwitch.isOn = cacheOverlay.enabled
                cacheSwitch.overlay = cacheOverlay
                cacheSwitch.onTintColor = scheme?.colorScheme.primaryColorVariant
                cacheSwitch.addTarget(self, action: #selector(childActiveChanged), for: .touchUpInside)
                cell?.accessoryView = cacheSwitch
            }
        }
        return cell!
    }
}

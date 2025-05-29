//
//  OfflineMapTableViewController.m
//  MAGE
//
//

import Foundation
import UIKit
import MagicalRecord
import geopackage_ios

@objc class OfflineMapTableViewController: UITableViewController, CacheOverlayListener {
    
    var refreshLayersButton: UIBarButtonItem?
    var selectedStaticLayers: Set<NSNumber>?
    var mapsFetchedResultsController: NSFetchedResultsController<any NSFetchRequestResult>?
    var scheme: MDCContainerScheming
    var context: NSManagedObjectContext
    
    enum Sections: Int {
        case DOWNLOADED_SECTION
        case MY_MAPS_SECTION
        case AVAILABLE_SECTION
        case PROCESSING_SECTION
        
        func name() -> String {
            switch self {
            case .DOWNLOADED_SECTION:
                "%@ Layers"
            case .MY_MAPS_SECTION:
                "My Layers"
            case .AVAILABLE_SECTION:
                "Available Layers"
            case .PROCESSING_SECTION:
                "Extracting Archives"
            }
        }
    }
    
    @objc init(scheme: MDCContainerScheming, context: NSManagedObjectContext) {
        self.scheme = scheme
        self.context = context
        
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTheme(containerScheme: MDCContainerScheming?) {
        guard let containerScheme else { return }
        scheme = containerScheme
        tableView.backgroundColor = scheme.colorScheme.backgroundColor
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // why are we setting this just to re-set it later
        navigationItem.rightBarButtonItem = editButtonItem
        tableView.layoutMargins = .zero
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh Layers", style: .plain, target: self, action: #selector(refreshLayers))
        
        reloadData()
        
        Task {
            await CacheOverlays.getInstance().register(self)
        }
        
        applyTheme(containerScheme: scheme)
    }
    
    func layerFromIndexPath(_ indexPath: IndexPath) -> Layer? {
        return mapsFetchedResultsController?.object(at: indexPath) as? Layer
    }
    
    @objc func reloadData() {
        mapsFetchedResultsController = Layer.mr_fetchAllGrouped(
            by: "loaded",
            with: NSPredicate(
                format: "(eventId == %@ OR eventId == -1) AND (type == %@ OR type == %@ OR type == %@)",
                argumentArray: [Server.currentEventId() ?? -1, "GeoPackage", "Local_XYZ", "Feature"]
            ),
            sortedBy: "loaded,name:YES",
            ascending: false,
            delegate: self,
            in: context
        )
        try? mapsFetchedResultsController?.performFetch()
        
        selectedStaticLayers = Set(UserDefaults.standard.array(forKey: "selectedStaticLayers.\(Server.currentEventId() ?? -1)") as? [NSNumber] ?? [])
    }
    
    func geoPackageImported(notification: NSNotification) {
        tableView.performSelector(onMainThread: #selector(tableView.reloadData), with: nil, waitUntilDone: false)
    }
    
    @objc func refreshLayers(sender: UIBarButtonItem) {
        refreshLayersButton?.isEnabled = false
        if let currentEventId = Server.currentEventId() {
            Layer.refreshLayers(eventId: currentEventId)
        }
    }
    
    func cacheOverlaysUpdated(_ cacheOverlays: [CacheOverlay]) {
        DispatchQueue.main.async {
            self.tableView.performSelector(onMainThread: #selector(self.tableView.reloadData), with: nil, waitUntilDone: false)
        }
    }
    
    func findOverlay(remoteId: NSNumber) async -> CacheOverlay? {
        let cacheOverlaysOverlays = await CacheOverlays.getInstance().getOverlays()
        for cacheOverlay in cacheOverlaysOverlays {
            if let gpCacheOverlay = cacheOverlay as? GeoPackageCacheOverlay,
               let layerId = gpCacheOverlay.layerId
            {
                if layerId == remoteId.stringValue {
                    return cacheOverlay
                }
            }
        }
        
        return nil
    }
    
    func layer(indexPath: IndexPath) -> Layer? {
        mapsFetchedResultsController?.object(at: indexPath) as? Layer
    }
}

extension OfflineMapTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChange sectionInfo: any NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType
    ) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(arrayLiteral: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(arrayLiteral: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        @unknown default:
            break
        }
    }
    
    func controller(
        _ controller: NSFetchedResultsController<any NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            if let newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .move:
            if let indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            if let newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .update:
            guard let layer = anObject as? Layer else { return }
            guard let indexPath else { return }
            let section = getSectionFromLayer(layer: layer)
            if section == Sections.AVAILABLE_SECTION.rawValue && indexPath.row == 0 {
                let cell = tableView.cellForRow(at: indexPath)
                if let fileDictionary = layer.file {
                    let downloadBytes = layer.downloadedBytes ?? 0
                    let totalBytes = fileDictionary["size"] as? Int ?? 0
                    cell?.detailTextLabel?.text = "Downloading, Please wait: \(ByteCountFormatter.string(fromByteCount: Int64(truncating: downloadBytes), countStyle: .file)) of \(ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file))"
                    tableView.reloadRows(at: [indexPath], with: .none)
                } else {
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        @unknown default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        let sectionCount = mapsFetchedResultsController?.sections?.count ?? 0
        
        if sectionCount == 0 {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width * 0.8, height: self.view.bounds.size.height))
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            imageView.image = UIImage(named: "square.stack.3d.up")
            imageView.contentMode = .scaleAspectFill
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
            
            let title = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width * 0.8, height: 0))
            title.text = "No Layers"
            title.numberOfLines = 0
            title.textAlignment = .center
            title.translatesAutoresizingMaskIntoConstraints = false
            title.font = UIFont.systemFont(ofSize: 24)
            title.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
            title.sizeToFit()
            
            let description = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width * 0.8, height: 0))
            description.text = "Event administrators can add layers to your event, or can be shared from other applications."
            description.numberOfLines = 0
            description.textAlignment = .center
            description.translatesAutoresizingMaskIntoConstraints = false
            description.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
            description.sizeToFit()
            
            view.addSubview(title)
            view.addSubview(description)
            view.addSubview(imageView)
            
            title.addConstraint(
                NSLayoutConstraint(
                    item: title,
                    attribute: .width,
                    relatedBy: .equal,
                    toItem: nil,
                    attribute: .notAnAttribute,
                    multiplier: 1.0,
                    constant: self.view.bounds.size.width * 0.8
                )
            )
            
            view.addConstraint(
                NSLayoutConstraint(
                    item: title,
                    attribute: .centerX,
                    relatedBy: .equal,
                    toItem: view,
                    attribute: .centerX,
                    multiplier: 1.0,
                    constant: 0
                )
            )
            
            description.addConstraint(
                NSLayoutConstraint(
                    item: description,
                    attribute: .width,
                    relatedBy: .equal,
                    toItem: nil,
                    attribute: .notAnAttribute,
                    multiplier: 1.0,
                    constant: self.view.bounds.size.width * 0.8
                )
            )
            
            view.addConstraint(
                NSLayoutConstraint(
                    item: title,
                    attribute: .centerY,
                    relatedBy: .equal,
                    toItem: view,
                    attribute: .centerY,
                    multiplier: 1.0,
                    constant: 0
                )
            )
            
            view.addConstraint(
                NSLayoutConstraint(
                    item: description,
                    attribute: .centerX,
                    relatedBy: .equal,
                    toItem: view,
                    attribute: .centerX,
                    multiplier: 1.0,
                    constant: 0
                )
            )
            
            imageView.addConstraint(
                NSLayoutConstraint(
                    item: imageView,
                    attribute: .width,
                    relatedBy: .equal,
                    toItem: nil,
                    attribute: .notAnAttribute,
                    multiplier: 1.0,
                    constant: 100
                )
            )
            
            imageView.addConstraint(
                NSLayoutConstraint(
                    item: imageView,
                    attribute: .height,
                    relatedBy: .equal,
                    toItem: nil,
                    attribute: .notAnAttribute,
                    multiplier: 1.0,
                    constant: 100
                )
            )
            
            view.addConstraint(
                NSLayoutConstraint(
                    item: imageView,
                    attribute: .centerX,
                    relatedBy: .equal,
                    toItem: view,
                    attribute: .centerX,
                    multiplier: 1.0,
                    constant: 0
                )
            )
            
            view.addConstraint(
                NSLayoutConstraint(
                    item: title,
                    attribute: .top,
                    relatedBy: .equal,
                    toItem: imageView,
                    attribute: .bottom,
                    multiplier: 1.0,
                    constant: 16
                )
            )
            
            view.addConstraint(
                NSLayoutConstraint(
                    item: description,
                    attribute: .top,
                    relatedBy: .equal,
                    toItem: title,
                    attribute: .bottom,
                    multiplier: 1.0,
                    constant: 16
                )
            )
            
            self.tableView.backgroundView = view
            return 0
        }
        self.tableView.backgroundView = nil
        return sectionCount
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapsFetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func getSectionFromLayer(layer: Layer) -> Int {
        guard let loaded = layer.loaded else { return Sections.AVAILABLE_SECTION.rawValue }
        
        if loaded.floatValue == NSNumber(floatLiteral: Layer.OFFLINE_LAYER_NOT_DOWNLOADED).floatValue {
            return Sections.AVAILABLE_SECTION.rawValue
        } else if loaded.floatValue == NSNumber(floatLiteral: Layer.OFFLINE_LAYER_LOADED).floatValue {
            return Sections.DOWNLOADED_SECTION.rawValue
        } else if loaded.floatValue == NSNumber(floatLiteral: Layer.EXTERNAL_LAYER_LOADED).floatValue {
            return Sections.MY_MAPS_SECTION.rawValue
        } else {
            return Sections.PROCESSING_SECTION.rawValue
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection: Int) -> CGFloat {
        45.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection: Int) -> UIView {
        ObservationTableHeaderView(name: self.tableView(tableView, titleForHeaderInSection: viewForHeaderInSection), andScheme: scheme)
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection: Int) -> CGFloat {
        0.0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection: Int) -> UIView {
        UIView(frame: .zero)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let layer = self.layer(indexPath: indexPath) else { return 58.0}
        
        let section = getSectionFromLayer(layer: layer)
        if section == Sections.DOWNLOADED_SECTION.rawValue {
            // TODO: async calls need to go away, this will be fixed in swiftUI view model
//            if let remoteId = layer.remoteId,
//                let cacheOverlay = findOverlay(remoteId: remoteId),
//                cacheOverlay.expanded
//            {
//                return 58.0 + (58.0 * CGFloat(integerLiteral: (cacheOverlay.getChildren().count)))
//            }
            return UITableView.automaticDimension
        } else if section == Sections.MY_MAPS_SECTION.rawValue {
            if let cacheOverlay = CacheOverlays.getInstance().getByCacheName(layer.name),
               cacheOverlay.expanded
            {
                return 58.0 + (58.0 * CGFloat(integerLiteral: (cacheOverlay.getChildren().count)))
            }
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "onlineLayerCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "onlineLayerCell")
        }
        cell?.textLabel?.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
        cell?.detailTextLabel?.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        cell?.backgroundColor = scheme.colorScheme.surfaceColor
        cell?.imageView?.tintColor = scheme.colorScheme.primaryColorVariant
        cell?.imageView?.image = nil
        cell?.accessoryView = nil
        
        guard let layer = layer(indexPath: indexPath) else { return cell! }
        let section = getSectionFromLayer(layer: layer)
        
        if section == Sections.AVAILABLE_SECTION.rawValue {
            cell?.textLabel?.text = layer.name
            if !layer.downloading {
                if let fileDictionary = layer.file,
                   let byteCount = fileDictionary["size"] as? Int
                {
                    cell?.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
                } else {
                    cell?.detailTextLabel?.text = "Static feature data"
                }
                
                let imageView = UIImageView(image: UIImage(named: "download"))
                imageView.tintColor = scheme.colorScheme.primaryColorVariant
                cell?.accessoryView = imageView
            } else {
                if let fileDictionary = layer.file {
                    let downloadBytes = layer.downloadedBytes ?? 0
                    let totalBytes = fileDictionary["size"] as? Int ?? 0
                    cell?.detailTextLabel?.text = "Downloading, Please wait: \(ByteCountFormatter.string(fromByteCount: Int64(truncating: downloadBytes), countStyle: .file)) of \(ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file))"
                } else {
                    cell?.detailTextLabel?.text = "Loading static feature data, Please wait"
                }
                
                let activityIndicatorView = UIActivityIndicatorView(style: .medium)
                activityIndicatorView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                activityIndicatorView.startAnimating()
                cell?.accessoryView = activityIndicatorView
            }
        } else if section == Sections.DOWNLOADED_SECTION.rawValue {
            if let staticLayer = layer as? StaticLayer {
                cell?.textLabel?.text = staticLayer.name
                cell?.detailTextLabel?.text = "\((staticLayer.data?["features"] as? [Any] ?? []).count)"
                
                cell?.imageView?.image = UIImage(named: "marker_outline")
                
                let cacheSwitch = UISwitch(frame: .zero)
                cacheSwitch.isOn = selectedStaticLayers?.contains((layer.remoteId ?? -1)) ?? false
                cacheSwitch.onTintColor = scheme.colorScheme.primaryColorVariant
                cacheSwitch.tag = indexPath.row
                cacheSwitch.addTarget(self, action: #selector(staticLayerToggled), for: .touchUpInside)
                cell?.accessoryView = cacheSwitch
            } else {
                var gpCell = tableView.dequeueReusableCell(withIdentifier: "geoPackageLayerCell") as? CacheOverlayTableCell
                if gpCell == nil {
                    gpCell = CacheOverlayTableCell(style: .subtitle, reuseIdentifier: "geoPackageLayerCell", scheme: scheme)
                }
                gpCell?.backgroundColor = scheme.colorScheme.surfaceColor
                
                // TODO: solve this async problem
//                let cacheOverlay = await findOverlay(remoteId: layer.remoteId)
//                gpCell?.overlay = cacheOverlay
                gpCell?.mageLayer = layer
                gpCell?.mainTable = self.tableView
                gpCell?.configure()
                gpCell?.bringSubviewToFront(gpCell!.tableView)
                return gpCell!
            }
        } else if section == Sections.MY_MAPS_SECTION.rawValue {
            let localOverlay = CacheOverlays.getInstance().getByCacheName(layer.name)
            if let localOverlay = localOverlay as? GeoPackageCacheOverlay {
                var gpCell = tableView.dequeueReusableCell(withIdentifier: "geoPackageLayerCell") as? CacheOverlayTableCell
                if gpCell == nil {
                    gpCell = CacheOverlayTableCell(style: .subtitle, reuseIdentifier: "geoPackageLayerCell", scheme: scheme)
                }
                gpCell?.backgroundColor = scheme.colorScheme.surfaceColor
                
                gpCell?.overlay = localOverlay
                gpCell?.mageLayer = layer
                gpCell?.mainTable = self.tableView
                gpCell?.configure()
                gpCell?.bringSubviewToFront(gpCell!.tableView)
                return gpCell!
            } else {
                cell?.textLabel?.text = localOverlay?.cacheName
                cell?.detailTextLabel?.text = localOverlay?.getInfo()
                cell?.imageView?.image = UIImage(named: localOverlay?.iconImageName ?? "")
                
                let cacheSwitch = CacheActiveSwitch(frame: .zero)
                cacheSwitch.isOn = localOverlay?.enabled ?? false
                cacheSwitch.overlay = localOverlay
                cacheSwitch.onTintColor = scheme.colorScheme.primaryColorVariant
                cacheSwitch.addTarget(self, action: #selector(activeChanged), for: .touchUpInside)
                cell?.accessoryView = cacheSwitch
            }
        } else if section == Sections.PROCESSING_SECTION.rawValue {
            let documentsDirectory = getDocumentsDirectory()
            let processingOverlay = CacheOverlays.getInstance().getProcessing()[indexPath.row]
            cell?.textLabel?.text = processingOverlay
            if let attrs = try? FileManager.default.attributesOfItem(atPath: documentsDirectory.appendingPathComponent(processingOverlay)),
               let fileSize = attrs[.size] as? Int64
            {
                cell?.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
            }
            cell?.imageView?.image = nil
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            activityIndicator.color = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            cell?.accessoryView = activityIndicator
        } else {
            cell?.textLabel?.text = layer.name
            cell?.detailTextLabel?.text = nil
            cell?.accessoryView = nil
        }
        return cell!
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }
    
    @objc func staticLayerToggled(sender: UISwitch) {
        guard let layer = layer(indexPath: IndexPath(row: sender.tag, section: 0)) else { return }
        guard let remoteId = layer.remoteId else { return }
        if sender.isOn {
            selectedStaticLayers?.insert(remoteId)
        } else {
            selectedStaticLayers?.remove(remoteId)
        }
        
        var staticLayers = UserDefaults.standard.selectedStaticLayers ?? [:]
        staticLayers["\(Server.currentEventId() ?? -1)"] = Array(selectedStaticLayers ?? Set<NSNumber>())
        UserDefaults.standard.selectedStaticLayers = staticLayers
    }
    
    func retrieveLayerData(layer: Layer) {
        if let layer = layer as? StaticLayer {
            StaticLayer.fetchStaticLayerData(eventId: Server.currentEventId() ?? -1, staticLayer: layer)
        } else {
            Layer.cancelGeoPackageDownload(layer: layer)
            startGeoPackageDownload(layer: layer)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let layer = layer(indexPath: indexPath) else { return }
        let section = getSectionFromLayer(layer: layer)
        
        if section == Sections.AVAILABLE_SECTION.rawValue {
            if layer.downloading {
                let alert = UIAlertController(
                    title: "Layer is Currently Downloading",
                    message: "It appears the \(layer.name ?? "") layer is currently being downloaded, however if the download has failed you can restart it.",
                    preferredStyle: .alert
                )
                let restartAction = UIAlertAction(title: "Restart Download", style: .destructive) { [weak self] _ in
                    self?.retrieveLayerData(layer: layer)
                }
                let cancelAction = UIAlertAction(title: "Cancel Download", style: .cancel) { [weak self] _ in
                    self?.cancelGeoPackageDownload(layer: layer)
                }
                let continueAction = UIAlertAction(title: "Continue Download", style: .cancel)
                
                alert.addAction(restartAction)
                alert.addAction(cancelAction)
                alert.addAction(continueAction)
                self.navigationController?.present(alert, animated: true, completion: nil)
            } else {
                retrieveLayerData(layer: layer)
            }
        } else if section == Sections.DOWNLOADED_SECTION.rawValue {
            if let staticLayer = layer as? StaticLayer {
                if let cell = tableView.cellForRow(at: indexPath) {
                    if cell.accessoryType == .none {
                        cell.accessoryType = .checkmark
                        selectedStaticLayers?.insert(layer.remoteId ?? -1)
                    } else {
                        cell.accessoryType = .none
                        selectedStaticLayers?.remove(layer.remoteId ?? -1)
                    }
                }
                var staticLayers = UserDefaults.standard.selectedStaticLayers ?? [:]
                staticLayers["\(Server.currentEventId() ?? -1)"] = Array(selectedStaticLayers ?? Set<NSNumber>())
                UserDefaults.standard.selectedStaticLayers = staticLayers
                
                tableView.reloadData()
            }
        }
    }
    
    
    func startGeoPackageDownload(layer: Layer) {
        MagicalRecord.save { context in
            let localLayer = layer.mr_(in: context)
            localLayer?.downloading = true
            localLayer?.downloadedBytes = 0
        } completion: { didSave, error in
            Layer.downloadGeoPackage(layer: layer) {
                
            } failure: { error in
                
            }

        }

    }
    
    func cancelGeoPackageDownload(layer: Layer) {
        Layer.cancelGeoPackageDownload(layer: layer)
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

    func updateSelectedAndNotify() async {
        UserDefaults.standard.selectedCaches = await getSelectedOverlays()
        await CacheOverlays.shared.notifyListenersExceptCaller(caller: self)
    }
    
    func getSelectedOverlays() async -> [String] {
        var overlays: [String] = []
        let cacheOverlaysOverlays: [CacheOverlay] = await CacheOverlays.shared.getOverlays()
        for cacheOverlay in cacheOverlaysOverlays {
            var childAdded = false
            for childCache in cacheOverlay.getChildren() {
                if childCache.enabled {
                    overlays.append(childCache.cacheName)
                    childAdded = true
                }
            }
            
            if childAdded, cacheOverlay.enabled {
                overlays.append(cacheOverlay.cacheName)
            }
        }
        return overlays
    }
    
    override func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt editingStyleForRowAtIndexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        var style: UITableViewCell.EditingStyle = .none
        
        let layer = mapsFetchedResultsController?.sections?[editingStyleForRowAtIndexPath.section].objects?[0] as? Layer
        if let layer {
            let section = getSectionFromLayer(layer: layer)
            if section == Sections.DOWNLOADED_SECTION.rawValue || section == Sections.MY_MAPS_SECTION.rawValue {
                style = .delete
            }
        }
        return style
    }
    
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard let editedLayer = layerFromIndexPath(indexPath) else { return }
        let section = getSectionFromLayer(layer: editedLayer)
        // if a row is deleted, remove it from the list
        if editingStyle == .delete {
            if section == Sections.DOWNLOADED_SECTION.rawValue {
                if let staticLayer = editedLayer as? StaticLayer {
                    staticLayer.removeStaticLayerData()
                } else {
                    MagicalRecord.save { context in
                        let request = NSFetchRequest<Layer>(entityName: "Layer")
                        request.predicate = NSPredicate(format: "remoteId == %@", editedLayer.remoteId ?? -1)
                        let layers = try? context.fetch(request)
                        for layer in layers ?? [] {
                            layer.loaded = nil
                            layer.downloadedBytes = 0
                            layer.downloading = false
                        }
                    } completion: { didSave, error in
                        Task { [weak self] in
                            if let cacheOverlay = await self?.findOverlay(remoteId: editedLayer.remoteId ?? -1) as? GeoPackageCacheOverlay {
                                await self?.deleteCacheOverlay(cacheOverlay)
                            }
                            self?.tableView.reloadData()
                        }
                    }
                }
            } else if section == Sections.MY_MAPS_SECTION.rawValue {
                if let localOverlay = CacheOverlays.shared.getByCacheName(editedLayer.name) {
                    Task {
                        await deleteCacheOverlay(localOverlay)
                        MagicalRecord.save(blockAndWait: { context in
                            let localLayer = editedLayer.mr_(in: context)
                            localLayer?.mr_deleteEntity()
                        })
                    }
                }
            }
        }
    }
    
    func deleteCacheOverlay(_ cacheOverlay: CacheOverlay) async {
        switch cacheOverlay.type {
            
        case .XYZ_DIRECTORY:
            if let overlay = cacheOverlay as? XYZDirectoryCacheOverlay {
                deleteXYZCacheOverlay(overlay)
            }
        case .GEOPACKAGE:
            if let overlay = cacheOverlay as? GeoPackageCacheOverlay {
                await deleteGeoPackageCacheOverlay(overlay)
            }
        default:
            break
        }
    }
    
    func deleteXYZCacheOverlay(_ xyzCacheOverlay: XYZDirectoryCacheOverlay) {
        do {
            guard let directory = xyzCacheOverlay.directory else { return }
            try FileManager.default.removeItem(atPath: directory)
        } catch {
            NSLog("Error deleting XYZ cache directory: \(error)")
        }
    }
    
    func deleteGeoPackageCacheOverlay(_ geoPackageCacheOverlay: GeoPackageCacheOverlay) async {
        let manager = GPKGGeoPackageManager()
        if !(manager?.delete(geoPackageCacheOverlay.name) ?? false) {
            NSLog("Error deleting GeoPackage cache file: \(geoPackageCacheOverlay.name)")
        }
        await CacheOverlays.shared.removeCacheOverlay(overlay: geoPackageCacheOverlay)
    }
}

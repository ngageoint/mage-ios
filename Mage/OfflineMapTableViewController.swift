//
//  OfflineMapTableViewController.m
//  MAGE
//
//

import Foundation
import UIKit
import MagicalRecord
import GeoPackage

@objc class OfflineMapTableViewController: UITableViewController, CacheOverlayListener {
    
    var refreshLayersButton: UIBarButtonItem?
    var selectedStaticLayers: Set<NSNumber> = []
    var mapsFetchedResultsController: NSFetchedResultsController<any NSFetchRequestResult>?
    var scheme: MDCContainerScheming
    var context: NSManagedObjectContext
    var cacheOverlays: [CacheOverlay] = [] // synced with listener changes
    
    enum Sections: Int {
        case DOWNLOADED_SECTION
        case MY_MAPS_SECTION
        case AVAILABLE_SECTION
        case PROCESSING_SECTION
        
        func name(eventName: String? = "") -> String {
            switch self {
            case .DOWNLOADED_SECTION:
                "\(eventName ?? "Current Event") Layers"
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh Layers", style: .plain, target: self, action: #selector(refreshLayers))
        tableView.layoutMargins = .zero
        applyTheme(containerScheme: scheme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
        Task {
            await CacheOverlays.shared.register(self)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Task {
            await CacheOverlays.shared.unregisterListener(self)
        }
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

        selectedStaticLayers = Set(UserDefaults.standard.selectedStaticLayers?[currentEventStaticLayerKey] ?? [])
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
            self.cacheOverlays = cacheOverlays
            self.tableView.performSelector(onMainThread: #selector(self.tableView.reloadData), with: nil, waitUntilDone: false)
        }
    }
    
    func findGeoPackageOverlay(remoteId: NSNumber) -> CacheOverlay? {
        for cacheOverlay in cacheOverlays {
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

    private var currentEventStaticLayerKey: String {
        "\(Server.currentEventId() ?? -1)"
    }

    private func saveSelectedStaticLayers() {
        var staticLayers = UserDefaults.standard.selectedStaticLayers ?? [:]
        staticLayers[currentEventStaticLayerKey] = Array(selectedStaticLayers)
        UserDefaults.standard.selectedStaticLayers = staticLayers
    }

    private func configureAvailableLayerCell(_ cell: UITableViewCell, layer: Layer) {
        cell.textLabel?.text = layer.name

        if !layer.downloading {
            if
                let fileDictionary = layer.file,
                let byteCount = fileDictionary["size"] as? String
            {
                cell.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: Int64((byteCount)) ?? 0, countStyle: .file)
            } else {
                cell.detailTextLabel?.text = "Static feature data"
            }

            let imageView = UIImageView(image: UIImage(named: "download"))
            imageView.tintColor = scheme.colorScheme.primaryColorVariant
            cell.accessoryView = imageView
        } else {
            if
                let fileDictionary = layer.file,
                let totalSizeString = fileDictionary["size"] as? String,
                let totalBytes = Int64(totalSizeString)
            {
                let downloadedBytes = Int64(truncating: layer.downloadedBytes ?? 0)
                let downloadedText = ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
                let totalText = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
                cell.detailTextLabel?.text = "Downloading, Please wait: \(downloadedText) of \(totalText)"
            } else {
                cell.detailTextLabel?.text = "Loading static feature data, Please wait"
            }

            if let activityIndicatorView = cell.accessoryView as? UIActivityIndicatorView {
                activityIndicatorView.startAnimating()
            } else {
                let activityIndicatorView = UIActivityIndicatorView(style: .medium)
                activityIndicatorView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                activityIndicatorView.startAnimating()
                cell.accessoryView = activityIndicatorView
            }
        }
    }

    private var layerToggleOnColor: UIColor {
        UIColor(named: "layerToggleOn") ?? scheme.colorScheme.primaryColorVariant
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
            if section == Sections.AVAILABLE_SECTION.rawValue,
               let cell = tableView.cellForRow(at: indexPath) {
                configureAvailableLayerCell(cell, layer: layer)
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard
            let sectionInfo = mapsFetchedResultsController?.sections?[section],
            let layer = (sectionInfo.objects?.first as? Layer),
            let sectionType = Sections(rawValue: getSectionFromLayer(layer: layer))
        else { return 0.001 }
        let title = sectionType.name(eventName: Event.getCurrentEvent(context: context)?.name)
        return title.isEmpty ? 0.001 : 45
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard
            let sectionInfo = mapsFetchedResultsController?.sections?[section],
            let layer = (sectionInfo.objects?.first as? Layer),
            let sectionType = Sections(rawValue: getSectionFromLayer(layer: layer))
        else { return nil }
        let title = sectionType.name(eventName: Event.getCurrentEvent(context: context)?.name)
        guard !title.isEmpty else { return nil }
        return ObservationTableHeaderViewSwift(name: title, scheme: scheme)
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
            if let remoteId = layer.remoteId,
                let cacheOverlay = findGeoPackageOverlay(remoteId: remoteId),
                cacheOverlay.expanded
            {
                return 58.0 + (58.0 * CGFloat(integerLiteral: (cacheOverlay.getChildren().count)))
            }
            return UITableView.automaticDimension
        } else if section == Sections.MY_MAPS_SECTION.rawValue {
            if let cacheOverlay = self.cacheOverlays.first(where: { $0.name == layer.name }),
               cacheOverlay.expanded
            {
                return 58.0 + (58.0 * CGFloat(integerLiteral: (cacheOverlay.getChildren().count)))
            }
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "onlineLayerCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "onlineLayerCell")
        cell.textLabel?.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
        cell.detailTextLabel?.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        cell.backgroundColor = scheme.colorScheme.surfaceColor
        cell.imageView?.tintColor = scheme.colorScheme.primaryColorVariant
        cell.imageView?.image = nil
        cell.accessoryView = nil
        
        guard let layer = layer(indexPath: indexPath) else { return cell }
        let section = getSectionFromLayer(layer: layer)
        
        if section == Sections.AVAILABLE_SECTION.rawValue {
            configureAvailableLayerCell(cell, layer: layer)
        } else if section == Sections.DOWNLOADED_SECTION.rawValue {
            if let staticLayer = layer as? StaticLayer {
                let staticCell = (tableView.dequeueReusableCell(
                    withIdentifier: StaticLayerToggleTableViewCell.cellIdentifier
                ) as? StaticLayerToggleTableViewCell) ?? StaticLayerToggleTableViewCell(
                        style: .subtitle,
                        reuseIdentifier: StaticLayerToggleTableViewCell.cellIdentifier
                    )
                staticCell.textLabel?.text = staticLayer.name
                staticCell.detailTextLabel?.text = "\((staticLayer.data?["features"] as? [Any] ?? []).count)"
                staticCell.textLabel?.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
                staticCell.detailTextLabel?.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
                staticCell.backgroundColor = scheme.colorScheme.surfaceColor
                staticCell.imageView?.tintColor = scheme.colorScheme.primaryColorVariant
                staticCell.imageView?.image = UIImage(named: "marker_outline")
                staticCell.configureToggle(
                    remoteId: layer.remoteId,
                    isOn: layer.remoteId.map { selectedStaticLayers.contains($0) } ?? false,
                    onTintColor: layerToggleOnColor,
                    onToggle: { [weak self] remoteId, isOn in
                        self?.staticLayerToggled(remoteId: remoteId, isOn: isOn)
                    }
                )
                return staticCell
            } else {
                let gpCell = (tableView.dequeueReusableCell(withIdentifier: "geoPackageLayerCell") as? CacheOverlayTableCell)
                    ?? CacheOverlayTableCell(style: .subtitle, reuseIdentifier: "geoPackageLayerCell", scheme: scheme)
                gpCell.backgroundColor = scheme.colorScheme.surfaceColor
                
                gpCell.overlay = nil
                gpCell.mageLayer = layer
                gpCell.mainTable = self.tableView
                gpCell.excludedListener = self
                gpCell.configure()
                
                // Capture indexPath and update when overlay is ready
                let currentIndexPath = indexPath
                Task { [weak self] in
                    guard let self = self else { return }
                    if let remoteId = layer.remoteId, let overlay = self.findGeoPackageOverlay(remoteId: remoteId) {
                        await MainActor.run {
                            // Ensure the cell is still visible at the same indexPath
                            if let visibleCell = self.tableView.cellForRow(at: currentIndexPath) as? CacheOverlayTableCell {
                                visibleCell.overlay = overlay
                                visibleCell.mageLayer = layer
                                visibleCell.mainTable = self.tableView
                                visibleCell.excludedListener = self
                                visibleCell.configure()
                                visibleCell.bringSubviewToFront(visibleCell.tableView)
                            }
                        }
                    }
                }
                
                gpCell.bringSubviewToFront(gpCell.tableView)
                return gpCell
            }
        } else if section == Sections.MY_MAPS_SECTION.rawValue {
            let localOverlay = self.cacheOverlays.first(where: { $0.name == layer.name })
            if let localOverlay = localOverlay as? GeoPackageCacheOverlay {
                let gpCell = (tableView.dequeueReusableCell(withIdentifier: "geoPackageLayerCell") as? CacheOverlayTableCell)
                    ?? CacheOverlayTableCell(style: .subtitle, reuseIdentifier: "geoPackageLayerCell", scheme: scheme)
                gpCell.backgroundColor = scheme.colorScheme.surfaceColor
                
                gpCell.overlay = localOverlay
                gpCell.mageLayer = layer
                gpCell.mainTable = self.tableView
                gpCell.excludedListener = self
                gpCell.configure()
                gpCell.bringSubviewToFront(gpCell.tableView)
                return gpCell
            } else {
                cell.textLabel?.text = localOverlay?.cacheName
                cell.detailTextLabel?.text = localOverlay?.getInfo()
                cell.imageView?.image = UIImage(named: localOverlay?.iconImageName ?? "")
                
                let cacheSwitch = CacheActiveSwitch(frame: .zero)
                cacheSwitch.isOn = localOverlay?.enabled ?? false
                cacheSwitch.overlay = localOverlay
                cacheSwitch.onTintColor = layerToggleOnColor
                cacheSwitch.addTarget(self, action: #selector(activeChanged), for: .touchUpInside)
                cell.accessoryView = cacheSwitch
            }
        } else if section == Sections.PROCESSING_SECTION.rawValue {
            let documentsDirectory = getDocumentsDirectory()
            let processingOverlay = CacheOverlays.shared.getProcessing()[indexPath.row]
            cell.textLabel?.text = processingOverlay
            if
                let attrs = try? FileManager.default.attributesOfItem(atPath: documentsDirectory.appendingPathComponent(processingOverlay)),
                let fileSize = attrs[.size] as? String
            {
                cell.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: Int64(Int(fileSize) ?? 0), countStyle: .file)
            }
            cell.imageView?.image = nil
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            activityIndicator.color = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
            cell.accessoryView = activityIndicator
        } else {
            cell.textLabel?.text = layer.name
            cell.detailTextLabel?.text = nil
            cell.accessoryView = nil
        }
        return cell
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory as NSString
    }

    private func staticLayerToggled(remoteId: NSNumber, isOn: Bool) {
        if isOn {
            selectedStaticLayers.insert(remoteId)
        } else {
            selectedStaticLayers.remove(remoteId)
        }

        saveSelectedStaticLayers()
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
        }
    }
    
    func startGeoPackageDownload(layer: Layer) {
        MagicalRecord.save { context in
            let localLayer = layer.mr_(in: context)
            localLayer?.downloading = true
            localLayer?.downloadedBytes = 0
        } completion: { didSave, error in
            Layer.downloadGeoPackage(layer: layer) {
                MagicalRecord.save({ context in
                    if let updated = layer.mr_(in: context) {
                        updated.downloading = false
                        // Mark layer as loaded on success
                        updated.loaded = NSNumber(value: Layer.OFFLINE_LAYER_LOADED)
                    }
                }, completion: { [weak self] didSave, error in
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                })
            } failure: { error in
                MagicalRecord.save({ context in
                    if let updated = layer.mr_(in: context) {
                        updated.downloading = false
                        // Reset downloaded bytes on failure
                        updated.downloadedBytes = 0
                    }
                }, completion: { [weak self] didSave, error in
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                })
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
                        let layers: [Layer] = Layer.mr_findAll(
                            with: NSPredicate(
                                format: "remoteId == %@",
                                argumentArray: [editedLayer.remoteId ?? -1]
                            ),
                            in: context) as? [Layer] ?? []
                        for layer in layers {
                            layer.loaded = nil
                            layer.downloadedBytes = 0
                            layer.downloading = false
                        }
                    } completion: { didSave, error in
                        Task { [weak self] in
                            if let cacheOverlay = await self?.findGeoPackageOverlay(remoteId: editedLayer.remoteId ?? -1) as? GeoPackageCacheOverlay {
                                await self?.deleteCacheOverlay(cacheOverlay)
                            }
                            await self?.tableView.reloadData()
                        }
                    }

                }
            } else if section == Sections.MY_MAPS_SECTION.rawValue {
                Task {
                    if let localOverlay = await CacheOverlays.shared.getByCacheName(editedLayer.name) {
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

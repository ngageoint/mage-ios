//
//  SettingsLocalDataSource.swift
//  MAGE
//
//

import Foundation
import Combine

private struct SettingsLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: SettingsLocalDataSource = SettingsLocalDataSourceImpl()
}

extension InjectedValues {
    var settingsLocalDataSource: SettingsLocalDataSource {
        get { Self[SettingsLocalDataSourceProviderKey.self] }
        set { Self[SettingsLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol SettingsLocalDataSource {
    func getSettings() -> SettingsModel?
    func getSettingsPublisher() -> AnyPublisher<SettingsModel?, Never>
    func handleMapSettingsResponse(response: [AnyHashable: Any]) async
}

class SettingsLocalDataSourceImpl: CoreDataDataSource<Settings>, SettingsLocalDataSource {
    
    var settingsPublisher: AnyPublisher<SettingsModel?, Never> {
        settingsSubject.eraseToAnyPublisher()
    }
    
    var cancellable = Set<AnyCancellable>()

    private var settingsSubject: CurrentValueSubject<SettingsModel?, Never> = CurrentValueSubject<SettingsModel?, Never>(nil)
    
    var settingsResultsController: NSFetchedResultsController<Settings>?
        
    override init() {
        super.init()
        Task {
            persistence.contextChange
                .sink { [weak self] _ in
                    self?.setUpSettingsFetchedResultsController()
                }
                .store(in: &cancellables)
            setUpSettingsFetchedResultsController()
        }
    }
    
    func setUpSettingsFetchedResultsController() {
        guard let context else { return }
        let fetchRequest: NSFetchRequest<Settings> = Settings.fetchRequest()
        fetchRequest.predicate = NSPredicate(value: true)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "mapSearchUrl", ascending: false)]
        
        self.settingsResultsController = NSFetchedResultsController<Settings>(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        self.settingsResultsController?.delegate = self
        try? self.settingsResultsController?.performFetch()
        if let settings = self.settingsResultsController?.fetchedObjects,
           let firstSettings = settings.first
        {
            settingsSubject.send(SettingsModel(settings: firstSettings))
        }
    }
    
    func getSettingsPublisher() -> AnyPublisher<SettingsModel?, Never> {
        settingsPublisher
    }
    
    func getSettings() -> SettingsModel? {
        return settingsSubject.value
    }
    
    func handleMapSettingsResponse(response: [AnyHashable: Any]) async {
        guard let context = context else {
            return
        }
        
        await context.perform {
            let settings: Settings = {
                if let settings = try? context.fetchFirst(Settings.self) {
                    return settings
                } else {
                    let settings = Settings(context: context)
                    try? context.obtainPermanentIDs(for: [settings])
                    return settings
                }
            }()

            settings.populate(response)
            try? context.save()
        }
    }
}

extension SettingsLocalDataSourceImpl: NSFetchedResultsControllerDelegate {
    public func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        if let settings = anObject as? Settings {
            switch type {
            case .insert:
                settingsSubject.send(SettingsModel(settings: settings))
            case .delete:
                settingsSubject.send(nil)
                break
            case .move:
                break
            case .update:
                MageLogger.misc.debug("Settings updated to \(settings)")
                settingsSubject.send(SettingsModel(settings: settings))
            @unknown default:
                break
            }
        }
    }
}

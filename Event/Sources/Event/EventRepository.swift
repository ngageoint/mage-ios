public protocol EventRepository: Sendable {
    func getEvents() async -> [EventModel]
}

final class EventRepositoryImpl: EventRepository {
    let localDataSource: EventLocalDataSource
    
    init(localDataSource: EventLocalDataSource) {
        self.localDataSource = localDataSource
    }
    
    func getEvents() async -> [EventModel] {
        await localDataSource.getEvents()
    }
}

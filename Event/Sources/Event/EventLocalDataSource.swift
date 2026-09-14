import Persistence

protocol EventLocalDataSource: Actor {
    func getEvents() async -> [EventModel]
}

actor EventCoreDataDataSource: EventLocalDataSource {
    var persistence: PersistenceProtocol
    
    init(
        persistence: PersistenceProtocol,
    ) {
        self.persistence = persistence
    }
    
    func getEvents() async -> [EventModel] {
        let events = await persistence.read { context in
            return context.fetchAll(Event.self)?.map({ event in
                EventModel(from: event)
            }) ?? []
        }
        return events
    }
}

import Testing
@testable import Event

actor EventLocalDataSourceSpy: EventLocalDataSource {
    var eventsToReturn: [EventModel] = []
    func updateEventsToReturn(_ events: [EventModel]) {
        eventsToReturn = events
    }
    
    func getEvents() async -> [EventModel] {
        eventsToReturn
    }

    
}

@Test func getEvents() async throws {
    let spy = EventLocalDataSourceSpy()
    let repository = EventRepositoryImpl(localDataSource: spy)
    await spy.updateEventsToReturn([EventModel(name: "Event1")])
    
    let events = await repository.getEvents()
    #expect(events.count == 1)
    #expect(events.first?.name == "Event1")
}

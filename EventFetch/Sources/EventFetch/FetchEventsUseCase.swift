import UseCaseFactory
import FetchOperation
import Event

public struct FetchEventsResult {
    public let eventsChanged: Bool
    public let events: [EventModel]
}

public final class FetchEventsUseCase: Sendable, UseCase {
    let repository: AnyFetchRepository<Void, EventRepositoryFetchResult>
    let eventRepository: EventRepository
    
    public init(
        repository: AnyFetchRepository<Void, EventRepositoryFetchResult>,
        eventRepository: EventRepository
    ) {
        self.repository = repository
        self.eventRepository = eventRepository
    }
    
    public func execute() async throws -> FetchEventsResult {
        let operation = repository.startFetch()
        let output = try await operation.value()
        EventFetchPackage.logger.info("Fetched Events: Inserted \(output.eventSaveResult?.inserted ?? 0), updated \(output.eventSaveResult?.updated ?? 0), deleted \(output.eventSaveResult?.deleted ?? 0) events")
        let models = await eventRepository.getEvents()
        
        return FetchEventsResult(
            eventsChanged: (output.eventSaveResult?.totalChanged ?? 0) != 0,
            events: models
        )
        
    }
}

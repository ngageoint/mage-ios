import Foundation
import APIRouter
import Persistence

public class EventRepositoryFactory {
    public static func createRepository(
        url: URL,
        session: TokenAPISession,
        persistence: PersistenceProtocol,
    ) -> EventRepository {
        return EventRepositoryImpl(
            localDataSource: EventCoreDataDataSource(
                persistence: persistence
            )
        )
    }
}

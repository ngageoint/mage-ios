import ServerDTO
import FetchOperation

public protocol EventFetchLocal: FetchLocalDataSource where DTO == EventDTO, SaveResult == EventSaveResult {
    
}

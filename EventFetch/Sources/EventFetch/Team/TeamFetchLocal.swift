import ServerDTO
import FetchOperation

public protocol TeamFetchLocal: FetchLocalDataSource where DTO == EventTeamDTO, SaveResult == TeamSaveResult {
}

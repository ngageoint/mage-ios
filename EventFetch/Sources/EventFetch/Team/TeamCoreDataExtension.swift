import Foundation
import Persistence
import ServerDTO

extension Team {
    func apply(dto: TeamDTO) {
        self.remoteId = dto.id
        self.name = dto.name
        self.teamDescription = dto.description
    }
}

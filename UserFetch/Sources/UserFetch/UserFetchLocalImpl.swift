//
//  UserFetchLocal.swift
//  MAGE
//
//

import Persistence
import FetchOperation
import ServerDTO
import User
import CoreData
import Pipeline
import User

final class UserFetchLocalImpl: UserFetchLocal {
    typealias DTO = UserDTO
    typealias SaveResult = UserSaveResult
    
    let persistence: PersistenceProtocol
    let userImporter: UserImporter
    
    init(persistence: PersistenceProtocol) {
        self.persistence = persistence
        userImporter = UserImporterImpl()
    }

    func save(
        _ dto: [UserDTO],
        progress: @escaping OperationProgressHandler
    ) async throws -> SaveResult {
        let persistenceResult = try await persistence.write { context in
            let totalCount = Int64(dto.count)
            var saveCount: Int64 = 0
            for user in dto {
                let _ = try self.userImporter.importUser(user, context: context)
                saveCount += 1
                
                if saveCount % 50 == 0 {
                    try Task.checkCancellation()
                    progress(
                        OperationProgress(
                            completed: saveCount,
                            total: totalCount
                        )
                    )
                }
            }
            
            progress(
                OperationProgress(
                    completed: saveCount,
                    total: totalCount
                )
            )
            UserFetchPackage.logger.info("Saved \(saveCount) users")
            return saveCount
        }
        
        return UserSaveResult(saveCount: Int(persistenceResult.blockReturn ?? 0))
    }
}

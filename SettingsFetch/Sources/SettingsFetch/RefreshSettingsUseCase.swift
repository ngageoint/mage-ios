// 
//     
//  RefreshSettingsUseCase.swift
//  SettingsFetch
//
// 


import ServerDTO
import FetchOperation
import UseCaseFactory
import Settings

public final class RefreshSettingsUseCase: Sendable, UseCase {

    private let repository: SettingsRepository
    private let fetchRepository: AnyFetchRepository<Void, [MapSettingsDTO]>

    public init(
        repository: SettingsRepository,
        fetchRepository: AnyFetchRepository<Void, [MapSettingsDTO]>
    ) {
        self.repository = repository
        self.fetchRepository = fetchRepository
    }

    public func execute() async throws -> SettingsModel? {
        let operation = fetchRepository.startFetch()
        let _ = try await operation.value()
        return await repository.getSettings()
    }
}

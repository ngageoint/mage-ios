// 
//     
//  ObserveSettingsUseCase.swift
//  Settings
//
// 


public protocol ObserveSettingsUseCase: Sendable {
    func execute() -> AsyncStream<SettingsModel>
}

public final class ObserveSettingsUseCaseImpl: ObserveSettingsUseCase {
    
    private let repository: SettingsRepository
    
    public init(repository: SettingsRepository) {
        self.repository = repository
    }
    
    public func execute() -> AsyncStream<SettingsModel> {
        repository.observeSettings()
    }
}

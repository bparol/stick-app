import Foundation

struct DomainItem: Codable, Equatable, Identifiable, Sendable {
    let id: String
    var name: String

    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}

enum DomainValidationError: LocalizedError, Equatable {
    case emptyName
    case storeUnavailable
    case missingDomain
    case invalidOrder
    case sessionInProgress

    var errorDescription: String? {
        switch self {
        case .emptyName:
            "Give your domain a name."
        case .missingDomain:
            "This domain no longer exists. Close the editor and try again."
        case .sessionInProgress:
            "Stop the current session before choosing another domain."
        case .invalidOrder:
            "The list has changed. Please try moving the domain again."
        case .storeUnavailable:
            "Your saved domains couldn't be loaded. Close and reopen the app to try again."
        }
    }
}

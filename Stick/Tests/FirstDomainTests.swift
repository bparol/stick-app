import Foundation
import Testing
@testable import Stick

@MainActor
struct FirstDomainTests {
    @Test func missingStoreStartsWithNoDomains() throws {
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = DomainStore(fileURL: folder.appending(path: "domains.json"))
        #expect(try store.load().isEmpty)
        let model = AppModel(store: store)
        #expect(model.domains.isEmpty)
        #expect(model.loadError == nil)
    }

    @Test func addingTrimsNameAndPersistsStableStringIDsInOrder() throws {
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = DomainStore(fileURL: folder.appending(path: "domains.json"))
        let model = AppModel(store: store)
        try model.addDomain(named: "  Guitar\n")
        try model.addDomain(named: "Reading")
        #expect(model.domains.map(\.name) == ["Guitar", "Reading"])
        #expect(model.domains.allSatisfy { !$0.id.isEmpty })
        #expect(Set(model.domains.map(\.id)).count == 2)

        let restored = AppModel(store: store)
        #expect(restored.domains == model.domains)
        #expect(restored.loadError == nil)
    }

    @Test func blankNamesDoNotChangeTheModelOrStore() throws {
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = DomainStore(fileURL: folder.appending(path: "domains.json"))
        let model = AppModel(store: store)
        try model.addDomain(named: "Drawing")
        let original = model.domains
        #expect(throws: DomainValidationError.emptyName) {
            try model.addDomain(named: " \n\t")
        }
        #expect(model.domains == original)
        #expect(try store.load() == original)
    }

    @Test func failedSaveDoesNotPublishAnUnsavedDomain() throws {
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "domains.json")
        let model = AppModel(store: DomainStore(fileURL: url))
        // A directory at the file destination produces a real write failure.
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        #expect(throws: (any Error).self) { try model.addDomain(named: "Guitar") }
        #expect(model.domains.isEmpty)
    }

    @Test func unreadableStoreIsNotSilentlyOverwritten() throws {
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: "domains.json")
        let original = Data("not a valid domains snapshot".utf8)
        try original.write(to: url)
        let model = AppModel(store: DomainStore(fileURL: url))
        #expect(model.loadError != nil)
        #expect(throws: DomainValidationError.storeUnavailable) {
            try model.addDomain(named: "Guitar")
        }
        #expect(try Data(contentsOf: url) == original)
    }

    private func temporaryFolder() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "FirstDomainTests-\(UUID().uuidString)")
    }
}

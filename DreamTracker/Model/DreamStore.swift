import Foundation
import CryptoKit

// MARK: - Dream Store (with device-key encryption)

public final class DreamStore {
    private let documentsURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // MARK: Paths

    private var dreamsURL: URL {
        documentsURL.appendingPathComponent("dreams_v2.enc")
    }
    private var journalURL: URL {
        documentsURL.appendingPathComponent("journal_v2.enc")
    }

    // MARK: Crypto Helpers

    private func encrypt(_ data: Data) throws -> Data {
        let key = try DeviceKeychain.getOrCreateKey()
        let sealed = try AES.GCM.seal(data, using: key)
        return sealed.combined!
    }

    private func decrypt(_ data: Data) throws -> Data {
        let key = try DeviceKeychain.getOrCreateKey()
        let sealed = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealed, using: key)
    }

    private func writeEncrypted(_ data: Data, to url: URL) throws {
        let encrypted = try encrypt(data)
        try encrypted.write(to: url, options: .completeFileProtection)
    }

    private func readEncrypted(from url: URL) throws -> Data {
        let encrypted = try Data(contentsOf: url)
        return try decrypt(encrypted)
    }

    // MARK: Dreams

    public func fetchDreams() async throws -> [Dream] {
        guard FileManager.default.fileExists(atPath: dreamsURL.path) else { return [] }
        let data = try readEncrypted(from: dreamsURL)
        return try decoder.decode([Dream].self, from: data)
    }

    public func saveDream(_ dream: Dream) async throws {
        var dreams = try await fetchDreams()
        if let idx = dreams.firstIndex(where: { $0.id == dream.id }) {
            dreams[idx] = dream
        } else {
            dreams.append(dream)
        }
        let data = try encoder.encode(dreams)
        try writeEncrypted(data, to: dreamsURL)
        syncWidgetData(dreams)
    }

    public func toggleDream(id: UUID) async throws {
        var dreams = try await fetchDreams()
        guard let idx = dreams.firstIndex(where: { $0.id == id }) else { return }
        dreams[idx].isCompleted.toggle()
        dreams[idx].completedAt = dreams[idx].isCompleted ? Date() : nil
        let data = try encoder.encode(dreams)
        try writeEncrypted(data, to: dreamsURL)
        syncWidgetData(dreams)
    }

    public func deleteDream(id: UUID) async throws {
        var dreams = try await fetchDreams()
        dreams.removeAll { $0.id == id }
        let data = try encoder.encode(dreams)
        try writeEncrypted(data, to: dreamsURL)
        syncWidgetData(dreams)
    }

    public func seedIfEmpty() async throws {
        let existing = try await fetchDreams()
        guard existing.isEmpty else { return }
        for dream in Dream.seedDreams() {
            try await saveDream(dream)
        }
    }

    // MARK: Journal

    public func fetchEntries() async throws -> [JournalEntry] {
        guard FileManager.default.fileExists(atPath: journalURL.path) else { return [] }
        let data = try readEncrypted(from: journalURL)
        return try decoder.decode([JournalEntry].self, from: data)
    }

    public func saveEntry(_ entry: JournalEntry) async throws {
        var entries = try await fetchEntries()
        entries.insert(entry, at: 0)
        let data = try encoder.encode(entries)
        try writeEncrypted(data, to: journalURL)
    }

    // MARK: Destroy

    public func destroyAll() throws {
        for url in [dreamsURL, journalURL] {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        }
        // Clean widget data
        if let widgetURL = widgetDataURL {
            if FileManager.default.fileExists(atPath: widgetURL.path) {
                try? FileManager.default.removeItem(at: widgetURL)
            }
        }
    }

    // MARK: - Widget Data (App Group mirror)

    private var widgetDataURL: URL? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.dreamtracker.app"
        ) else { return nil }
        return container.appendingPathComponent("dreams_v2.enc")
    }

    private func syncWidgetData(_ dreams: [Dream]) {
        guard let url = widgetDataURL else { return }
        let data = (try? encoder.encode(dreams)) ?? Data()
        try? data.write(to: url, options: .atomic)
    }
}

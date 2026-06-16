import WidgetKit
import SwiftUI

// MARK: - Provider

struct DreamProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamEntry {
        DreamEntry(
            date: Date(),
            totalCompleted: 3,
            totalDreams: 7,
            focusDream: "Launch my own business",
            focusHorizon: "3Y"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DreamEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamEntry>) -> Void) {
        let entry = loadEntry()
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func loadEntry() -> DreamEntry {
        let dreams = SharedStore.loadDreams()
        let totalCompleted = dreams.filter(\.isCompleted).count
        let totalDreams = dreams.count

        // Find the first incomplete dream across all horizons, prioritized by shorter timeframes
        let horizonOrder: [TimeHorizon] = [.sixMonths, .oneYear, .threeYears, .fiveYears, .tenYears]
        var focusDream = "Add your first dream"
        var focusHorizon = ""

        for horizon in horizonOrder {
            if let dream = dreams.first(where: { $0.horizon == horizon && !$0.isCompleted }) {
                focusDream = dream.title
                focusHorizon = horizon.shortLabel
                break
            }
        }

        // If all dreams are complete
        if focusHorizon.isEmpty, let first = dreams.first {
            focusDream = first.title
            focusHorizon = first.horizon.shortLabel
        }

        return DreamEntry(
            date: Date(),
            totalCompleted: totalCompleted,
            totalDreams: totalDreams,
            focusDream: focusDream,
            focusHorizon: focusHorizon
        )
    }
}

// MARK: - Entry

struct DreamEntry: TimelineEntry {
    let date: Date
    let totalCompleted: Int
    let totalDreams: Int
    let focusDream: String
    let focusHorizon: String
}

// MARK: - Shared Store (reads from App Group)

enum SharedStore {
    private static let appGroupID = "group.com.dreamtracker.app"

    static func loadDreams() -> [Dream] {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return []
        }
        let url = container.appendingPathComponent("dreams_v2.enc")
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return (try? JSONDecoder().decode([Dream].self, from: data)) ?? []
    }
}

// MARK: - Widget Views

struct DreamWidgetEntryView: View {
    var entry: DreamEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Progress ring
            HStack {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.15), lineWidth: 3)
                        .frame(width: 28, height: 28)

                    Circle()
                        .trim(from: 0, to: entry.totalDreams > 0
                              ? CGFloat(entry.totalCompleted) / CGFloat(entry.totalDreams)
                              : 0)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                }

                Text("\(entry.totalCompleted)/\(entry.totalDreams)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Focus dream
            if !entry.focusHorizon.isEmpty {
                Text(entry.focusHorizon)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue.opacity(0.1)))
            }

            Text(entry.focusDream)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
    }
}

// MARK: - Circular Widget (Lock Screen / Accessory)

struct DreamCircularView: View {
    var entry: DreamEntry

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 4)

            Circle()
                .trim(from: 0, to: entry.totalDreams > 0
                      ? CGFloat(entry.totalCompleted) / CGFloat(entry.totalDreams)
                      : 0)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(entry.totalCompleted)")
                    .font(.system(size: 18, weight: .bold))
                Text("/\(entry.totalDreams)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Widget Configuration

struct DreamWidget: Widget {
    let kind = "DreamWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamProvider()) { entry in
            DreamWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Dream Progress")
        .description("See your focus dream and overall progress at a glance.")
        .supportedFamilies([.systemSmall])

        // Lock Screen circular
        StaticConfiguration(kind: "DreamCircular", provider: DreamProvider()) { entry in
            DreamCircularView(entry: entry)
        }
        .configurationDisplayName("Dreams Completed")
        .description("Quick progress ring.")
        .supportedFamilies([.accessoryCircular])
    }
}

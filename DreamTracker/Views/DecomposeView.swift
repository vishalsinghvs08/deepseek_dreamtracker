import SwiftUI

// MARK: - Decompose View

struct DecomposeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    let parentDream: Dream

    @State private var subDreamsByHorizon: [TimeHorizon: [String]] = [:]

    private var childHorizons: [TimeHorizon] {
        let allCases = TimeHorizon.allCases
        guard let idx = allCases.firstIndex(of: parentDream.horizon), idx > 0 else { return [] }
        return Array(allCases[0..<idx].reversed())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    parentCard
                        .padding(.top, 16)

                    if !childHorizons.isEmpty {
                        connectingStem
                    }

                    ForEach(Array(childHorizons.enumerated()), id: \.element) { i, horizon in
                        if i > 0 {
                            branchConnector
                        }
                        levelSection(horizon: horizon)
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Decompose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                saveButton
            }
            .onAppear {
                seedSuggestions()
            }
        }
    }

    // MARK: - Parent Card

    private var parentCard: some View {
        VStack(spacing: 10) {
            Text("Parent Dream")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(horizonColor(parentDream.horizon).opacity(0.7))
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(horizonColor(parentDream.horizon))
                Text(parentDream.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                horizonBadge(parentDream.horizon)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(horizonColor(parentDream.horizon).opacity(0.5), lineWidth: 2)
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Connecting Line (stem from parent)

    private var connectingStem: some View {
        Rectangle()
            .fill(horizonColor(parentDream.horizon).opacity(0.3))
            .frame(width: 2, height: 24)
    }

    // MARK: - Branch Connector

    private var branchConnector: some View {
        HStack(spacing: 0) {
            Spacer()
            Rectangle()
                .fill(Color(.systemGray4).opacity(0.5))
                .frame(width: 2, height: 16)
            Spacer()
        }
    }

    // MARK: - Level Section

    private func levelSection(horizon: TimeHorizon) -> some View {
        let items = subDreamsByHorizon[horizon] ?? []
        let color = horizonColor(horizon)
        let indent = CGFloat(childHorizons.firstIndex(of: horizon) ?? 0) * 16

        return VStack(spacing: 0) {
            // Horizon header with color bar
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: 28)
                Text(horizon.shortLabel)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                horizonBadge(horizon)
                Spacer()
                if !items.isEmpty {
                    Text("\(items.count) dream\(items.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            // Sub-dream list
            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, text in
                    subDreamRow(horizon: horizon, idx: idx, text: text, color: color)
                }
                addSubDreamButton(horizon: horizon, color: color)
            }
            .padding(.horizontal, 20 + indent)

            // Connector stem below
            if horizon != childHorizons.last {
                Rectangle()
                    .fill(color.opacity(0.25))
                    .frame(width: 2, height: 20)
            }
        }
    }

    private func subDreamRow(horizon: TimeHorizon, idx: Int, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 8, height: 8)
            TextField("Sub-dream at \(horizon.shortLabel)...", text: Binding(
                get: { text },
                set: { newValue in
                    subDreamsByHorizon[horizon]?[idx] = newValue
                }
            ))
            .font(.callout)
            Button {
                subDreamsByHorizon[horizon]?.remove(at: idx)
                if subDreamsByHorizon[horizon]?.isEmpty == true {
                    subDreamsByHorizon[horizon] = []
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.caption)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    private func addSubDreamButton(horizon: TimeHorizon, color: Color) -> some View {
        Button {
            if subDreamsByHorizon[horizon] == nil {
                subDreamsByHorizon[horizon] = []
            }
            subDreamsByHorizon[horizon]?.append("")
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.callout)
                Text("Add sub-dream for \(horizon.shortLabel)")
                    .font(.callout)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.08))
            )
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        let allSubDreams = collectSubDreams()
        let hasContent = !allSubDreams.isEmpty

        return Button {
            saveAll()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.fill")
                Text("Save All (\(allSubDreams.count) dreams)")
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(hasContent ? Color.blue : Color.blue.opacity(0.3))
            )
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(!hasContent)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Helpers

    private func collectSubDreams() -> [(title: String, horizon: TimeHorizon)] {
        var result: [(String, TimeHorizon)] = []
        for horizon in childHorizons {
            for text in subDreamsByHorizon[horizon] ?? [] {
                let trimmed = text.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    result.append((trimmed, horizon))
                }
            }
        }
        return result
    }

    private func saveAll() {
        let subs = collectSubDreams()
        guard !subs.isEmpty else { return }
        viewModel.decomposeDream(parentID: parentDream.id, subDreams: subs)
        dismiss()
    }

    private func seedSuggestions() {
        for horizon in childHorizons {
            let suggestions = defaultSuggestions(for: horizon, parentTitle: parentDream.title)
            if subDreamsByHorizon[horizon] == nil {
                subDreamsByHorizon[horizon] = suggestions
            }
        }
    }

    private func defaultSuggestions(for horizon: TimeHorizon, parentTitle: String) -> [String] {
        switch horizon {
        case .fiveYears:
            return [
                "Build a foundation for \(parentTitle)",
                "Develop key skills for \(parentTitle)",
                "Create a roadmap for \(parentTitle)"
            ]
        case .threeYears:
            return [
                "First major milestone for \(parentTitle)",
                "Establish core systems",
                "Achieve early traction"
            ]
        case .oneYear:
            return [
                "Learn fundamentals of \(parentTitle)",
                "Complete first project",
                "Build initial habits"
            ]
        case .sixMonths:
            return [
                "Research and plan approach",
                "Start small experiment",
                "Define success metrics"
            ]
        default:
            return []
        }
    }

    private func horizonColor(_ horizon: TimeHorizon) -> Color {
        switch horizon {
        case .tenYears:   return .blue
        case .fiveYears:  return .purple
        case .threeYears: return .orange
        case .oneYear:    return .teal
        case .sixMonths:  return .green
        }
    }

    private func horizonBadge(_ horizon: TimeHorizon) -> some View {
        Text(horizon.shortLabel)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(horizonColor(horizon))
            )
    }
}

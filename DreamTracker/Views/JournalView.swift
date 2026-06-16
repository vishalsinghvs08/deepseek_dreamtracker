import SwiftUI

// MARK: - Journal View

struct JournalView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showWriteSheet = false
    @State private var entryText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient underlay
                LinearGradient(
                    colors: [
                        Color.indigo.opacity(0.04),
                        Color(.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                Group {
                    if viewModel.journalEntries.isEmpty {
                        emptyState
                    } else {
                        entryList
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showWriteSheet = true } label: {
                        Image(systemName: "square.and.pencil")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showWriteSheet) { writeSheet }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "book.pages")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.blue.opacity(0.4))
                .symbolRenderingMode(.hierarchical)
            Text("Your Journal")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Capture thoughts about your progress,\nsetbacks, and wins along the way.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button { showWriteSheet = true } label: {
                Label("Write First Entry", systemImage: "pencil")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.blue))
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Entry List

    private var entryList: some View {
        List {
            ForEach(viewModel.journalEntries) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(entry.content)
                        .font(.body)
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 6)
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    // Accent border
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 3)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Write Sheet

    private var writeSheet: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                TextEditor(text: $entryText)
                    .font(.body)
                    .focused($isFocused)
                    .padding()
                    .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showWriteSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                        .fontWeight(.semibold)
                        .disabled(entryText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationBackground(.regularMaterial)
    }

    private func saveEntry() {
        let text = entryText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        viewModel.addJournalEntry(content: text)
        entryText = ""
        showWriteSheet = false
    }
}

#Preview {
    JournalView()
        .environmentObject(AppViewModel())
}

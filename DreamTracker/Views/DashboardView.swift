import SwiftUI

// MARK: - Dashboard View (Tab 1: "Today")

struct DashboardView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showSettings = false

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 24)

                    hero
                        .padding(.top, 48)
                        .padding(.horizontal, 24)

                    habitsSection
                        .padding(.top, 48)
                        .padding(.horizontal, 24)

                    quarterSection
                        .padding(.top, 48)
                        .padding(.bottom, 48)
                        .padding(.horizontal, 24)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(isPresented: $showSettings)
                .environmentObject(viewModel)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("DreamTracker")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.secondary)

            Spacer()

            Button {
                let g = UIImpactFeedbackGenerator(style: .light)
                g.impactOccurred()
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(DS.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 10) {
            Text(viewModel.goal?.title ?? Goal.defaultTemplate.title)
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(DS.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let why = viewModel.goal?.why, !why.isEmpty {
                Text(why)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(DS.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Habits Section

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Today's Habits")

            if viewModel.habits.isEmpty {
                emptyHabits
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.habits.enumerated()), id: \.element.id) { idx, habit in
                        HabitRowView(habit: habit) {
                            let g = UIImpactFeedbackGenerator(style: .medium)
                            g.impactOccurred()
                            viewModel.toggleHabit(id: habit.id)
                        }

                        if idx < viewModel.habits.count - 1 {
                            DS.border
                                .frame(height: 1)
                                .padding(.leading, 40)
                        }
                    }
                }
                .background(DS.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DS.border, lineWidth: 1)
                )
            }
        }
    }

    private var emptyHabits: some View {
        VStack(spacing: 8) {
            Text("No habits yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(DS.secondary)
            Text("Add your first daily habit to start tracking.")
                .font(.system(size: 13))
                .foregroundColor(DS.secondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(DS.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DS.border, lineWidth: 1)
        )
    }

    // MARK: - This Quarter

    private var quarterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("This Quarter")

            if let next = nextMilestone {
                HStack(spacing: 12) {
                    Circle()
                        .fill(DS.accent)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(next.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(DS.primary)

                        if let quarter = next.quarter {
                            Text("Year \(next.year) · Q\(quarter)")
                                .font(.system(size: 12))
                                .foregroundColor(DS.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DS.secondary.opacity(0.5))
                }
                .padding(16)
                .background(DS.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DS.border, lineWidth: 1)
                )
            } else {
                Text("No upcoming milestones")
                    .font(.system(size: 15))
                    .foregroundColor(DS.secondary)
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(DS.secondary.opacity(0.55))
            .tracking(2)
            .padding(.bottom, 14)
    }

    private var nextMilestone: Milestone? {
        viewModel.milestones
            .filter { !$0.isCompleted }
            .sorted { $0.order < $1.order }
            .first
    }
}

// MARK: - Habit Row View (Tap‑Based)

struct HabitRowView: View {
    let habit: Habit
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Circle indicator
                ZStack {
                    Circle()
                        .stroke(habit.isCompletedToday ? DS.accent : DS.border, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if habit.isCompletedToday {
                        Circle()
                            .fill(DS.accent)
                            .frame(width: 14, height: 14)
                    }
                }

                // Title
                Text(habit.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(habit.isCompletedToday ? DS.secondary : DS.primary)
                    .strikethrough(habit.isCompletedToday, color: DS.secondary)

                Spacer()

                // Streak
                if habit.streakDays > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(habit.isCompletedToday ? DS.accent : DS.secondary.opacity(0.4))

                        Text("\(habit.streakDays)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(habit.isCompletedToday ? DS.accent.opacity(0.8) : DS.secondary.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Sheet (Presented via .sheet)

struct SettingsSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: AppViewModel

    @State private var faceIDEnabled: Bool = true
    @State private var notificationsEnabled: Bool = true
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Security
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("SECURITY")

                            HStack {
                                Image(systemName: "faceid")
                                    .font(.system(size: 16))
                                    .foregroundColor(DS.accent)
                                    .frame(width: 24)

                                Text("Face ID / Touch ID")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DS.primary)

                                Spacer()

                                Toggle("", isOn: $faceIDEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: DS.accent))
                                    .labelsHidden()
                                    .onChange(of: faceIDEnabled) { newValue in
                                        viewModel.setFaceIDEnabled(newValue)
                                    }
                            }
                        }
                    }

                    // Notifications
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("NOTIFICATIONS")

                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(DS.accent)
                                    .frame(width: 24)

                                Text("Daily Reminders")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DS.primary)

                                Spacer()

                                Toggle("", isOn: $notificationsEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: DS.accent))
                                    .labelsHidden()
                            }
                        }
                    }

                    // Theme
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("THEME")

                            HStack {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.system(size: 16))
                                    .foregroundColor(DS.accent)
                                    .frame(width: 24)

                                Text("Appearance")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(DS.primary)

                                Spacer()

                                Picker("", selection: .constant(0)) {
                                    Text("System").tag(0)
                                    Text("Light").tag(1)
                                    Text("Dark").tag(2)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 170)
                            }
                        }
                    }

                    // Danger
                    settingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("DANGER ZONE")

                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(DS.danger)
                                        .frame(width: 24)

                                    Text("Delete Account")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(DS.danger)

                                    Spacer()

                                    Text("Permanently wipe all data")
                                        .font(.system(size: 12))
                                        .foregroundColor(DS.danger.opacity(0.5))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(DS.bg)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(DS.secondary)
                    }
                }
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Data & Account", role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your data and account. This action cannot be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(DS.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DS.border, lineWidth: 1)
            )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(DS.secondary.opacity(0.55))
            .tracking(1.5)
    }
}

// MARK: - Settings Panel Overlay (kept for backward compatibility)

struct SettingsPanelOverlay: View {
    @Binding var isPresented: Bool

    @State private var faceIDEnabled: Bool = true
    @State private var notificationsEnabled: Bool = true
    @State private var showDeleteConfirmation: Bool = false

    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                HStack {
                    Text("Settings")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SECURITY")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.25))
                                    .tracking(1.5)

                                HStack {
                                    Image(systemName: "faceid")
                                        .font(.system(size: 16))
                                        .foregroundColor(DS.accent)
                                        .frame(width: 24)
                                    Text("Face ID / Touch ID")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Toggle("", isOn: $faceIDEnabled)
                                        .toggleStyle(SwitchToggleStyle(tint: DS.accent))
                                        .labelsHidden()
                                        .onChange(of: faceIDEnabled) { newValue in
                                            viewModel.setFaceIDEnabled(newValue)
                                        }
                                }
                            }
                        }

                        card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("NOTIFICATIONS")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.25))
                                    .tracking(1.5)

                                HStack {
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(DS.accent)
                                        .frame(width: 24)
                                    Text("Daily Reminders")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Toggle("", isOn: $notificationsEnabled)
                                        .toggleStyle(SwitchToggleStyle(tint: DS.accent))
                                        .labelsHidden()
                                }
                            }
                        }

                        card {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("DANGER ZONE")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.25))
                                    .tracking(1.5)

                                Button(action: { showDeleteConfirmation = true }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.red)
                                            .frame(width: 24)
                                        Text("Delete Account")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.red.opacity(0.9))
                                        Spacer()
                                        Text("Permanently wipe all data")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red.opacity(0.5))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 40, x: 0, y: -10)
            .padding(.top, 40)
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Data & Account", role: .destructive) {
                Task { await viewModel.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your data and account. This action cannot be undone.")
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.825)) {
            isPresented = false
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Preview

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = AppViewModel()
        vm.goal = Goal(
            title: "Build a life of creative freedom and meaningful work",
            why: "Because autonomy over my time is the ultimate wealth."
        )
        vm.habits = Goal.defaultHabits
        vm.milestones = Goal.defaultMilestones

        return DashboardView()
            .environmentObject(vm)
            .preferredColorScheme(.dark)
    }
}
#endif

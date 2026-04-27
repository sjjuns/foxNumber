import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var allNumbers: [LottoNumber]

    @AppStorage("notificationEnabled") private var notificationEnabled = false
    @AppStorage("selectedIcon") private var selectedIcon = "dark_gold"
    @State private var showDeleteAlert = false
    @State private var showDeletedToast = false

    let appIcons = [
        ("dark_gold",   "다크 골드",   "🌟"),
        ("black_red",   "블랙 레드",   "🔴"),
        ("dark_silver", "다크 실버",   "⚪️")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()

                List {
                    // 알림
                    notificationSection

                    // 앱 아이콘
                    iconSection

                    // 데이터
                    dataSection

                    // 기타
                    miscSection

                    // 버전
                    Section {
                        HStack {
                            Spacer()
                            Text("버전 1.0.0")
                                .font(.caption)
                                .foregroundColor(DesignSystem.textSecondary)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                if showDeletedToast {
                    VStack {
                        Spacer()
                        Text("번호가 모두 삭제되었습니다")
                            .font(.subheadline.bold())
                            .foregroundColor(DesignSystem.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(DesignSystem.cardBackground)
                            .clipShape(Capsule())
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("번호 초기화", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) { deleteAll() }
            } message: {
                Text("저장된 번호 \(allNumbers.count)개를 모두 삭제합니다.")
            }
        }
    }

    // MARK: - 알림 섹션
    private var notificationSection: some View {
        Section("알림") {
            Toggle(isOn: $notificationEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("추첨일 알림")
                        .foregroundColor(DesignSystem.textPrimary)
                    Text("매주 토요일 오후 8:35")
                        .font(.caption)
                        .foregroundColor(DesignSystem.textSecondary)
                }
            }
            .tint(DesignSystem.gold)
            .listRowBackground(DesignSystem.cardBackground)
            .onChange(of: notificationEnabled) { _, enabled in
                enabled ? requestNotification() : cancelNotification()
            }
        }
    }

    // MARK: - 아이콘 섹션
    private var iconSection: some View {
        Section("앱 아이콘") {
            ForEach(appIcons, id: \.0) { id, name, emoji in
                Button {
                    selectedIcon = id
                } label: {
                    HStack {
                        Text(emoji)
                        Text(name)
                            .foregroundColor(DesignSystem.textPrimary)
                        Spacer()
                        if selectedIcon == id {
                            Image(systemName: "checkmark")
                                .foregroundColor(DesignSystem.gold)
                        }
                    }
                }
                .listRowBackground(DesignSystem.cardBackground)
            }
        }
    }

    // MARK: - 데이터 섹션
    private var dataSection: some View {
        Section("데이터") {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Text("저장된 번호 초기화")
                    Spacer()
                    Text("\(allNumbers.count)개")
                        .font(.caption)
                        .foregroundColor(DesignSystem.textSecondary)
                }
            }
            .listRowBackground(DesignSystem.cardBackground)
        }
    }

    // MARK: - 기타 섹션
    private var miscSection: some View {
        Section("기타") {
            Link(destination: URL(string: "https://apps.apple.com")!) {
                Label("앱 평가하기", systemImage: "star")
                    .foregroundColor(DesignSystem.textPrimary)
            }
            .listRowBackground(DesignSystem.cardBackground)

            ShareLink(item: "로또 번호 생성기 앱을 사용해보세요!") {
                Label("공유하기", systemImage: "square.and.arrow.up")
                    .foregroundColor(DesignSystem.textPrimary)
            }
            .listRowBackground(DesignSystem.cardBackground)

            NavigationLink {
                PrivacyView()
            } label: {
                Label("개인정보처리방침", systemImage: "hand.raised")
                    .foregroundColor(DesignSystem.textPrimary)
            }
            .listRowBackground(DesignSystem.cardBackground)
        }
    }

    // MARK: - Actions
    private func deleteAll() {
        allNumbers.forEach { context.delete($0) }
        try? context.save()
        withAnimation { showDeletedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showDeletedToast = false }
        }
    }

    private func requestNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationEnabled = granted
                if granted { scheduleWeeklyNotification() }
            }
        }
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["lotto_weekly"])
    }

    private func scheduleWeeklyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "오늘은 로또 추첨일! 🎱"
        content.body = "번호를 확인해보세요"
        content.sound = .default

        var components = DateComponents()
        components.weekday = 7  // 토요일
        components.hour = 20
        components.minute = 35

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "lotto_weekly", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - 개인정보처리방침
struct PrivacyView: View {
    var body: some View {
        ZStack {
            DesignSystem.background.ignoresSafeArea()
            ScrollView {
                Text("이 앱은 개인정보를 수집하지 않습니다.\n저장된 번호는 기기에만 보관됩니다.")
                    .foregroundColor(DesignSystem.textPrimary)
                    .padding()
            }
        }
        .navigationTitle("개인정보처리방침")
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: LottoNumber.self, inMemory: true)
        .preferredColorScheme(.dark)
}

import SwiftUI

enum CommunityTab: String, CaseIterable, Identifiable {
    case forYou = "For You"
    case friends = "Friends"
    case sport = "Sport"
    case inbox = "Inbox"

    var id: String { rawValue }
}

struct CommunityView: View {
    @State private var selected: CommunityTab = .forYou
    @State private var dmService = DMService.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            segmentedControl
            Divider().opacity(0.3)
            contentForTab
        }
        .background(ColorTheme.background(colorScheme).ignoresSafeArea())
        .task {
            try? await dmService.loadInbox()
        }
    }

    private var segmentedControl: some View {
        HStack(spacing: 24) {
            ForEach(CommunityTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = tab }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: selected == tab ? .semibold : .regular))
                                .foregroundStyle(selected == tab ? .primary : .secondary)
                            if tab == .inbox && dmService.totalUnread > 0 {
                                Text("\(dmService.totalUnread)")
                                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(ColorTheme.accent))
                            }
                        }
                        Rectangle()
                            .fill(selected == tab ? ColorTheme.accent : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var contentForTab: some View {
        switch selected {
        case .forYou:
            NavigationStack {
                ForYouFeedView()
                    .navigationTitle("Community")
                    .navigationBarTitleDisplayMode(.inline)
            }
        case .friends:
            NavigationStack {
                FriendsFeedView()
            }
        case .sport:
            NavigationStack {
                SportFeedView()
            }
        case .inbox:
            NavigationStack {
                InboxView()
            }
        }
    }
}

private struct CommunityComingSoonView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}

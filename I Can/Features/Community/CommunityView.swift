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
            PageHeader("Community")
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
        HStack(spacing: 0) {
            ForEach(CommunityTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = tab }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: selected == tab ? .semibold : .regular).width(.condensed))
                                .foregroundStyle(selected == tab ? .primary : .secondary)
                            if tab == .inbox && dmService.totalUnread > 0 {
                                Text("\(dmService.totalUnread)")
                                    .font(.system(size: 10, weight: .bold).width(.condensed).monospacedDigit())
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
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var contentForTab: some View {
        switch selected {
        case .forYou:
            NavigationStack {
                ForYouFeedView()
                    .toolbar(.hidden, for: .navigationBar)
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
                .font(.system(size: 20, weight: .semibold).width(.condensed))
            Text(message)
                .font(.system(size: 14).width(.condensed))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}

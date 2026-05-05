import SwiftUI
import SafariServices

struct ArticleReaderView: View {
    let article: SportArticle

    @State private var service = SportFeedService.shared
    @State private var showSafari = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage

                VStack(alignment: .leading, spacing: 16) {
                    Text(article.categoryLabel)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(ColorTheme.accent)

                    Text(article.title)
                        .font(.system(size: 22, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(article.sourceName) · \(relativeTime)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    if !article.bullets.isEmpty {
                        Divider().opacity(0.3)
                        Text("Key takeaways")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(article.bullets, id: \.self) { bullet in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(ColorTheme.accent)
                                        .padding(.top, 4)
                                    Text(bullet)
                                        .font(.system(size: 15))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    Divider().opacity(0.3).padding(.top, 8)

                    Button {
                        Task { await service.track(article: article, action: "open") }
                        showSafari = true
                    } label: {
                        HStack {
                            Text("Read full article")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                        .foregroundStyle(Color.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(ColorTheme.accent, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, article.imageUrl == nil ? 16 : 20)
                .padding(.bottom, 40)
            }
        }
        .background(ColorTheme.background(colorScheme).ignoresSafeArea())
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
        .task { await service.track(article: article, action: "view") }
        .sheet(isPresented: $showSafari) {
            if let url = URL(string: article.sourceUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        if let urlString = article.imageUrl, let url = URL(string: urlString) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .overlay(
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty, .failure:
                            placeholder
                        @unknown default:
                            placeholder
                        }
                    }
                )
                .clipped()
        }
    }

    private var placeholder: some View {
        ZStack {
            ColorTheme.accent.opacity(0.15)
            Image(systemName: "newspaper.fill")
                .font(.system(size: 40))
                .foregroundStyle(ColorTheme.accent.opacity(0.6))
        }
    }

    private var relativeTime: String {
        guard let d = article.publishedDate else { return "" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: d, relativeTo: Date())
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

import SwiftUI

struct ComposePostView: View {
    let onPosted: (CommunityPost) -> Void

    @State private var service = CommunityService.shared
    @State private var draft: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let maxChars = 2000

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                editor
                if let msg = errorMessage {
                    Text(msg)
                        .font(.system(size: 13).width(.condensed))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
                Spacer()
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("New post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { Task { await submit() } }
                        .disabled(!canPost)
                        .fontWeight(.semibold)
                }
            }
        }
        .interactiveDismissDisabled(isSubmitting)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $draft)
                .font(.system(size: 16).width(.condensed))
                .frame(minHeight: 200)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .overlay(alignment: .topLeading) {
                    if draft.isEmpty {
                        Text("What's on your mind?")
                            .font(.system(size: 16).width(.condensed))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 17)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }

            HStack {
                Spacer()
                Text("\(draft.count)/\(maxChars)")
                    .font(.system(size: 12).width(.condensed).monospacedDigit())
                    .foregroundStyle(draft.count > maxChars ? .red : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private var canPost: Bool {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxChars && !isSubmitting
    }

    private func submit() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let post = try await service.createPost(type: "text", body: trimmed)
            onPosted(post)
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Could not post. Try again."
        }
    }
}

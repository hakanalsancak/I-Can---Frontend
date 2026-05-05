import SwiftUI

struct ReportSheet: View {
    let targetKind: String
    let targetId: String
    let onSubmitted: () -> Void

    @State private var selected: ReportReason?
    @State private var note: String = ""
    @State private var isSubmitting = false
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Why are you reporting this?")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                List {
                    ForEach(ReportReason.allCases) { reason in
                        Button {
                            selected = reason
                        } label: {
                            HStack {
                                Text(reason.label)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(ColorTheme.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)

                if selected == .other {
                    TextField("Tell us more (optional)", text: $note, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.10))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                if let error {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { Task { await submit() } }
                        .disabled(selected == nil || isSubmitting)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func submit() async {
        guard let reason = selected else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await ModerationService.shared.report(
                targetKind: targetKind,
                targetId: targetId,
                reason: reason,
                note: note.isEmpty ? nil : note
            )
            onSubmitted()
            dismiss()
        } catch {
            self.error = (error as? APIError)?.errorDescription ?? "Couldn't submit report."
        }
    }
}

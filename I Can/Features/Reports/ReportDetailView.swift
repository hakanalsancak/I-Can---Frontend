import SwiftUI

struct ReportDetailView: View {
    let report: AIReport

    var body: some View {
        ReportPagedView(report: report)
    }
}

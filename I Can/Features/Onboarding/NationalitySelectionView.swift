import SwiftUI

struct NationalitySelectionView: View {
    @Binding var country: String
    let onNext: () -> Void
    let onBack: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""

    private var filteredCountries: [(code: String, name: String, flag: String)] {
        let list = Self.countries
        if searchText.isEmpty { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Where Are You From?")
                    .font(.system(size: 28, weight: .heavy).width(.condensed))
                    .foregroundColor(ColorTheme.primaryText(colorScheme))
                Text("Your nationality")
                    .font(.system(size: 14, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
            .padding(.top, 24)
            .padding(.bottom, 16)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
                TextField("Search country...", text: $searchText)
                    .font(.system(size: 16, weight: .medium).width(.condensed))
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 6) {
                    ForEach(filteredCountries, id: \.code) { c in
                        Button {
                            HapticManager.impact(.light)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                country = c.code
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(c.flag)
                                    .font(.system(size: 28))

                                Text(c.name)
                                    .font(.system(size: 16, weight: .semibold).width(.condensed))
                                    .foregroundColor(ColorTheme.primaryText(colorScheme))

                                Spacer()

                                if country == c.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(ColorTheme.accent)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                country == c.code
                                ? ColorTheme.accent.opacity(colorScheme == .dark ? 0.15 : 0.08)
                                : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            VStack(spacing: 0) {
                Divider().opacity(0.3)
                HStack(spacing: 12) {
                    Button {
                        withAnimation { onBack() }
                    } label: {
                        Text("Back")
                            .font(Typography.headline)
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }

                    PrimaryButton(
                        title: "Continue",
                        isDisabled: country.isEmpty
                    ) {
                        withAnimation { onNext() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .padding(.bottom, 20)
            }
            .background(ColorTheme.background(colorScheme))
        }
    }

    static let countries: [(code: String, name: String, flag: String)] = [
        ("GB", "United Kingdom", "🇬🇧"),
        ("US", "United States", "🇺🇸"),
        ("TR", "Turkey", "🇹🇷"),
        ("DE", "Germany", "🇩🇪"),
        ("FR", "France", "🇫🇷"),
        ("ES", "Spain", "🇪🇸"),
        ("IT", "Italy", "🇮🇹"),
        ("BR", "Brazil", "🇧🇷"),
        ("AR", "Argentina", "🇦🇷"),
        ("PT", "Portugal", "🇵🇹"),
        ("NL", "Netherlands", "🇳🇱"),
        ("BE", "Belgium", "🇧🇪"),
        ("IN", "India", "🇮🇳"),
        ("AU", "Australia", "🇦🇺"),
        ("CA", "Canada", "🇨🇦"),
        ("MX", "Mexico", "🇲🇽"),
        ("JP", "Japan", "🇯🇵"),
        ("KR", "South Korea", "🇰🇷"),
        ("CN", "China", "🇨🇳"),
        ("RU", "Russia", "🇷🇺"),
        ("SA", "Saudi Arabia", "🇸🇦"),
        ("AE", "United Arab Emirates", "🇦🇪"),
        ("EG", "Egypt", "🇪🇬"),
        ("NG", "Nigeria", "🇳🇬"),
        ("ZA", "South Africa", "🇿🇦"),
        ("GH", "Ghana", "🇬🇭"),
        ("KE", "Kenya", "🇰🇪"),
        ("SE", "Sweden", "🇸🇪"),
        ("NO", "Norway", "🇳🇴"),
        ("DK", "Denmark", "🇩🇰"),
        ("FI", "Finland", "🇫🇮"),
        ("PL", "Poland", "🇵🇱"),
        ("CZ", "Czech Republic", "🇨🇿"),
        ("AT", "Austria", "🇦🇹"),
        ("CH", "Switzerland", "🇨🇭"),
        ("IE", "Ireland", "🇮🇪"),
        ("NZ", "New Zealand", "🇳🇿"),
        ("CO", "Colombia", "🇨🇴"),
        ("CL", "Chile", "🇨🇱"),
        ("PE", "Peru", "🇵🇪"),
        ("UY", "Uruguay", "🇺🇾"),
        ("PK", "Pakistan", "🇵🇰"),
        ("BD", "Bangladesh", "🇧🇩"),
        ("LK", "Sri Lanka", "🇱🇰"),
        ("PH", "Philippines", "🇵🇭"),
        ("ID", "Indonesia", "🇮🇩"),
        ("MY", "Malaysia", "🇲🇾"),
        ("TH", "Thailand", "🇹🇭"),
        ("VN", "Vietnam", "🇻🇳"),
        ("GR", "Greece", "🇬🇷"),
        ("RO", "Romania", "🇷🇴"),
        ("HR", "Croatia", "🇭🇷"),
        ("RS", "Serbia", "🇷🇸"),
        ("HU", "Hungary", "🇭🇺"),
        ("UA", "Ukraine", "🇺🇦"),
        ("IL", "Israel", "🇮🇱"),
        ("JM", "Jamaica", "🇯🇲"),
        ("TT", "Trinidad and Tobago", "🇹🇹"),
        ("CU", "Cuba", "🇨🇺"),
        ("MA", "Morocco", "🇲🇦"),
        ("TN", "Tunisia", "🇹🇳"),
        ("SN", "Senegal", "🇸🇳"),
        ("CM", "Cameroon", "🇨🇲"),
        ("CI", "Ivory Coast", "🇨🇮"),
        ("ET", "Ethiopia", "🇪🇹"),
        ("IR", "Iran", "🇮🇷"),
        ("IQ", "Iraq", "🇮🇶"),
        ("QA", "Qatar", "🇶🇦"),
        ("KW", "Kuwait", "🇰🇼"),
        ("BH", "Bahrain", "🇧🇭"),
        ("OM", "Oman", "🇴🇲"),
        ("JO", "Jordan", "🇯🇴"),
        ("LB", "Lebanon", "🇱🇧"),
        ("SG", "Singapore", "🇸🇬"),
        ("HK", "Hong Kong", "🇭🇰"),
        ("TW", "Taiwan", "🇹🇼"),
    ]
}

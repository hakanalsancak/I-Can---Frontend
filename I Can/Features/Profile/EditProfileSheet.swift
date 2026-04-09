import SwiftUI
import PhotosUI

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let viewModel: ProfileViewModel

    @State private var fullName: String
    @State private var username: String
    @State private var sport: String
    @State private var team: String
    @State private var position: String
    @State private var mantra: String
    @State private var height: String
    @State private var weight: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var editedImage: UIImage?
    @State private var usernameAvailable: Bool?
    @State private var usernameError: String?
    @State private var checkTask: Task<Void, Never>?
    @State private var showSportPicker = false
    @State private var showPositionPicker = false
    @State private var photoRemoved = false
    @State private var photoChanged = false
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var imageToCrop: UIImage?
    @State private var showCropView = false

    private let sports: [(id: String, name: String, icon: String)] = [
        ("soccer", "Soccer", "sportscourt"),
        ("basketball", "Basketball", "basketball"),
        ("tennis", "Tennis", "tennisball"),
        ("football", "Football", "football"),
        ("boxing", "Boxing", "figure.boxing"),
        ("cricket", "Cricket", "cricket.ball"),
    ]

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        let user = AuthService.shared.currentUser
        _fullName = State(initialValue: user?.fullName ?? "")
        _username = State(initialValue: user?.username ?? "")
        _sport = State(initialValue: user?.sport ?? "soccer")
        _team = State(initialValue: user?.team ?? "")
        _position = State(initialValue: user?.position ?? "")
        _mantra = State(initialValue: user?.mantra ?? "")
        let pref = UnitPreference.shared
        if let h = user?.height, h > 0 {
            if pref.heightUnit == .feet {
                let fi = UnitPreference.cmToFeetInches(h)
                _height = State(initialValue: "\(fi.feet)'\(fi.inches)")
            } else {
                _height = State(initialValue: "\(Int(h))")
            }
        } else {
            _height = State(initialValue: "")
        }
        if let w = user?.weight, w > 0 {
            if pref.weightUnit == .lbs {
                _weight = State(initialValue: "\(Int(UnitPreference.kgToLbs(w)))")
            } else {
                _weight = State(initialValue: "\(Int(w))")
            }
        } else {
            _weight = State(initialValue: "")
        }
        _editedImage = State(initialValue: viewModel.profileImage)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    photoSection
                    formFields
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(ColorTheme.background(colorScheme).ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ColorTheme.secondaryText(colorScheme))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if viewModel.isSavingProfile {
                            ProgressView()
                                .tint(ColorTheme.accent)
                        } else {
                            Text("Save")
                                .font(.system(size: 17, weight: .bold).width(.condensed))
                                .foregroundColor(ColorTheme.accent)
                        }
                    }
                    .disabled(viewModel.isSavingProfile || !isValid)
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(spacing: 14) {
            Button {
                HapticManager.selection()
                showPhotoOptions = true
            } label: {
                ZStack {
                    if let image = editedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ColorTheme.accent.opacity(0.2), ColorTheme.accent.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Text(initialsText)
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(ColorTheme.accent)
                    }

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [ColorTheme.accent, Color(hex: "358A90")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 106, height: 106)

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(ColorTheme.accent)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -2, y: -2)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }
            .buttonStyle(.plain)
            .confirmationDialog("Profile Photo", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                Button("Choose from Library") { showPhotoPicker = true }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") { showCamera = true }
                }
                if editedImage != nil {
                    Button("Remove Photo", role: .destructive) {
                        HapticManager.impact(.light)
                        editedImage = nil
                        selectedPhoto = nil
                        photoRemoved = true
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        imageToCrop = uiImage
                        showCropView = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    showCamera = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        imageToCrop = image
                        showCropView = true
                    }
                } onCancel: {
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showCropView) {
                if let image = imageToCrop {
                    ImageCropView(image: image) { cropped in
                        editedImage = cropped
                        photoChanged = true
                        showCropView = false
                        imageToCrop = nil
                    } onCancel: {
                        showCropView = false
                        imageToCrop = nil
                    }
                    .ignoresSafeArea()
                }
            }

            if editedImage != nil {
                Text("Tap to change photo")
                    .font(.system(size: 12, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            } else {
                Text("Tap to add photo")
                    .font(.system(size: 12, weight: .medium).width(.condensed))
                    .foregroundColor(ColorTheme.secondaryText(colorScheme))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Form Fields

    private var formFields: some View {
        VStack(spacing: 20) {
            fieldGroup(title: "NAME") {
                styledTextField("Full name", text: $fullName)
            }

            fieldGroup(title: "USERNAME") {
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Text("@")
                            .font(.system(size: 16, weight: .bold).width(.condensed))
                            .foregroundColor(ColorTheme.secondaryText(colorScheme))

                        TextField("username", text: $username)
                            .font(.system(size: 16, weight: .medium).width(.condensed))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: username) { _, newValue in
                                username = newValue.lowercased().replacingOccurrences(
                                    of: "[^a-z0-9._]", with: "", options: .regularExpression
                                )
                                checkTask?.cancel()
                                let current = username
                                let original = AuthService.shared.currentUser?.username ?? ""
                                guard current != original else {
                                    usernameAvailable = nil
                                    usernameError = nil
                                    return
                                }
                                let trimmed = current.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty && trimmed.count < 3 {
                                    usernameAvailable = false
                                    usernameError = "At least 3 characters"
                                    return
                                }
                                usernameAvailable = nil
                                usernameError = nil
                                checkTask = Task {
                                    try? await Task.sleep(for: .milliseconds(500))
                                    guard !Task.isCancelled, current == username else { return }
                                    await checkUsername()
                                }
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(usernameBorderColor, lineWidth: 1)
                    )

                    if let error = usernameError {
                        Text(error)
                            .font(.system(size: 11, weight: .medium).width(.condensed))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if usernameAvailable == true {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Available")
                        }
                        .font(.system(size: 11, weight: .medium).width(.condensed))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            fieldGroup(title: "SPORT") {
                Button {
                    HapticManager.selection()
                    showSportPicker.toggle()
                } label: {
                    HStack {
                        if let s = sports.first(where: { $0.id == sport }) {
                            Image(systemName: s.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ColorTheme.accent)
                            Text(s.name)
                                .font(.system(size: 16, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.primaryText(colorScheme))
                        } else {
                            Text("Select sport")
                                .font(.system(size: 16, weight: .medium).width(.condensed))
                                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                            .rotationEffect(.degrees(showSportPicker ? 180 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if showSportPicker {
                    sportPickerGrid
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            fieldGroup(title: "TEAM / CLUB") {
                styledTextField("Team or club name", text: $team)
            }

            HStack(spacing: 12) {
                let hUnit = UnitPreference.shared.heightUnit
                fieldGroup(title: "HEIGHT (\(hUnit == .cm ? "CM" : "FT"))") {
                    TextField(hUnit == .cm ? "175" : "5'9\"", text: $height)
                        .font(.system(size: 16, weight: .medium).width(.condensed))
                        .keyboardType(hUnit == .cm ? .numberPad : .default)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                        )
                        .onChange(of: height) { _, newValue in
                            if hUnit == .cm {
                                height = String(newValue.filter { $0.isNumber }.prefix(3))
                            }
                        }
                }

                let wUnit = UnitPreference.shared.weightUnit
                fieldGroup(title: "WEIGHT (\(wUnit == .kg ? "KG" : "LBS"))") {
                    TextField(wUnit == .kg ? "70" : "154", text: $weight)
                        .font(.system(size: 16, weight: .medium).width(.condensed))
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                        )
                        .onChange(of: weight) { _, newValue in
                            weight = String(newValue.filter { $0.isNumber }.prefix(3))
                        }
                }
            }

            fieldGroup(title: positionLabel) {
                Button {
                    HapticManager.selection()
                    showPositionPicker.toggle()
                } label: {
                    HStack {
                        Text(position.isEmpty ? "Select position" : position)
                            .font(.system(size: 16, weight: .medium).width(.condensed))
                            .foregroundColor(position.isEmpty ? ColorTheme.secondaryText(colorScheme) : ColorTheme.primaryText(colorScheme))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ColorTheme.tertiaryText(colorScheme))
                            .rotationEffect(.degrees(showPositionPicker ? 180 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(ColorTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if showPositionPicker {
                    positionPickerGrid
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            fieldGroup(title: "MANTRA") {
                VStack(alignment: .trailing, spacing: 4) {
                    TextField("Your personal mantra...", text: $mantra, axis: .vertical)
                        .font(.system(size: 16, weight: .medium).width(.condensed))
                        .lineLimit(3...)
                        .onChange(of: mantra) { _, newValue in
                            if newValue.count > 20 {
                                mantra = String(newValue.prefix(20))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(ColorTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
                        )
                    Text("\(mantra.count)/20")
                        .font(.system(size: 11, weight: .medium).width(.condensed))
                        .foregroundColor(mantra.count >= 20 ? .red : ColorTheme.tertiaryText(colorScheme))
                }
            }
        }
    }

    // MARK: - Helpers

    private func fieldGroup(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(ColorTheme.secondaryText(colorScheme))
                .tracking(1)
            content()
        }
    }

    private func styledTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 16, weight: .medium).width(.condensed))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(ColorTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ColorTheme.separator(colorScheme), lineWidth: 1)
            )
    }

    private var sportPickerGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(sports, id: \.id) { s in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sport = s.id
                        position = ""
                        showSportPicker = false
                    }
                    HapticManager.impact(.light)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: s.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(s.name)
                            .font(.system(size: 14, weight: .semibold).width(.condensed))
                    }
                    .foregroundColor(sport == s.id ? .white : ColorTheme.primaryText(colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(sport == s.id ? ColorTheme.accent : ColorTheme.elevatedBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private var positionPickerGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(positionsForSport, id: \.self) { pos in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        position = pos
                        showPositionPicker = false
                    }
                    HapticManager.impact(.light)
                } label: {
                    Text(pos)
                        .font(.system(size: 13, weight: .semibold).width(.condensed))
                        .foregroundColor(position == pos ? .white : ColorTheme.primaryText(colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(position == pos ? ColorTheme.accent : ColorTheme.elevatedBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    private var positionsForSport: [String] {
        switch sport {
        case "soccer": return ["Goalkeeper", "Centre-Back", "Full-Back", "Defensive Midfielder", "Central Midfielder", "Attacking Midfielder", "Winger", "Striker"]
        case "basketball": return ["Point Guard", "Shooting Guard", "Small Forward", "Power Forward", "Center"]
        case "tennis": return ["Singles", "Doubles", "Both"]
        case "football": return ["Quarterback", "Running Back", "Wide Receiver", "Tight End", "Offensive Line", "Defensive Line", "Linebacker", "Cornerback", "Safety", "Kicker / Punter"]
        case "boxing": return ["Heavyweight", "Light Heavyweight", "Middleweight", "Welterweight", "Lightweight", "Featherweight", "Bantamweight", "Flyweight"]
        case "cricket": return ["Batsman", "Bowler (Pace)", "Bowler (Spin)", "All-Rounder", "Wicket-Keeper"]
        default: return ["Player"]
        }
    }

    private var positionLabel: String {
        switch sport {
        case "boxing": return "WEIGHT CLASS"
        case "tennis": return "PLAY STYLE"
        default: return "POSITION"
        }
    }

    private var usernameBorderColor: Color {
        if let available = usernameAvailable {
            return available ? .green.opacity(0.5) : .red.opacity(0.5)
        }
        return ColorTheme.separator(colorScheme)
    }

    private var initialsText: String {
        guard !fullName.isEmpty else { return "?" }
        let parts = fullName.components(separatedBy: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(fullName.prefix(2)).uppercased()
    }

    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        usernameAvailable != false
    }

    private func checkUsername() async {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else {
            usernameError = trimmed.isEmpty ? nil : "At least 3 characters"
            usernameAvailable = false
            return
        }
        do {
            let result = try await FriendService.shared.checkUsername(trimmed)
            usernameAvailable = result.available
            usernameError = result.available ? nil : (result.error ?? "Username taken")
        } catch {
            usernameAvailable = nil
        }
    }

    private func parseHeightToCm() -> Double? {
        let trimmed = height.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if UnitPreference.shared.heightUnit == .feet {
            // Parse formats like "5'9", "5'9\"", "5 9"
            let parts = trimmed.components(separatedBy: CharacterSet(charactersIn: "' \"")).filter { !$0.isEmpty }
            if let ft = Int(parts.first ?? ""), parts.count >= 2, let inch = Int(parts[1]) {
                return UnitPreference.feetInchesToCm(feet: ft, inches: inch)
            } else if let ft = Int(parts.first ?? "") {
                return UnitPreference.feetInchesToCm(feet: ft, inches: 0)
            }
            return nil
        }
        return Double(trimmed)
    }

    private func parseWeightToKg() -> Double? {
        let trimmed = weight.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let val = Double(trimmed) else { return nil }
        if UnitPreference.shared.weightUnit == .lbs {
            return UnitPreference.lbsToKg(val)
        }
        return val
    }

    private func save() async {
        let photoDidChange = photoRemoved || photoChanged
        let success = await viewModel.saveProfile(
            fullName: fullName.trimmingCharacters(in: .whitespaces),
            username: username.trimmingCharacters(in: .whitespaces),
            sport: sport,
            team: team.trimmingCharacters(in: .whitespaces),
            position: position,
            mantra: mantra.trimmingCharacters(in: .whitespaces),
            height: parseHeightToCm(),
            weight: parseWeightToKg(),
            photo: photoDidChange ? editedImage : nil,
            removePhoto: photoRemoved
        )
        if success { dismiss() }
    }
}

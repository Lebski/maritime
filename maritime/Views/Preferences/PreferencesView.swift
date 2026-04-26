import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var section: PrefsSection = .anthropic

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider().background(Theme.stroke)
            content
        }
        .frame(width: 760, height: 560)
        .background(Theme.bg)
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Preferences")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 12)

            ForEach(PrefsSection.allCases) { entry in
                sidebarRow(entry)
            }
            Spacer()
        }
        .frame(width: 200, alignment: .leading)
        .background(Theme.bgElevated)
    }

    private func sidebarRow(_ entry: PrefsSection) -> some View {
        let selected = section == entry
        return Button(action: { section = entry }) {
            HStack(spacing: 10) {
                Image(systemName: entry.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(selected ? entry.tint : Theme.textTertiary)
                    .frame(width: 18)
                Text(entry.title)
                    .font(.system(size: 13, weight: selected ? .semibold : .medium))
                    .foregroundStyle(selected ? Theme.textPrimary : Theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(selected ? entry.tint.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                contentHeader
                switch section {
                case .anthropic: anthropicPane
                case .fal:       falPane
                case .debug:     DebugPane()
                case .about:     aboutPane
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var contentHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text(section.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Panes

    private var anthropicPane: some View {
        VStack(alignment: .leading, spacing: 22) {
            APIKeySection(
                title: "API Key",
                placeholder: "sk-ant-...",
                savedKey: settings.apiKey,
                accent: Theme.magenta,
                pingingText: "Pinging api.anthropic.com…",
                idleHelp: "Used for character psychology and story generation.",
                onSave: { settings.apiKey = $0 },
                runTest: { await testAnthropic() }
            )
            modelSection
        }
    }

    private var falPane: some View {
        APIKeySection(
            title: "API Key",
            placeholder: "fal_...",
            savedKey: settings.falAPIKey,
            accent: Theme.coral,
            pingingText: "Pinging api.fal.ai…",
            idleHelp: "Used for Nano Banana 2 image generation in Set Design and Scene Builder.",
            onSave: { settings.falAPIKey = $0 },
            runTest: { await testFal() }
        )
    }

    private var aboutPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Get a key")
            VStack(alignment: .leading, spacing: 10) {
                if let url = URL(string: "https://console.anthropic.com/settings/keys") {
                    Link("console.anthropic.com/settings/keys", destination: url)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }
                if let url = URL(string: "https://fal.ai/dashboard/keys") {
                    Link("fal.ai/dashboard/keys", destination: url)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.accent)
                }
            }

            Divider().background(Theme.stroke).padding(.vertical, 4)

            sectionHeader("About")
            Text("MovieBlaze is a filmmaking cockpit. Keys live in your macOS Keychain — nothing is uploaded except API requests you initiate.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Model picker

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Model")
            VStack(spacing: 8) {
                ForEach(AppSettings.availableModels) { option in
                    modelRow(option)
                }
            }
        }
    }

    private func modelRow(_ option: AppSettings.ModelOption) -> some View {
        Button(action: { settings.modelID = option.id }) {
            HStack(spacing: 12) {
                Image(systemName: settings.modelID == option.id ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(settings.modelID == option.id ? Theme.magenta : Theme.textTertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(option.tagline)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(10)
            .background(settings.modelID == option.id ? Theme.magenta.opacity(0.08) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(settings.modelID == option.id ? Theme.magenta.opacity(0.5) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(Theme.textTertiary)
    }

    // MARK: Test runners

    private func testAnthropic() async -> Result<Void, Error> {
        let client = AnthropicClient(apiKey: settings.apiKey, model: settings.modelID, maxTokens: 8)
        do {
            _ = try await client.send(.init(
                system: "Respond with the single word: ok.",
                messages: [.init(role: .user, content: "ping")],
                maxTokens: 8,
                model: nil
            ), label: "Test connection")
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func testFal() async -> Result<Void, Error> {
        let client = FalaiClient(apiKey: settings.falAPIKey)
        do {
            try await client.ping()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - Section catalog

private enum PrefsSection: String, CaseIterable, Identifiable {
    case anthropic
    case fal
    case debug
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .anthropic: return "Anthropic"
        case .fal:       return "fal.ai"
        case .debug:     return "Debug"
        case .about:     return "About"
        }
    }

    var subtitle: String {
        switch self {
        case .anthropic: return "Claude API key and model selection. Powers character writing and story generation."
        case .fal:       return "fal.ai API key. Powers Nano Banana 2 image generation in Set Design and Scene Builder."
        case .debug:     return "Every AI request — full request body, response, tokens, duration. Persisted across launches."
        case .about:     return "Where to get keys, and how MovieBlaze uses them."
        }
    }

    var icon: String {
        switch self {
        case .anthropic: return "brain"
        case .fal:       return "photo.stack"
        case .debug:     return "ladybug"
        case .about:     return "info.circle"
        }
    }

    var tint: Color {
        switch self {
        case .anthropic: return Theme.magenta
        case .fal:       return Theme.coral
        case .debug:     return Theme.teal
        case .about:     return Theme.accent
        }
    }
}

// MARK: - Reusable key section

private struct APIKeySection: View {
    let title: String
    let placeholder: String
    let savedKey: String
    let accent: Color
    let pingingText: String
    let idleHelp: String
    let onSave: (String) -> Void
    let runTest: () async -> Result<Void, Error>

    @State private var draftKey: String = ""
    @State private var testState: TestState = .idle

    enum TestState: Equatable {
        case idle
        case running
        case success
        case failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title)

            HStack(spacing: 8) {
                SecureField(placeholder, text: $draftKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(10)
                    .background(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button("Paste") { pasteFromClipboard() }
                    .buttonStyle(.borderless)
                    .foregroundStyle(accent)
            }

            HStack(spacing: 10) {
                Button(action: save) {
                    Text(saveButtonTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(draftKey == savedKey ? Theme.textTertiary : .black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(draftKey == savedKey ? Color.white.opacity(0.08) : accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
                .disabled(draftKey == savedKey)

                Button(action: { Task { await test() } }) {
                    HStack(spacing: 6) {
                        if testState == .running {
                            ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "bolt.fill").font(.system(size: 10))
                        }
                        Text("Test connection").font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plainSolid)
                .disabled(savedKey.isEmpty || testState == .running)

                Spacer()
            }

            statusBanner
        }
        .onAppear { draftKey = savedKey }
        .onChange(of: savedKey) { _, new in
            if draftKey == new { return }
            draftKey = new
        }
    }

    private var saveButtonTitle: String {
        if draftKey.isEmpty && !savedKey.isEmpty { return "Remove key" }
        return draftKey == savedKey ? "Saved" : "Save key"
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch testState {
        case .idle:
            if !savedKey.isEmpty {
                bannerRow(icon: "checkmark.seal.fill", tint: Theme.teal,
                          text: "Key saved on this device.")
            } else {
                bannerRow(icon: "info.circle", tint: Theme.textSecondary,
                          text: idleHelp)
            }
        case .running:
            bannerRow(icon: "dot.radiowaves.left.and.right", tint: accent,
                      text: pingingText)
        case .success:
            bannerRow(icon: "checkmark.seal.fill", tint: Theme.teal,
                      text: "Connection successful.")
        case .failure(let detail):
            bannerRow(icon: "exclamationmark.triangle.fill", tint: Theme.coral,
                      text: detail)
        }
    }

    private func bannerRow(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(tint)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(10)
        .background(tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(Theme.textTertiary)
    }

    private func save() {
        onSave(draftKey)
        testState = .idle
    }

    private func pasteFromClipboard() {
        if let s = NSPasteboard.general.string(forType: .string) {
            draftKey = s.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func test() async {
        testState = .running
        let result = await runTest()
        switch result {
        case .success:
            testState = .success
        case .failure(let error):
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            testState = .failure(message)
        }
    }
}

//
//  ArduinoDisplayControlView.swift
//  JovesLanding
//
//  Created by David Giovannini on 3/25/25.
//

import SwiftUI
import SBJFoundation
import BLEByJove
import SBJLego

struct ArduinoDisplayControlView: View {
    let display: ArduinoDisplay.Power

    @State private var isScrolling = false
    @State private var exportName = ""
    @State private var exportLanguage: ExportLanguage = .cpp
    @State private var isExportPresented = false

    enum ExportLanguage: String, CaseIterable, Identifiable {
        case cpp = "C++"
        case swift = "Swift"
        case json = "JSON"

        var id: String { rawValue }
    }

    var body: some View {
        VStack {
            HStack {
                Button("Export", systemImage: "square.and.arrow.up") {
                    isExportPresented = true
                }
                .labelStyle(.iconOnly)
                .font(.title)

                Button("Fill") {
                    display.control.fill(.on)
                }
                .frame(maxWidth: .infinity)

                Button("Clear") {
                    display.control.fill(.off)
                }
                .frame(maxWidth: .infinity)

                Button("Invert") {
                    display.control.fill(.toggle)
                }
                .frame(maxWidth: .infinity)

                Button("Flip X") {
                    display.control.flip(true, false)
                }
                .frame(maxWidth: .infinity)

                Button("Flip Y") {
                    display.control.flip(false, true)
                }
                .frame(maxWidth: .infinity)

                Toggle("Scroll", isOn: $isScrolling)
                    .font(.headline)
#if !os(tvOS)
                    .toggleStyle(.button)
#endif
                    .frame(maxWidth: .infinity)
            }

            ArduinoR4MatrixView(
                value: display.feedback,
                interactive: isScrolling ? .scroll : .draw
            ) {
                display.control = $0
            }
        }
        .sheet(isPresented: $isExportPresented) {
            exportSheet
        }
    }

    private var exportText: String {
        let sanitized = exportName.sanitizeCVariableName

        return switch exportLanguage {
        case .cpp:
            display.control.exportCPP(name: sanitized)
        case .swift:
            display.control.exportSwift(name: sanitized)
        case .json:
            display.control.exportJSON(name: sanitized)
        }
    }

    private var exportSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Variable name", text: $exportName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }

                Section("Language") {
                    Picker("Language", selection: $exportLanguage) {
                        ForEach(ExportLanguage.allCases) { language in
                            Text(language.rawValue).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Preview") {
                    ScrollView {
                        Text(exportText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }
                    .frame(minHeight: 120)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        isExportPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: exportText) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .disabled(exportText.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ArduinoDisplayControlView(
        display: ArduinoDisplay.Power(
            broadcaster: BTDevice(preview: "Sample"),
            characteristic: BTCharacteristicIdentity(),
            transfomer: .init()
        )
    )
}

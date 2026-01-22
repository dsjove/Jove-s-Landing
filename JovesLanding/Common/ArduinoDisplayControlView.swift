//
//  ArduinoDisplayControlView.swift
//  JovesLanding
//
//  Created by David Giovannini on 3/25/25.
//

import SwiftUI
import BLEByJove
import SBJLego
import SBJKit

struct ArduinoDisplayControlView: View {
	let display: ArduinoDisplay.Power
	@State private var isScrolling = false

	enum ExportLanguage: String, CaseIterable, Identifiable {
		case cpp = "C++"
		case swift = "Swift"
		case json = "JSON"
		var id: String { rawValue }
	}
	@State private var exportName: String = ""
	@State private var exportLanguage: ExportLanguage = .cpp

	enum ActiveSheet: Identifiable {
		case export
		case share
		var id: Int { hashValue }
	}
	@State private var activeSheet: ActiveSheet? = nil

	var body: some View {
		VStack {
			HStack() {
				Button(action: {
					activeSheet = .export
				}) {
					Image(systemName: "square.and.arrow.up").font(.title)
				}
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
				Toggle(isOn: $isScrolling) {
					Text("Scroll")
						.font(.headline)
				}
#if !os(tvOS)
				.toggleStyle(ButtonToggleStyle())
#endif
				.frame(maxWidth: .infinity)
			}
			ArduinoR4MatrixView(value: display.feedback, interactive: isScrolling ? .scroll : .draw) {
				display.control = $0
			}
			.sheet(item: $activeSheet) { sheet in
				let text = {
					let sanitized = exportName.sanitizeCVariableName
					return switch exportLanguage {
					case .cpp:
						display.control.exportCPP(name: sanitized)
					case .swift:
						display.control.exportSwift(name: sanitized)
					case .json:
						display.control.exportJSON(name: sanitized)
					}
				}()
				switch sheet {
				case .share:
					SBJKit.ShareSheet(activityItems: [text])
				case .export:
					NavigationStack {
						Form {
							Section(header: Text("Name")) {
								TextField("Variable name", text: $exportName)
									.textInputAutocapitalization(.never)
									.autocorrectionDisabled(true)
							}
							Section(header: Text("Language")) {
								Picker("Language", selection: $exportLanguage) {
									ForEach(ExportLanguage.allCases) { lang in
										Text(lang.rawValue).tag(lang)
									}
								}
								.pickerStyle(.segmented)
							}
							Section(header: Text("Preview")) {
								ScrollView {
									Text(text)
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
								Button("Cancel") { activeSheet = nil }
							}
							ToolbarItem(placement: .confirmationAction) {
								Button("Share") {
									activeSheet = .share
								}
								.disabled(text.isEmpty)
							}
						}
					}
				}
			}
		}
	}
}

#Preview {
	ArduinoDisplayControlView(display: ArduinoDisplay.Power(
			broadcaster: BTDevice(preview: "Sample"),
			characteristic: BTCharacteristicIdentity(),
			transfomer: .init()))
}

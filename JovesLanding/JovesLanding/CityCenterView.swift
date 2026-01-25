//
//  CityCenterView.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/5/22.
//

import SwiftUI
import SBJLego
import BLEByJove

struct CityCenterView: View {
	let facility: CityCenter
	@State private var showOverlay = false

	var body: some View {
		ZStack {
			Image("Metal")
				.resizable()
				.ignoresSafeArea()
			FacilityConnectionView(facility) { facility in
				VStack {
					Grid(alignment: .leading, horizontalSpacing: 12) {
						LightingControlsView(lighting: facility.streetLights)
					}
					RegistrationListView(rail: facility.rail)
					Text(facility.currentTrain?.registration.name ?? "")
					ArduinoR4MatrixView(value: facility.logoDisplay.power.feedback)
						.frame(maxWidth: 240)
						.highPriorityGesture(
							TapGesture().onEnded {
								showOverlay = true
							}
						)
				}
			}
		}
		.navigationBarTitle(facility.name)
		.sheet(isPresented: $showOverlay) {
			ArduinoDisplayControlView(display: facility.logoDisplay.power)
		}
	}
}

struct RegistrationListView: View {
	let rail: RFIDProducer

	var body: some View {
		ScrollView(.vertical) {
			VStack(alignment: .leading, spacing: 8) {
				ForEach(CityCenter.registrations.values.sorted()) { reg in
					Button(action: {
						let detection = RFIDDetection(reader: 1, timeStampMS: 0, id: reg.id)
						rail.receive(detection)
					}) {
						HStack {
							Image(reg.image)
								.resizable()
								.scaledToFit()
								.frame(width: 20, height: 20)
								.opacity(0.8)
							Text(reg.name)
								.foregroundStyle(.primary)
								.lineLimit(1)
								.truncationMode(.tail)
							Spacer()
						}
						.contentShape(Rectangle())
					}
					.buttonStyle(.plain)
				}
			}
			.padding(.horizontal, 8)
		}
		.frame(height: 5 * 44)
	}
}

#Preview {
	CityCenterView(facility: CityCenter())
}

//
//  ConductedView.swift
//  JovesLanding
//
//  Created by David Giovannini on 4/4/25.
//

import SwiftUI
import BLEByJove
import SBJLego

typealias JoveMetroLineView = ConductedView<JoveMetroLine>
//typealias CityCenterView = ConductedView<CityCenter>
typealias JoveExpressView = ConductedView<JoveExpress>
typealias PowerFunctionView = ConductedView<PFFacility>

struct ESPCamView : View {
	let facility: ESPCam
	@State private var imageURL: URL
	@State private var crown = Int()
	@State var refreshID = UUID()

	init(facility: ESPCam) {
		self.facility = facility
		self._imageURL = State(initialValue: facility.imageURL)
	}

	var body: some View {
		AsyncImage(url: imageURL) { image in
			image.resizable()
				.aspectRatio(contentMode: .fit)
		} placeholder: {
			ProgressView()
		}
		.id(refreshID)
		.onTapGesture {
			refreshID = UUID()
		}
		.focusable(true)
		.digitalCrownRotation(
			detent: $crown, from: 0, through: 255, by: 1,
			sensitivity: .high, isContinuous: false,
			 isHapticFeedbackEnabled: true,
			 onChange: { _ in }, onIdle: {})
		.onChange(of: crown) { _, newValue in
			facility.lighting.power.control = Double(newValue) / 255.0
		}
	}

	private func refreshImage() {
		imageURL = URL(string: "\(facility.imageURL)?\(UUID().uuidString)")!
	}
}

struct ConductedView<F: MotorizedFacility>: View {
	let facility: F
	@State private var crown = Int()

	init(facility: F) {
		self.facility = facility
	}
	
	var body: some View {
		MotorizedFacilityGauageView(facility: facility)
			.onTapGesture(count: 1) {
				if let lighting = facility.lighting {
					lighting.power.control = lighting.power.control == 0.0 ? 1.0 : 0.0
					}
				}
				.onLongPressGesture {
					switch (facility.connectionState) {
						case .connected:
							crown = 0
							facility.fullStop()
						case .connecting:
							break
						case .disconnected:
							facility.connect()
					}
				}
				.focusable(true)
				.digitalCrownRotation(
					detent: $crown, from: -100, through: 100, by: 1,
					sensitivity: .high, isContinuous: false,
					 isHapticFeedbackEnabled: true,
					 onChange: { _ in }, onIdle: {})
				.onChange(of: crown) { _, newValue in
					facility.motor.power.control = Double(newValue) / 100.0
				}
	}
}

#Preview {
	ConductedView(facility: JoveMetroLine())
}

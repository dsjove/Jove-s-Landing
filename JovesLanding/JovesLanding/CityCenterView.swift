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
		.sheet(isPresented: $showOverlay) {
			ArduinoDisplayControlView(display: facility.logoDisplay.power)
		}
	}
}

#Preview {
	CityCenterView(facility: CityCenter())
}

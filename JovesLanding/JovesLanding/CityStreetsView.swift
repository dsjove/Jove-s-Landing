//
//  CityStreets.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/5/22.
//

import SwiftUI
import Infrastructure
import BLEByJove

struct CityStreetsView: View {
	let facility: CityStreets
	@State private var showOverlay = false

	var body: some View {
		MotorizedFacilityView(facility) {
			Divider()
			ArduinoR4MatrixView(value: facility.display.power.feedback)
				.frame(maxWidth: 240)
				.highPriorityGesture(
					TapGesture().onEnded {
						showOverlay = true
					}
				)
		}
		.sheet(isPresented: $showOverlay) {
			ArduinoDisplayControlView(display: facility.display.power)
		}
	}
}

#Preview {
	CityStreetsView(facility: CityStreets())
}

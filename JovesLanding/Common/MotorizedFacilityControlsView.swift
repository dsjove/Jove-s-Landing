//
//  MotorizedFacilityControlsView.swift
//  JovesLanding
//
//  Created by David Giovannini on 3/25/25.
//

import SwiftUI
import SBJLego
import SbjGauge

struct MotorizedFacilityControlsView<Facility: MotorizedFacility>: View {
	let facility: Facility

	var body: some View {
		Grid(alignment: .leading, horizontalSpacing: 12) {
			GridRow() {
				Text("Speed").font(.headline)
				ScrubView(
					value: facility.motor.power.control,
					range: -1.0...1.0,
					increment: facility.motor.increment,
					minMaxSplit: 0.0,
					minTrackColor: Color("Motor/Reverse"),
					maxTrackColor: Color("Motor/Forward")) {
						facility.motor.power.control = $0
					}
					.frame(height: 44)
			}
			if let calibration = facility.motor.calibration, !facility.motor.readOnlyCalibration {
				GridRow {
					Text("Idle").font(.headline)
					ScrubView(
						value: calibration.control,
						range: 0.0...1.0,
						minTrackColor: Color("Motor/Idle"),
						maxTrackColor: Color("Motor/Go")) {
							calibration.control = $0
						}
						.frame(height: 44)
				}
			}
			Divider()
			if let lighting = facility.lighting {
				LightingControlsView(lighting: lighting)
			}
		}
		.disabled(facility.connectionState != .connected)
	}
}



#Preview {
	MotorizedFacilityControlsView(facility: JoveMetroLine())
}

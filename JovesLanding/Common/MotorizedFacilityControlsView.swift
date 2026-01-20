//
//  MotorizedFacilityControlsView.swift
//  JovesLanding
//
//  Created by David Giovannini on 3/25/25.
//

import SwiftUI
import Infrastructure
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
					//increment: facility.motor.increment,
					minMaxSplit: 0.0,
					minTrackColor: Color("Motor/Reverse"),
					maxTrackColor: Color("Motor/Forward")) {
						facility.motor.power.control = $0
					}
					.frame(height: 44)
			}
			if let calibration = facility.motor.calibration {
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
				GridRow {
					Text("Lights").font(.headline)
					ScrubView(
						value: lighting.power.control,
						range: 0.0...1.0,
							gradient: true,
						minTrackColor: Color("Lights/Off"),
						maxTrackColor: Color("Lights/On")) {
							lighting.power.control = $0
						}
						.frame(height: 44)
				}
				if let calibration = lighting.calibration {
					GridRow {
						Text("Auto\nLights").font(.headline).lineLimit(2)
						ScrubView(
							value: calibration.control,
							range: 0.0...1.0,
							increment: lighting.increment,
							minMaxSplit: lighting.sensed?.feedback ?? 0.0,
							minTrackColor: Color.black,
							maxTrackColor: Color.white) {
								calibration.control = $0
							}
								.frame(height: 44)
					}
				}
			}
		}
		.disabled(facility.connectionState != .connected)
	}
}

#Preview {
	MotorizedFacilityControlsView(facility: JoveMetroLine())
}

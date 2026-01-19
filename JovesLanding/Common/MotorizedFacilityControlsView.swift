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
	let motorPower: Facility.Motor.Power
	let motorCalibration: Facility.Motor.Calibration
	let lightPower: Facility.Lighting.Value

	init(facility: Facility) {
		self.facility = facility
		self.motorPower = facility.motor.power
		self.motorCalibration = facility.motor.calibration
		self.lightPower = facility.lighting.power
	}

	var body: some View {
		Grid(alignment: .leading, horizontalSpacing: 12) {
			if facility.hasMotor {
				GridRow() {
					Text("Speed").font(.headline)
					ScrubView(
						value: facility.motor.power.control,
						range: -1.0...1.0,
						minMaxSplit: 0.0,
						minTrackColor: Color("Motor/Reverse"),
						maxTrackColor: Color("Motor/Forward")) {
							facility.motor.power.control = $0
						}
						.frame(height: 44)
				}
				GridRow {
					Text("Idle").font(.headline)
					ScrubView(
						value: facility.motor.calibration.control,
						range: 0.0...1.0,
						minTrackColor: Color("Motor/Idle"),
						maxTrackColor: Color("Motor/Go")) {
							facility.motor.calibration.control = $0
						}
						.frame(height: 44)
				}
				Divider()
			}
			if facility.hasLighting {
				GridRow {
					Text("Lights").font(.headline)
					ScrubView(
						value: facility.lighting.power.control,
						range: 0.0...1.0,
							gradient: true,
						minTrackColor: Color("Lights/Off"),
						maxTrackColor: Color("Lights/On")) {
							facility.lighting.power.control = $0
						}
						.frame(height: 44)
				}
			}
		}
		.disabled(facility.connectionState != .connected)
	}
}

#Preview {
	MotorizedFacilityControlsView(facility: JoveMetroLine())
}

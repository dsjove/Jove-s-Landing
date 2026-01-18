//
//  JoveMetroLineControlsView.swift
//  JovesLanding
//
//  Created by David Giovannini on 3/25/25.
//

import SwiftUI
import Infrastructure
import SbjGauge

struct JoveMetroLineControlsView: View {
	let facility: JoveMetroLine
	let motorPower: JoveMetroLine.Motor.Power
	let motorCalibration: JoveMetroLine.Motor.Calibration
	let lightPower: JoveMetroLine.Lighting.Value

	init(facility: JoveMetroLine) {
		self.facility = facility
		self.motorPower = facility.motor.power
		self.motorCalibration = facility.motor.calibration
		self.lightPower = facility.lighting.power
	}

	var body: some View {
		Grid(alignment: .leading, horizontalSpacing: 12) {
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
		.disabled(facility.connectionState != .connected)
	}
}

#Preview {
	JoveMetroLineControlsView(facility: JoveMetroLine())
}

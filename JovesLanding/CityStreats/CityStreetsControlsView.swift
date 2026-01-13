//
//  CityStreetsControlsView.swift
//  JovesLanding
//
//  Created by David Giovannini on 3/25/25.
//

import SwiftUI
import Infrastructure
import SbjGauge
import BLEByJove

struct CityStreetsControlsView: View {
	@ObservedObject var facility: CityStreets
	@ObservedObject var motorPower: CityStreets.Motor.Power
	@ObservedObject var motorCalibration: CityStreets.Motor.Calibration
	@ObservedObject var lightPower: CityStreets.Lighting.Value
	@ObservedObject var lightCalibration: CityStreets.Lighting.Value
	@ObservedObject var lightSensed: CityStreets.Lighting.Value
	@ObservedObject var display: ArduinoDisplay.Power
	@ObservedObject var rail: TrainRail

	@State private var showOverlay = false

	init(facility: CityStreets) {
		self.facility = facility
		self.motorPower = facility.motor.power
		self.motorCalibration = facility.motor.calibration
		self.lightPower = facility.lighting.power
		self.lightCalibration = facility.lighting.calibration
		self.lightSensed = facility.lighting.sensed
		self.display = facility.display.power
		self.rail = facility.rail
	}

	var body: some View {
		VStack {
			Grid(alignment: .leading, horizontalSpacing: 12) {
				GridRow() {
					Text("Speed").font(.headline).lineLimit(2)
					ScrubView(
						value: motorPower.control,
						range: -1.0...1.0,
						increment: facility.motor.increment,
						minMaxSplit: 0.0,
						minTrackColor: Color("Motor/Reverse"),
						maxTrackColor: Color("Motor/Forward")) {
							motorPower.control = $0
						}
							.frame(height: 44)
				}
				GridRow {
					Text("Idle").font(.headline).lineLimit(2)
					ScrubView(
						value: motorCalibration.control,
						range: 0.0...1.0,
						increment: facility.motor.increment,
						minTrackColor: Color("Motor/Idle"),
						maxTrackColor: Color("Motor/Go")) {
							motorCalibration.control = $0
						}
							.frame(height: 44)
				}
				Divider()
				GridRow {
					Text("Lights").font(.headline).lineLimit(2)
					ScrubView(
						value: lightPower.control,
						range: 0.0...1.0,
						increment: facility.lighting.increment,
						gradient: true,
						minTrackColor: Color("Lights/Off"),
						maxTrackColor: Color("Lights/On")) {
							lightPower.control = $0
						}
							.frame(height: 44)
				}
				if facility.lighting.hasSensor {
					GridRow {
						Text("Auto\nLights").font(.headline).lineLimit(2)
						ScrubView(
							value: lightCalibration.control,
							range: 0.0...1.0,
							increment: facility.lighting.increment,
							minMaxSplit: lightSensed.feedback,
							minTrackColor: Color.black,
							maxTrackColor: Color.white) {
								lightCalibration.control = $0
							}
								.frame(height: 44)
					}
				}
			}
			Divider()
			ArduinoR4MatrixView(value: display.feedback)
				.frame(maxWidth: 240)
				.highPriorityGesture(
					TapGesture().onEnded {
						showOverlay = true
					}
				)
				.sheet(isPresented: $showOverlay) {
					ArduinoDisplayControlView(display: display)
				}
		}
		.disabled(facility.connectionState != .connected)
	}
}

#Preview {
	CityStreetsControlsView(facility: CityStreets())
}

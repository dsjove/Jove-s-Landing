//
//  MotorizedFacilityGauageView.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/14/22.
//

import SwiftUI
import SBJKit
import Infrastructure
import SbjGauge

struct MotorizedFacilityGauageView<F: MotorizedFacility> : View {
	let facility: F
	@ObservedObject var motorPower: F.Motor.Power
	@ObservedObject var motorCalibration: F.Motor.Calibration
	@ObservedObject var lightPower: F.Lighting.Value

	init(facility: F) {
		self.facility = facility
		self.motorPower = facility.motor.power
		self.motorCalibration = facility.motor.calibration
		self.lightPower = facility.lighting.power
	}

	func indicators() -> GaugeIndicators {
		var indicators = GaugeIndicators(image: Image(facility.image))
		indicators.battery = facility.battery
		indicators.light = lightPower.feedback
		indicators.motorState = MotorState(power: motorPower.feedback)
		indicators.connectionState = facility.connectionState
		indicators.heartBeat = facility.heartBeat
		return indicators
	}

	var body: some View {
		let model = SbjGauge.StandardModel(
			power: motorPower.feedback,
			control: motorPower.control,
			idle: motorCalibration.feedback)
		let indicators = self.indicators()
		SbjGauge.Power.PowerView(model) { _, w in
			GaugeIndicatorsView(width: w, indicators: indicators)
		}
	}
}

#Preview {
	MotorizedFacilityGauageView(facility: CityStreets())
	MotorizedFacilityGauageView(facility: JoveMetroLine())
}

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

	func indicators() -> GaugeIndicators {
		var indicators = GaugeIndicators(image: Image(facility.image))
		indicators.battery = facility.battery
		indicators.light = facility.lighting?.power.feedback ?? 0
		indicators.motorState = MotorState(power: facility.motor.power.feedback)
		indicators.connectionState = facility.hasConnectionState ? facility.connectionState : nil
		indicators.heartBeat = facility.heartBeat
		return indicators
	}

	var body: some View {
		let model = SbjGauge.StandardModel(
			power: facility.motor.power.feedback,
			control: facility.motor.power.control,
			idle: facility.motor.calibration?.feedback ?? 0.0)
		let indicators = self.indicators()
		SbjGauge.Power.PowerView(model) { _, w in
			GaugeIndicatorsView(width: w, indicators: indicators)
		}
	}
}

#Preview {
	MotorizedFacilityGauageView(facility: JoveMetroLine())
}

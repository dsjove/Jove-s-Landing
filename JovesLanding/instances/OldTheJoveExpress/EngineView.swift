//
//  EngineView.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/9/21.
//

import SwiftUI
import BLEByJove
import Infrastructure
import SbjGauge

struct EngineView: View {
	@ObservedObject var calibration: BTSubject<EngineRational>
	@ObservedObject var power: BTSubject<EngineRational>
	//@State private var gaugeModel: SbjGauge.Gauge.Model

	init(_ engine: Engine) {
		self._calibration = ObservedObject(initialValue: engine.calibration)
		self._power = ObservedObject(initialValue: engine.power)
		//_gaugeModel = State(initialValue: SbjGauge.Gauge.Model())
	}
	
	var body: some View {
		VStack(alignment: .center, spacing: 12) {
			/*
			SbjGauge.ZStackSquare(gaugeModel) { geom, model in
				SbjGauge.Gauge.standard(geom: geom, model: model)
			}
				.onChange(of: rail.power) { newValue in
					gaugeValues.value = newValue.ratio * 100.0
				}
				.onChange(of: rail.calibration) { newValue in
					let c = newValue.ratio * 100.0
					gaugeValues.ranges[0].values = -100 ... -c
					gaugeValues.ranges[1].values = -c ... c
					gaugeValues.ranges[2].values = c ... 100
				}
				.onChange(of: rail.motorState) { newValue in
					gaugeValues.image = newValue.imageName
				}

			RationalSlider(hasNegative: true, value: $power.control, thumbColor: Color.gray, minTrackColor: Color.red, maxTrackColor: Color.green)
			Text("Speed").multilineTextAlignment(.center)
			RationalSlider(hasNegative: false, value: $calibration.control, thumbColor: Color.gray, minTrackColor: Color.yellow, maxTrackColor: Color.red)
			Text("Idle Threshold").multilineTextAlignment(.center)
		}
			*/
			}
	}
}

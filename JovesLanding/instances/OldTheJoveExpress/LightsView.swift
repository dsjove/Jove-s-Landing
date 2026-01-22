//
//  LightsView.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/9/21.
//

import SwiftUI
import BLEByJove
import Infrastructure
import SbjGauge

struct LightsView: View {
	@ObservedObject var calibration: BTSubject<LightsRational>
	@ObservedObject var power: BTSubject<LightCommand>
	@ObservedObject var state: BTSubject<Bool>
	@ObservedObject var sensed: BTSubject<LightsRational>
	//@State private var gaugeModel: SbjGauge.Gauge.Model

	init(_ lights: Lights) {
		self._calibration = ObservedObject(initialValue: lights.calibration)
		self._power = ObservedObject(initialValue: lights.power)
		self._state = ObservedObject(initialValue: lights.state)
		self._sensed = ObservedObject(initialValue: lights.ambient)
		//_gaugeModel = State(initialValue:  SbjGauge.Gauge.Model())
	}
	
	var body: some View {
			/*
		VStack(alignment: .center, spacing: 12) {
			ZStackSquare(gaugeModel) { geom, state in
			Gauge.standard(geom: geom, model: gaugeModel)
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
			*/
			/*
				value: sensed.feedback,
				marker: FogRational(ratio: 1.0),
				ranges: [
					Double(calibration.feedback.num),
					256.0],
				indicator: GuageImage(named: state.feedback ? "TorchOn" : "TorchOff")!)
					.aspectRatio(1, contentMode: .fit)
			*/
			Picker("", selection: $power.control) {
				ForEach(LightCommand.allCases, id: \.self) {
					Text($0.description)
				}
			}
			//.pickerStyle(SegmentedPickerStyle())
			Text("Lights").multilineTextAlignment(.center)
			/*
			RationalSlider(hasNegative: false, value: $calibration.control, thumbColor: Color.gray, minTrackColor: Color.black, maxTrackColor: Color.white)
			*/
			Text("Ambient Threshold").multilineTextAlignment(.center)
	   // }
	}
}

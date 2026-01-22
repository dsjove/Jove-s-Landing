//
//  LightingControlsView.swift
//  JovesLanding
//
//  Created by David Giovannini on 1/22/26.
//

import SwiftUI
import SBJLego
import SbjGauge

struct LightingControlsView<Lighting: LightingProtocol>: View {
	let lighting: Lighting

	var body: some View {
		Group {
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
}

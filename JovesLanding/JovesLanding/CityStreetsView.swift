//
//  CityStreets.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/5/22.
//

import SwiftUI
import Infrastructure
import BLEByJove

struct CityStreetsView: View {
	@ObservedObject var facility: CityStreets
	@ObservedObject var sensedTrain: TrainRail.TrainID

	 init(facility: CityStreets) {
		 self.facility = facility
		 self.sensedTrain = facility.rail.sensedTrain
	}

	var body: some View {
		ZStack {
			Image("Metal")
				.resizable()
				.ignoresSafeArea()
			HVStack(spacing: 8) {
				FacilityConnectionView(facility) { facility in
					MotorizedFacilityGauageView(facility: facility)
				}
				CityStreetsControlsView(facility: facility)
			}
			.padding(8)
		}
		.navigationBarTitle(
			sensedTrain.feedback.isZero ? facility.name : sensedTrain.feedback.description )
		.onChange(of: sensedTrain.feedback) { _, newValue in
			if newValue.isZero { return }
			SoundPlayer.shared.play(assetName: "TrainHorn")
		}
	}
}

#Preview {
	CityStreetsView(facility: CityStreets())
}

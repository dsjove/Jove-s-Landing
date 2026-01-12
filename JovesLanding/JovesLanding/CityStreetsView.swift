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
		.navigationBarTitle(facility.currentTrain?.registration.name ?? facility.name)
	}
}

#Preview {
	CityStreetsView(facility: CityStreets())
}

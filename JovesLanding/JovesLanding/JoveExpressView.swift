//
//  JoveExpressView.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/5/22.
//

import SwiftUI
import Infrastructure
import BLEByJove

struct JoveExpressView: View {
	let facility: JoveExpress

	@State private var presentEditName = false

	var body: some View {
		ZStack {
			Image("Metal")
				.resizable()
				.ignoresSafeArea()
			HVStack(spacing: 8) {
				FacilityConnectionView(facility) { facility in
					MotorizedFacilityGauageView(facility: facility)
				}
				JoveExpressControlsView(facility: facility)
			}
			.padding(8)
		}
		.navigationBarTitle(facility.name)
	}
}

#Preview {
	JoveExpressView(facility: JoveExpress())
}

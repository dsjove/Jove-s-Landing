//
//  ChristofView.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/5/22.
//

import SwiftUI
import SBJLego
import BLEByJove

struct ChristofView: View {
	let facility: Christof

	var body: some View {
		ZStack {
			Image("Metal")
				.resizable()
				.ignoresSafeArea()
			FacilityConnectionView(facility) { facility in
				VStack {
					Grid(alignment: .leading, horizontalSpacing: 12) {
						LightingControlsView(lighting: facility.streetLights)
					}
					Divider()
				}
			}
		}
		.navigationBarTitle(facility.name)
	}
}

#Preview {
	ChristofView(facility: Christof())
}

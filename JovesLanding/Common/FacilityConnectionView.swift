//
//  FacilityConnectionView.swift
//  JovesLanding
//
//  Created by David Giovannini on 3/31/25.
//

import SwiftUI
import BLEByJove
import Infrastructure

public struct FacilityConnectionView<Content: View, F: Facility>: View {
	let facility: F
	@ViewBuilder public var gauge: (F) -> Content

	public init(_ facility: F, @ViewBuilder _ gauge: @escaping (F) -> Content) {
		self.facility = facility
		self.gauge = gauge
	}

	public var body: some View {
		ZStack {
			gauge(facility)
			if facility.hasConnectionState {
				VStack {
					HStack(alignment: .top) {
						Button(action: {
							if facility.connectionState == .disconnected {
								facility.connect()
							}
							else {
								facility.disconnect()
							}
						}) {
							Image(systemName: facility.connectionState == .disconnected ?  "cable.connector" : "cable.connector.slash")
								.resizable()
								.aspectRatio(contentMode: .fit)
						}
						.frame(width: 42, height: 42)
						Spacer()
						Button(action: {
							facility.fullStop()
						}) {
							Image(systemName: "stop.circle")
								.resizable()
								.aspectRatio(contentMode: .fit)
						}
						.frame(width: 42, height: 42)
					}
					Spacer()
				}
			}
		}
		.aspectRatio(1.0, contentMode: .fit)
		.clipped()
	}
}

#Preview {
	FacilityConnectionView(CityStreets(), { _ in Circle().fill() })
	.background(Color.mint)
}

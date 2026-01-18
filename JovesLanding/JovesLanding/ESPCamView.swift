//
//  ChristofView.swift
//  JovesLanding
//
//  Created by David Giovannini on 5/19/25.
//

import SwiftUI
import Infrastructure
import BLEByJove
import Network
import SbjGauge

struct ESPCamView: View {
	let facility: ESPCam
	let lightPower: ESPCam.Lighting.Value
	@State private var imageURL: URL
	@State var refreshID = UUID()

	init(facility: ESPCam) {
		self.facility = facility
		self._imageURL = State(initialValue: facility.imageURL)
		self.lightPower = facility.lighting.power
	}

	var body: some View {
		ZStack {
			Image("Metal")
				.resizable()
				.ignoresSafeArea()
			VStack {
				AsyncImage(url: imageURL) { image in
					image.resizable()
						.aspectRatio(contentMode: .fit)

				} placeholder: {
					ProgressView().background(Color.white.opacity(0.5))
				}
				.id(refreshID)
				.onTapGesture {
					refreshID = UUID()
				}
				ScrubView(
					value: lightPower.control,
					range: 0.0...1.0,
					increment: facility.lighting.increment,
					gradient: true,
					minTrackColor: Color("Lights/Off"),
					maxTrackColor: Color("Lights/On")) {
						lightPower.control = $0
					}
						.frame(height: 44)
			}
			.padding(8)
		}
		.navigationBarTitle(facility.name)
	}
}

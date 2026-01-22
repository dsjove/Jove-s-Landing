//
//  ConnectionView.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/13/21.
//

import SwiftUI
import BLEByJove
import Infrastructure

struct ConnectionView: View {
	@ObservedObject var train: TheJoveExpress
	@ObservedObject var beat: BTSubject<UInt8>
	@ObservedObject var fullStop: BTSubject<Bool>
	
	@State private var padding : CGFloat = 22
	
	init(train: TheJoveExpress) {
		self.train = train
		self.beat = train.heart.beat
		self.fullStop = train.heart.fullStop
	}
	
	var body: some View {
	/*	train.state.image
			.resizable()
			.frame(width: 44, height: 44)
			.background(
				Color.red.opacity(0.5)
					.cornerRadius(22)
					.padding(padding)
					.onReceive(beat.$feedback) { _ in
						padding = 0
						withAnimation(.easeInOut(duration: 0.75)) {
							padding = 22
						}
					}
			)
			.overlay(
				Circle().foregroundColor(Color.red.opacity(fullStop.control ? 0.5 : 0.0))

			)
		.onTapGesture {
			if train.state != .connected {
				train.connect()
			}
		}
		.onLongPressGesture {
			fullStop.control = true
		}
		*/
	Text("")
	}
}

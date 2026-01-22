//
//  MotorIndicatorView.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/16/22.
//

import SwiftUI
import SBJLego

struct MotorIndicatorView: View {
	var image: Image = Image(systemName: "train.side.front.car")
	let motorState: MotorState
	
	var body: some View {
		image
			.resizable()
			.foregroundColor(color())
			.aspectRatio(contentMode: .fit)
	}

	private func color() -> Color {
		switch motorState {
			case .idle:
				return Color("Motor/Idle")
			case .forward:
				return Color("Motor/Forward")
			case.reverse:
				return Color("Motor/Reverse")
		}
	}
}

#Preview {
	VStack {
		MotorIndicatorView(motorState: .reverse)
		MotorIndicatorView(motorState: .idle)
		MotorIndicatorView(motorState: .forward)
	}
}

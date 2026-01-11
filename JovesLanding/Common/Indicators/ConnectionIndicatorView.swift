//
//  ConnectionIndicatorView.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/16/22.
//

import SwiftUI
import Infrastructure
import BLEByJove

struct ConnectionIndicatorView: View {
	let connectionState: ConnectionState
	let heartBeat: Int // Counter passed into the init
	@State private var scale: CGFloat = 0.0 // State to drive animation

	static func color(connectionState: ConnectionState) -> Color {
		switch connectionState {
		case .disconnected:
			return Color("Connection/Disconnected")
		case .connecting:
			return Color("Connection/Connecting")
		case.connected:
			return Color("Connection/Connected")
		}
	}

	var body: some View {
		ZStack {
			Image(systemName: iconName())
				.resizable()
				.aspectRatio(contentMode: .fit)
				.symbolRenderingMode(.palette)
				.foregroundStyle(Self.color(connectionState: connectionState))
			Image(systemName: "heart.fill")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.symbolRenderingMode(.palette)
				.foregroundStyle(Color.red)
				.opacity(scale)
				.scaleEffect(scale)
				.animation(.easeInOut(duration: 0.75), value: scale)
		}
		.onChange(of: heartBeat) { _, newValue in
			if newValue >= 0 {
				scale = 1.0
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					scale = 0.0
				}
			}
		}
	}

	private func iconName() -> String {
		switch connectionState {
		case .disconnected:
			return "powerplug"
		case .connecting:
			return "rays"
		case .connected:
			return "powerplug"
		}
	}
}

#Preview {
	VStack {
		ConnectionIndicatorView(connectionState: .connected, heartBeat: 0)
		ConnectionIndicatorView(connectionState: .connecting, heartBeat: -1)
		ConnectionIndicatorView(connectionState: .disconnected, heartBeat: -1)
	}
}

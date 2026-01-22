//
//  BatteryIndicatorView.swift
//  MaskingStuff
//
//  Created by Federico on 16/04/2022.
//
import SwiftUI
import SBJLego

struct BatteryIndicatorView: View {
	let progress: Double

	var body: some View {
		GeometryReader { geom in
			ZStack {
				Color.clear
				Image(systemName: iconName())
					.resizable()
					.aspectRatio(contentMode: .fit)
					.foregroundStyle(color(), .black)
					/*
				Text(progress != nil ? "\(Int(self.progress! * 100))%" : "")
					.font(.system(size: geom.size.height * 0.25))
					.lineLimit(1)
					.allowsTightening(true)
					.foregroundColor(Color("Battery/Text"))
					.frame(alignment: .leading)
					*/
			}
		}
	}

	private func iconName() -> String {
		if progress >= 0.90 {
			return "battery.100"
		}
		if progress >= 0.60 {
			return "battery.75"
		}
		if progress >= 0.30 {
			return "battery.50"
		}
		if progress >= 0 {
			return "battery.25"
		}
		return "battery.0"
	}

	private func color() -> Color {
		if progress >= 0.50 {
			return Color("Battery/High")
		}
		if progress >= 0.0 {
			return Color("Battery/Low")
		}
		return Color("Battery/Disconnect")
	}
}

#Preview {
	VStack {
		BatteryIndicatorView(progress: -1)
		BatteryIndicatorView(progress: 0.0)
		BatteryIndicatorView(progress: 0.30)
		BatteryIndicatorView(progress: 0.60)
		BatteryIndicatorView(progress: 0.90)
			.background(Color.gray)
			.frame(width: 200, height: 100)
	}
}

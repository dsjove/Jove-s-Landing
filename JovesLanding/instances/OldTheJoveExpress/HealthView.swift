//
//  HealthView.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/15/21.
//

import SwiftUI
import BLEByJove
import Infrastructure

struct HealthView: View {
	@ObservedObject var health: BTSubject<HeartHealth>
	
	var body: some View {
		HStack(alignment: .center, spacing: 8) {
			Text("\(health.feedback.cpuUsage)%").bold()
			Text("\(health.feedback.cpuTemp)°C").bold()
			Text("\(health.feedback.internalTemp)°C").bold()
			//Text("\(health.feedback.internalPressure)hPa").bold()
		}
	}
}

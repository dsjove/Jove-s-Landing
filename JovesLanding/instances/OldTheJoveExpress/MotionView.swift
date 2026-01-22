//
//  MotionView.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/29/21.
//

import SwiftUI
import Infrastructure

struct MotionView: View {
	var body: some View {
		ZStack {
			Circle().foregroundColor(Color.gray.opacity(0.75)).frame(maxWidth: .infinity, maxHeight: .infinity)
			.aspectRatio(1, contentMode: .fit)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			Text("Motion Gauge")
		}
	}
}

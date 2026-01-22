//
//  CheckboxStyle.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/29/21.
//

import SwiftUI

struct CheckboxStyle: ToggleStyle {
	func makeBody(configuration: Self.Configuration) -> some View {
		HStack {
			Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
				.resizable()
				.frame(width: 24, height: 24)
				.foregroundColor(configuration.isOn ? .purple : .gray)
				.font(.system(size: 20, weight: .bold, design: .default))
				.onTapGesture {
					configuration.isOn.toggle()
				}
		}
	}
}

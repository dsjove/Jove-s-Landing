//
//  MotorizedFacilityView.swift
//  JovesLanding
//
//  Created by David Giovannini on 1/19/26.
//


import SwiftUI
import Infrastructure
import BLEByJove

struct MotorizedFacilityView<Facility: MotorizedFacility>: View {
	let facility: Facility

	var body: some View {
		Text(facility.name)
	}
}

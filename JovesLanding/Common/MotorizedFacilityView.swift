//
//  MotorizedFacilityView.swift
//  JovesLanding
//
//  Created by David Giovannini on 1/19/26.
//


import SwiftUI
import SBJLego
import BLEByJove

struct MotorizedFacilityView<Facility: MotorizedFacility, FacilitySpecializationView: View>: View {
	let facility: Facility
	let specializationView: FacilitySpecializationView

	@State private var presentEditName = false
	@State private var editingName = ""

	init(_ facility: Facility, @ViewBuilder specializationView: () -> FacilitySpecializationView = { EmptyView() }) {
		self.facility = facility
		self.specializationView = specializationView()
	}

	var body: some View {
		ZStack {
			Image("Metal")
				.resizable()
				.ignoresSafeArea()
			HVStack(spacing: 8) {
				FacilityConnectionView(facility) { facility in
					MotorizedFacilityGauageView(facility: facility)
				}
				VStack {
					MotorizedFacilityControlsView(facility: facility)
					specializationView
				}
			}.padding(8)
		}
		.navigationBarTitle(facility.name)
		.toolbar {
			if facility.canSetName {
				Button {
						presentEditName = true
				} label: {
					Image(systemName: "tag.fill")
						.resizable()
				}
				.frame(width: 44)
				.aspectRatio(1, contentMode: .fit)
			}
		}
		.alert("Name", isPresented: $presentEditName,
			actions: {
				TextField(facility.name, text: $editingName)
				Button("OK", action: {
					if editingName.isEmpty == false {
						facility.change(name: editingName)
					}
					editingName = ""
				})
				Button("Cancel", role: .cancel, action: {
					editingName = ""
				})
			},
			message: {
				Text("Enter new name.")
			})
	}
}


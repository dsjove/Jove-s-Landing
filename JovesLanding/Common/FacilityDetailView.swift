//
//  FacilityDetailView.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/10/22.
//

import SwiftUI
import SBJKit
import BLEByJove
import SBJLego

struct FacilityHeaderView<F: Facility>: View {
	let facility: F

	var body: some View {
        HStack(spacing: 8) {
            Image(facility.connectionState.imageName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
            Label(facility.name, image: facility.image)
        }
    }
}

struct FacilityLineView: View {
	let facility: any Facility

	var body: some View {
		switch facility
		{
		case is JoveMetroLine:
			FacilityHeaderView(facility: facility as! JoveMetroLine)
		case is CityCenter:
			FacilityHeaderView(facility: facility as! CityCenter)
		case is JoveExpress:
			FacilityHeaderView(facility: facility as! JoveExpress)
		case is ESPCam:
			FacilityHeaderView(facility: facility as! ESPCam)
		case is PFFacility:
			FacilityHeaderView(facility: facility as! PFFacility)
		case is UnsupportedFacility:
			FacilityHeaderView(facility: facility as! UnsupportedFacility)
		default:
			FacilityHeaderView(facility: UnsupportedFacility(name: facility.name))
		}
	}
}

struct FacilityDetailView: View {
	let facility: (any Facility)?

	var body: some View {
		if let facility {
			switch facility
			{
			case is JoveMetroLine:
				MotorizedFacilityView(facility as! JoveMetroLine)
			case is CityCenter:
				CityCenterView(facility: facility as! CityCenter)
			case is JoveExpress:
				MotorizedFacilityView(facility as! JoveExpress)
			case is ESPCam:
				ESPCamView(facility: facility as! ESPCam)
			case is PFFacility:
				MotorizedFacilityView(facility as! PFFacility)
			case is UnsupportedFacility:
				NotSupportedView(text: "Unsupported \(facility.name)")
			default:
				NotSupportedView(text: "Unknown \(facility.name)")
			}
		}
		else {
			NotSupportedView(text: "No facility selected.")
		}
	}
}

struct NotSupportedView: View {
	var text: String

	var body: some View {
		Text(text)
	}
}

#Preview {
	FacilityDetailView(facility: nil)
}

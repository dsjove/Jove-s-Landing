//
//  FacilityDetailView.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/10/22.
//

import SwiftUI
import SBJKit
import BLEByJove
import Infrastructure

struct FacilityHeaderView<F: Facility>: View {
	let facility: F

	var body: some View {
		HStack {
			Image(facility.image)
			Text(facility.name)
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
		case is CityStreets:
			FacilityHeaderView(facility: facility as! CityStreets)
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
				JoveMetroLineView(facility: facility as! JoveMetroLine)
			case is CityStreets:
				CityStreetsView(facility: facility as! CityStreets)
			case is JoveExpress:
				JoveExpressView(facility: facility as! JoveExpress)
			case is ESPCam:
				ESPCamView(facility: facility as! ESPCam)
			case is PFFacility:
				MotorizedFacilityView(facility: facility as! PFFacility)
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

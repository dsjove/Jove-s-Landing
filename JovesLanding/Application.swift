//
//  JovesLandingApp.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/9/22.
//

import SwiftUI
import BLEByJove
import Infrastructure

@main
struct Application: App {
	private let facilities = FacilityRepository()

	@SceneBuilder var body: some Scene {
		WindowGroup {
			FacilitiesListView(facilities: facilities)
		}
	}
}

//
//  JovesLandingApp.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/9/22.
//

import SwiftUI
import BLEByJove
import SBJKit
import Infrastructure

@main
struct JovesLandingApp: App {
	private let facilities: FacilityRepository
	private let bluetooth: BTClient
	private let mDNS: MDNSClient
	private let powerFunction: PFClient

	init() {
		self.facilities = FacilityRepository()

		self.bluetooth = BTClient()
		self.mDNS = MDNSClient()
		self.powerFunction = PFClient() { [weak facilities] cmd in
			facilities?.transmit(cmd: cmd)
		}

		self.facilities.addScanner(bluetooth)
		self.facilities.addScanner(mDNS)
		self.facilities.addScanner(powerFunction)
	}

	@SceneBuilder var body: some Scene {
		WindowGroup {
			FacilitiesListView(facilities: facilities)
		}
	}
}

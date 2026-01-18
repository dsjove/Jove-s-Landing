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
	private let facilities: FacilitiesFactory
	private let bluetooth: BTClient
	private let mDNS: MDNSClient
	private let powerFunction: PFClient

	private static let knownPFFacilites: [PFMeta] = [
	]

	init() {
		self.facilities = FacilitiesFactory() { rfid in
		}
		self.bluetooth = BTClient()
		self.mDNS = MDNSClient()
		self.powerFunction = PFClient(knownDevices: JovesLandingApp.knownPFFacilites) { [weak facilities] cmd in
			facilities?.transmit(cmd: cmd)
		}
		self.facilities.addScanner(bluetooth)
		self.facilities.addScanner(mDNS)
		self.facilities.addScanner(powerFunction)

		withObservationTracking(for: facilities, with: bluetooth, value: \.devices) { facilities, scanner, devices in
				facilities.devicesDidChange(devices)
		}
		withObservationTracking(for: facilities, with: mDNS, value: \.devices) { facilities, scanner, devices in
				facilities.devicesDidChange(devices)
		}
		withObservationTracking(for: facilities, with: powerFunction, value: \.devices) { facilities, scanner, devices in
				facilities.devicesDidChange(devices)
		}
	}

	@SceneBuilder var body: some Scene {
		WindowGroup {
			FacilitiesListView(facilities: facilities)
		}
	}
}


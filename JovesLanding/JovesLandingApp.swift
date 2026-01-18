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
import Combine

@main
struct JovesLandingApp: App {
	private let facilities: FacilitiesFactory
	private let bluetooth: BTClient
	private let mDNS: MDNSClient
	private let powerFunction: PFClient
	private var cancellables = Set<AnyCancellable>()

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

		bluetooth.$devices
			.receive(on: DispatchQueue.main)
			.sink { [weak facilities] (devices: [BTDevice]) in
				facilities?.devicesDidChange(devices)
			}
			.store(in: &cancellables)

		mDNS.$devices
			.receive(on: DispatchQueue.main)
			.sink { [weak facilities] (devices: [MDNSDevice]) in
				facilities?.devicesDidChange(devices)
			}
			.store(in: &cancellables)

		powerFunction.$devices
			.receive(on: DispatchQueue.main)
			.sink { [weak facilities] (devices: [PFDevice]) in
				facilities?.devicesDidChange(devices)
			}
			.store(in: &cancellables)
	}

	@SceneBuilder var body: some Scene {
		WindowGroup {
			FacilitiesListView(facilities: facilities)
		}
	}
}


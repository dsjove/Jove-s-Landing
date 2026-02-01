//
//  Christof.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/22/25.
//

import Foundation
import SBJKit
import BLEByJove
import Combine
import Observation
import SBJLego

@Observable
public final class Christof: Facility, PFTransmitter {
	public static let Service = BTServiceIdentity(name: "Christof")
	public var id: UUID { device.id }
	private let device: BTDevice
	private var sink: Set<AnyCancellable> = []

	public let streetLights: BTLighting
	public let fpTransmitter: PFBTRransmitter

	public private(set) var connectionState: ConnectionState {
		didSet {
			switch connectionState {
				case .connected:
					break
				case .connecting:
					break
				case .disconnected:
					reset()
			}
		}
	}

	public var pfConnectionState: ConnectionState {
		self.connectionState
	}

	public convenience init() {
		self.init(device: .init(preview: "Sample"))
	}

	public init(device: BTDevice) {
		self.device = device
		self.connectionState = device.connectionState
		self.streetLights = BTLighting(device: device)
		self.fpTransmitter = PFBTRransmitter(
			device: device,
			component: FacilityPropComponent.motion,
			category: FacilityPropCategory.power)

		device.$connectionState.dropFirst().sink { [weak self] in
			self?.connectionState = $0
		}.store(in: &sink)
	}

	public var category: FacilityCategory { .transportation }
	public var image: ImageName { .system("building") }
	public var name : String { Christof.Service.name }

	public func connect() {
		device.connect()
	}

	public func disconnect() {
		device.disconnect()
	}

	public func transmit(cmd: PFCommand) {
		self.fpTransmitter.transmit(cmd: cmd)
	}

	public func reset() {
		self.streetLights.reset()
	}

	public func fullStop() {
		self.streetLights.fullStop()
	}
}

/*

//					Grid(alignment: .leading, horizontalSpacing: 12) {
//						LightingControlsView(lighting: facility.streetLights)
//					}
 */

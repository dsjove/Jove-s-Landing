//
//  PFFacility.swift
//  Infrastructure
//
//  Created by David Giovannini on 1/17/26.
//

import Foundation
import BLEByJove
import SBJKit

public class PFFacility: ObservableObject, MotorizedFacility {
	private let device: PFDevice
	public let category: FacilityCategory

	public var id: UUID { device.id }
	public var name: String { device.name }

	public private(set) var motor: PFMotor;
	public private(set) var lighting: PFLighting;

	init(device: PFDevice, category: FacilityCategory) {
		self.device = device
		self.category = category
		self.motor = PFMotor(device: device)
		self.lighting = PFLighting(device: device)
	}

	public var image: ImageName { .system("car") }

	public var connectionState: BLEByJove.ConnectionState { .connected }
	public func connect() {}
	public func disconnect() {}

	public func reset() {
		self.motor.reset()
		self.lighting.reset()
	}

	public func fullStop() {
		self.motor.fullStop()
		self.lighting.fullStop()
	}
}

//
//  CityStreets.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/22/25.
//

import Foundation
import Combine
import SwiftUI
import BLEByJove

public class CityStreets: ObservableObject, MotorizedFacility {
	public static let Service = BTServiceIdentity(name: "City Streets")
	public var id: UUID { device.id }
	private let device: BTDevice
	private var sink: Set<AnyCancellable> = []

	public private(set) var motor: BTMotor;
	public private(set) var lighting: BTLighting;
	public private(set) var display: ArduinoDisplay;
	public private(set) var rail: TrainRail;

	public init(device: BTDevice) {
		self.device = device
		self.connectionState = device.connectionState
		self.motor = Motor(device: device)
		self.lighting = BTLighting(device: device)
		self.display = ArduinoDisplay(device: device)
		self.rail = TrainRail(device: device)

		device.$connectionState.dropFirst().sink { [weak self] in
			self?.connectionState = $0
		}.store(in: &sink)
	}

	public convenience init() {
		self.init(device: .init(preview: "Sample"))
	}

	public var category: FacilityCategory { .transportation }
	public var image: Image { Image(systemName: "car") }
	public var name : String {CityStreets.Service.name}

	public func connect() {
		device.connect()
	}

	public func disconnect() {
		device.disconnect()
	}

	@Published
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

	public func reset() {
		self.motor.reset()
		self.lighting.reset()
		self.display.reset()
		self.rail.reset()
	}

	public func fullStop() {
		self.motor.fullStop()
		self.lighting.fullStop()
		self.display.fullStop()
		self.rail.fullStop()
	}
}

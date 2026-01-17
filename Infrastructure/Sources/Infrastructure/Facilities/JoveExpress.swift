//
//  JoveExpress.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/22/25.
//

import Foundation
import Combine
import SBJKit
import BLEByJove

public class JoveExpress: ObservableObject, MotorizedFacility {
	public static let Service = BTServiceIdentity(name: "Jove Express")
	public var id: UUID { device.id }
	private let device: BTDevice
	private var sink: Set<AnyCancellable> = []

	public private(set) var motor: BTMotor;
	public private(set) var lighting: BTLighting;

	public init(device: BTDevice) {
		self.device = device
		self.connectionState = device.connectionState
		self.motor = Motor(device: device)
		self.lighting = BTLighting(device: device)

		device.$connectionState.dropFirst().sink { [weak self] in
			self?.connectionState = $0
		}.store(in: &sink)
	}

	public convenience init() {
		self.init(device: .init(preview: "Sample"))
	}

	public var category: FacilityCategory { .transportation }
	public var image: ImageName { .system("train.side.front.car") }
	public var name : String {JoveExpress.Service.name}

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
	}

	public func fullStop() {
		self.motor.fullStop()
		self.lighting.fullStop()
	}
}

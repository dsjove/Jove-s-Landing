//
//  CityStreets.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/22/25.
//

import Foundation
import SBJKit
import BLEByJove
import Combine
import Observation

@Observable
public final class CityStreets: PowerFunctionsRemote, MotorizedFacility, RFIDProducing {
	public static var rfid: KeyPath<CityStreets, BLEByJove.RFIDDetection> {
		\.rail.sensedTrain.feedback
	}

	public static let Service = BTServiceIdentity(name: "City Streets")
	public var id: UUID { device.id }
	private let device: BTDevice
	private var sink: Set<AnyCancellable> = []

	public private(set) var motor: BTMotor; // todo: street power
	public private(set) var lighting: BTLighting;
	public private(set) var display: ArduinoDisplay;
	public private(set) var rail: TrainRail;

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

	public private(set) var currentTrain: TrainDetection?

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

		observe(for: self, with: rail, \.currentTrain) { this, _, value in
			this.updateCurrentTrain(value)
		}
	}

	public convenience init() {
		self.init(device: .init(preview: "Sample"))
	}

	public var category: FacilityCategory { .transportation }
	public var image: ImageName { .system("car") }
	public var name : String { CityStreets.Service.name }

	public func transmit(cmd: PFCommand) {
		rail.powerFunction(cmd)
	}

	public func connect() {
		device.connect()
	}

	public func disconnect() {
		device.disconnect()
	}

	private func updateCurrentTrain(_ train: TrainDetection?) {
		self.currentTrain = train
		let sound: SoundPlayer.Source
		let symbol: ArduinoR4Matrix?
		if let train {
			if train.anotherRound {
				sound = train.registration.sound
				symbol = train.registration.symbol
			}
			else {
				sound = .system(1306)
				symbol = nil
			}
		}
		else {
			sound = .none
			symbol = ArduinoR4Matrix()
		}
		SoundPlayer.shared.play(sound)
		if let symbol {
			self.display.power.control = symbol
		}
	}

	public func reset() {
		self.motor.reset()
		self.lighting.reset()
		self.display.reset()
		self.rail.reset()
		self.currentTrain = nil
	}

	public func fullStop() {
		self.motor.fullStop()
		self.lighting.fullStop()
		self.display.fullStop()
		self.rail.fullStop()
		self.currentTrain = nil
	}
}

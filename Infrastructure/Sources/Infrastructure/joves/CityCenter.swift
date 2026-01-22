//
//  CityCenter.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/22/25.
//

//TODO: Move Out of infrastructure package

import Foundation
import SBJKit
import BLEByJove
import Combine
import Observation

public struct TrainRegistration {
	public let info: PFMeta
	public let sound: SoundPlayer.Source
	public let symbol: ArduinoR4Matrix?

    public init(info: PFMeta, sound: SoundPlayer.Source, symbol: ArduinoR4Matrix?) {
		self.info = info
		self.sound = sound
		self.symbol = symbol
	}
}

public struct TrainDetection {
	let rfid: SampledRFIDDetection
	let registration: TrainRegistration
}

@Observable
public final class CityCenter: PFTransmitter, Facility, RFIDProducing {
	public static let Service = BTServiceIdentity(name: "City Center")
	public var id: UUID { device.id }
	private let device: BTDevice
	private var sink: Set<AnyCancellable> = []

	public let streetLights: BTLighting
	public let logoDisplay: ArduinoDisplay
	public let fpTransmitter: PFBTRransmitter
	public let rail: RFIDReceiver;

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

	public private(set) var currentTrain: TrainDetection?

	public init(device: BTDevice) {
		self.device = device
		self.connectionState = device.connectionState
		self.streetLights = BTLighting(device: device)
		self.logoDisplay = ArduinoDisplay(device: device)
		self.rail = RFIDReceiver(device: device)
		self.fpTransmitter = PFBTRransmitter(device: device)

		device.$connectionState.dropFirst().sink { [weak self] in
			self?.connectionState = $0
		}.store(in: &sink)

		observe(for: self, with: rail, \.current) { this, _, value in
			if let value {
				this.updateCurrentRail(value)
			}
		}
	}

	public var category: FacilityCategory { .transportation }
	public var image: ImageName { .system("building") }
	public var name : String { CityCenter.Service.name }

	public static var rfid: KeyPath<CityCenter, BLEByJove.RFIDDetection> {
		\.rail.received.feedback
	}

	public func transmit(cmd: PFCommand) {
		self.fpTransmitter.transmit(cmd: cmd)
	}

	public func connect() {
		device.connect()
	}

	public func disconnect() {
		device.disconnect()
	}

	private func updateCurrentRail(_ detection: SampledRFIDDetection) {
		let registration = CityCenter.trains[detection.rfid.id.id] ?? CityCenter.trains[Data()]!
		self.currentTrain = TrainDetection(rfid: detection, registration: registration)
		let sound: SoundPlayer.Source
		let symbol: ArduinoR4Matrix?
		if let train = self.currentTrain {
			if train.rfid.anotherRound {
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
			self.logoDisplay.power.control = symbol
		}
	}

	public func reset() {
		self.streetLights.reset()
		self.logoDisplay.reset()
		self.rail.reset()
		self.currentTrain = nil
	}

	public func fullStop() {
		self.streetLights.fullStop()
		self.logoDisplay.fullStop()
		self.currentTrain = nil
	}
}

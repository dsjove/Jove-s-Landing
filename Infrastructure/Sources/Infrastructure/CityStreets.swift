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
import AudioToolbox

public struct TrainRegistration: Equatable {
	public let id: Data
	public let name: String
	public let sound: String
	public let symbol: ArduinoR4Matrix?
}

public struct TrainDetection: Equatable {
	public let registration: TrainRegistration
	public let timestampMS: UInt32
}

public class CityStreets: ObservableObject, MotorizedFacility {
	public static let Service = BTServiceIdentity(name: "City Streets")
	public var id: UUID { device.id }
	private let device: BTDevice
	private var sink: Set<AnyCancellable> = []

	public private(set) var motor: BTMotor;
	public private(set) var lighting: BTLighting;
	public private(set) var display: ArduinoDisplay;
	public private(set) var rail: TrainRail;

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

	@Published
	public private(set) var currentTrain: TrainDetection?

	private func updateCurrentTrain(for detection: RFIDDetection) {
		let announce: (TrainRegistration, UInt32)->() = { registration, timestampMS in
			//print("Annnouncing")
			self.currentTrain = .init(registration: registration, timestampMS: timestampMS)
			if let symbol = registration.symbol {
				self.display.power.control = symbol
				SoundPlayer.shared.play(.asset(registration.sound))
			}
		}
		if detection.id.isZero {
			//print("Gone")
			self.currentTrain = nil
		}
		else if let current = currentTrain, detection.id.id == current.registration.id {
			let timeDiff = detection.timestampMS - current.timestampMS
			if timeDiff > 5000 {
				//print("Same \(timeDiff) announcing")
				announce(current.registration, detection.timestampMS)
			}
			else {
				//print("Same \(timeDiff) updating")
				self.currentTrain = .init(registration: current.registration, timestampMS: detection.timestampMS)
				SoundPlayer.shared.play(.system(1306))
			}
		}
		else {
			//print("New")
			let registration = self.registration[detection.id.id] ?? self.registration[Data()]!
			announce(registration, detection.timestampMS)
		}
	}

	public init(device: BTDevice) {
		self.device = device
		self.connectionState = device.connectionState
		self.motor = Motor(device: device)
		self.lighting = BTLighting(device: device)
		self.display = ArduinoDisplay(device: device)
		self.rail = TrainRail(device: device)

		updateCurrentTrain(for: self.rail.sensedTrain.feedback)

		device.$connectionState.dropFirst().sink { [weak self] in
			self?.connectionState = $0
		}.store(in: &sink)

		rail.sensedTrain.$feedback
			.removeDuplicates()
			.receive(on: DispatchQueue.main)
			.sink { [weak self] detection in
				self?.updateCurrentTrain(for: detection)
			}
			.store(in: &sink)
	}

	public private(set) var registration : [Data: TrainRegistration] = {
		let registrations: [TrainRegistration] = [
			TrainRegistration(
				id: Data([0xC0, 0x05, 0x1F, 0x3B]),
				name: "Maersk",
				sound: "TrainHorn",
				symbol: try? .init(packed: [0xe07f0fd9, 0xbcf3cf3c, 0x63c63c63])
			),
			TrainRegistration(
				id: Data([0xF0, 0xBE, 0x1F, 0x3B]),
				name: "Bare Necessities",
				sound: "CatCallWhistle",
				symbol: try? .init(packed: [0x20440280, 0x1801a658, 0x6149230c])
			),
			TrainRegistration(
				id: Data(),
				name: "Unknown",
				sound: "",
				symbol: try? .init(packed: [0x0f01f811, 0x80180700, 0x60000060])
			),
		]
		return Dictionary(uniqueKeysWithValues: registrations.map { ($0.id, $0) })
	}()

	var train: TrainRegistration? {
		get {
			self.registration[rail.sensedTrain.feedback.id.id]
		}
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


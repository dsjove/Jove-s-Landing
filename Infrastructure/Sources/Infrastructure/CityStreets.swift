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

public struct TrainRegistration {
	public let id: Data
	public let name: String
	public let sound: SoundPlayer.Source
	public let symbol: ArduinoR4Matrix?
}

public struct TrainDetection {
	public let count: Int
	public let registration: TrainRegistration
	public let detection: RFIDDetection

	public var title: String {
		"\(registration.name) (\(count))"
	}
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

	private let trains : [Data: TrainRegistration] = {
		let registrations: [TrainRegistration] = [
			TrainRegistration(
				id: Data(),
				name: "Unknown",
				sound: .none,
				symbol: try? .init(packed: [0x0f01f811, 0x80180700, 0x60000060])
			),
			TrainRegistration(
				id: Data([0xC0, 0x05, 0x1F, 0x3B]),
				name: "Maersk",
				sound: .asset("TrainHorn"),
				symbol: try? .init(packed: [0xe07f0fd9, 0xbcf3cf3c, 0x63c63c63])
			),
			TrainRegistration(
				id: Data([0xF0, 0xBE, 0x1F, 0x3B]),
				name: "Bare Necessities",
				sound: .asset("CatCallWhistle"),
				symbol: try? .init(packed: [0x20440280, 0x1801a658, 0x6149230c])
			),
		]
		return Dictionary(uniqueKeysWithValues: registrations.map { ($0.id, $0) })
	}()

	@Published
	public private(set) var currentTrain: TrainDetection?

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

	private func updateCurrentTrain(for detection: RFIDDetection) {
		let sound: SoundPlayer.Source
		let symbol: ArduinoR4Matrix?
		if detection.id.isZero {
			self.currentTrain = nil
			sound = .none
			symbol = ArduinoR4Matrix()
		}
		else if let currentTrain, currentTrain.registration.id == detection.id.id {
			let timeDiff = detection.timestampMS - currentTrain.detection.timestampMS
			let anotherRound = timeDiff > 5000
			self.currentTrain = .init(
				count: currentTrain.count + (anotherRound ? 1 : 0),
				registration: currentTrain.registration,
				detection: detection)
			sound = anotherRound ? currentTrain.registration.sound : .system(1306)
			symbol = nil
		}
		else {
			let registration = self.trains[detection.id.id] ?? self.trains[Data()]!
			self.currentTrain = .init(
				count: 1,
				registration: registration,
				detection: detection)
			sound = registration.sound
			symbol = registration.symbol
		}
		SoundPlayer.shared.play(sound)
		if let symbol {
			self.display.power.control = symbol
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

	var train: TrainRegistration? {
		get {
			self.trains[rail.sensedTrain.feedback.id.id]
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


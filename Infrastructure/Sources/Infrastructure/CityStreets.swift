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

public struct TrainRegistration: Equatable {
	public let name: String
	public let sound: String
	public let symbol: ArduinoR4Matrix?
}

public struct TrainDetection: Equatable {
	public let registration: TrainRegistration
	public let date: UInt32
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
		if detection.id.isZero {
			self.currentTrain = nil
		}
		else {
			let registration = self.registration[detection.id.id] ?? self.registration[Data()]!
			self.currentTrain = .init(registration: registration, date: detection.timeStamp)
			if let symbol = registration.symbol {
				display.power.control = symbol
			}
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

	public private(set) var registration : [Data: TrainRegistration] = [
		Data([0xC0, 0x05, 0x1F, 0x3B]) :
			TrainRegistration(
				name: "Maersk",
				sound: "TrainHorn",
				symbol: try? .init(packed: [0xe07f0fd9, 0xbcf3c63c, 0x03c03c03])
			),
		Data([0xF0, 0xBE, 0x1F, 0x3B]) :
			TrainRegistration(
				name: "Bare Necessities",
				sound: "CatCallWhistle",
				symbol: try? .init(packed: [0x20440280, 0x1801861a, 0x6549230c])
			),
		Data([]) :
			TrainRegistration(
				name: "Unknown",
				sound: "",
				symbol: try? .init(packed: [0x0f01f811, 0x80180700, 0x60000060])
			),
	]

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


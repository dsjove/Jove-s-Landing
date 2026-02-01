//
//  TrainDetection.swift
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

public struct TrainDetection {
	let rfid: SampledRFIDDetection
	let registration: PFFacilityRegistration
}

enum DockDetection: UInt8, BTSerializable {
	init() {
		self = .none
	}
	
	case none
	case detectPassive
	case dectactCharable
}

@Observable
public final class TrainStation: Facility, RFIDProducing {
	public static let Service = BTServiceIdentity(name: "Train Station")
	public var id: UUID { device.id }
	private let device: BTDevice
	private var sink: Set<AnyCancellable> = []

	public let logoDisplay: ArduinoDisplay
	public let rail: RFIDProducer;

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
	
	public convenience init() {
		self.init(device: .init(preview: "Sample"))
	}

	public init(device: BTDevice) {
		self.device = device
		self.connectionState = device.connectionState
		self.logoDisplay = ArduinoDisplay(device: device)
		self.rail = RFIDProducer(
			device: device,
			component: FacilityPropComponent.system,
			category: FacilityPropCategory.address,
			subCategory: EmptySubCategory(0))

		device.$connectionState.dropFirst().sink { [weak self] in
			self?.connectionState = $0
		}.store(in: &sink)

		observeValue(of: rail, \.currentRFID, with: self) { _, value, this in
			if let this, let value {
				this.updateCurrentRail(value)
			}
		}
	}

	public var category: FacilityCategory { .transportation }
	public var image: ImageName { .system("tram.fill.tunnel") }
	public var name : String { Self.Service.name }

	public func connect() {
		device.connect()
	}

	public func disconnect() {
		device.disconnect()
	}

	public var currentRFID: BLEByJove.SampledRFIDDetection? {
		rail.currentRFID
	}

	public func resetRFID() {
		rail.resetRFID()
		updateCurrentRail(nil)
	}

	private func updateCurrentRail(_ detection: SampledRFIDDetection?) {
		if let detection, !detection.rfid.id.isZero {
			let registration = Christof.registrations[detection.rfid.id] ?? Christof.registrations[Data()]!
			let train = TrainDetection(rfid: detection, registration: registration)
			self.currentTrain = train
			let sound: SoundPlayer.Source
			let symbol: ArduinoR4Matrix?
			if train.rfid.anotherRound {
				sound = train.registration.sound
				symbol = train.registration.symbol ?? ArduinoR4Matrix()
			}
			else {
				sound = .system(1306)
				symbol = nil
			}
			SoundPlayer.shared.play(sound)
			if let symbol {
				self.logoDisplay.power.control = symbol
			}
		}
		else {
			self.currentTrain = nil
			self.logoDisplay.power.control = .init()
		}
	}

	public func reset() {
		self.logoDisplay.reset()
		self.rail.resetRFID()
		self.currentTrain = nil
	}

	public func fullStop() {
		self.logoDisplay.fullStop()
		self.currentTrain = nil
	}
}

//
//  TrainRail.swift
//  Infrastructure
//
//  Created by David Giovannini on 1/9/26.
//

import Foundation
import BLEByJove
import SBJKit
import Observation

public struct TrainRegistration {
	public let id: Data
	public let name: String
	public let sound: SoundPlayer.Source
	public let symbol: ArduinoR4Matrix?
}

public struct TrainDetection {
	public let date = Date()
	public let count: Int
	public let anotherRound: Bool
	public let registration: TrainRegistration
	public let rfid: RFIDDetection

	public var title: String {
		"\(registration.name) (\(count))"
	}
}

@Observable
public class TrainRail {
	public typealias TrainID = BTProperty<BTValueTransformer<RFIDDetection>>
	public typealias PowerFuction = (PFCommand)->()
	public var sensedTrain: TrainID
	public var powerFunction: PowerFuction
	private var staleTimer: Timer?

	private let noiseThresholdMS = 3000
	private let silenceThresholdSecs: TimeInterval = 180.0

	public private(set) var currentTrain: TrainDetection?

	public init(device: any BTBroadcaster) {
		self.sensedTrain = .init(
			broadcaster: device,
			characteristic: BTCharacteristicIdentity(
				component: FacilityPropComponent.motion,
				category: FacilityPropCategory.address,
				channel: BTPropChannel.feedback))
		let pfChar = BTCharacteristicIdentity(
				component: FacilityPropComponent.motion,
				category: FacilityPropCategory.power)
		self.powerFunction = {
			device.send(data: $0.pack(), to: pfChar)
		}

		observe(for: self, with: sensedTrain, \.feedback) { this, _, value in
			print(value)
			this.updateCurrentTrain(for: value)
		}
	}

	deinit {
		staleTimer?.invalidate()
	}

	private func updateCurrentTrain(for detection: RFIDDetection) {
		if detection.id.isZero {
			self.currentTrain = nil
		}
		else if let currentTrain, currentTrain.registration.id == detection.id.id {
			let timeDiffMS = detection.timestampMS - currentTrain.rfid.timestampMS
			let anotherRound = timeDiffMS > noiseThresholdMS
			self.currentTrain = .init(
				count: currentTrain.count + (anotherRound ? 1 : 0),
				anotherRound: anotherRound,
				registration: currentTrain.registration,
				rfid: detection)
		}
		else {
			let registration = TrainRail.trains[detection.id.id] ?? TrainRail.trains[Data()]!
			self.currentTrain = .init(
				count: 1,
				anotherRound: true,
				registration: registration,
				rfid: detection)
		}
		let train = self.currentTrain
		DispatchQueue.main.async { [weak self] in
			self?.startStaleCheck(train)
		}
	}

	private func startStaleCheck(_ train: TrainDetection?) {
		staleTimer?.invalidate()
		guard let train else {
			staleTimer = nil
			return
		}
		staleTimer = Timer.scheduledTimer(withTimeInterval: silenceThresholdSecs, repeats: false) { [weak self] _ in
			guard let self = self else { return }
			if let current = self.currentTrain {
				if current.rfid == train.rfid {
					self.currentTrain = nil
				}
			}
		}
	}

	public func reset() {
		self.currentTrain = nil
		staleTimer?.invalidate()
		staleTimer = nil
		self.sensedTrain.reset()
	}

	public func fullStop() {
	}
}

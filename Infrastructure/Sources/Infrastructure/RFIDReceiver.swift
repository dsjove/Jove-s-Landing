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

public struct SampledRFIDDetection {
	public let date = Date()
	public let count: Int
	public let anotherRound: Bool
	public let rfid: RFIDDetection
}

@Observable
public class RFIDReceiver {
	public typealias Value = BTProperty<BTValueTransformer<RFIDDetection>>
	public typealias PowerFuction = (PFCommand)->()
	public var received: Value
	private var staleTimer: Timer?

	private let noiseThresholdMS = 3000
	private let silenceThresholdSecs: TimeInterval = 180.0

	public private(set) var current: SampledRFIDDetection?

	public init(device: any BTBroadcaster, number: UInt8 = 0) {
		self.received = .init(
			broadcaster: device,
			characteristic: BTCharacteristicIdentity(
				component: FacilityPropComponent.motion,
				category: FacilityPropCategory.address,
				subCategory: EmptySubCategory(number),
				channel: BTPropChannel.feedback))

		observe(for: self, with: received, \.feedback) { this, _, value in
			print(value)
			this.updateCurrent(for: value)
		}
	}

	deinit {
		staleTimer?.invalidate()
	}

	private func updateCurrent(for detection: RFIDDetection) {
		if detection.id.isZero {
			self.current = nil
		}
		else if let current, current.rfid.id == detection.id {
			let timeDiffMS = detection.timestampMS - current.rfid.timestampMS
			let anotherRound = timeDiffMS > noiseThresholdMS
			self.current = .init(
				count: current.count + (anotherRound ? 1 : 0),
				anotherRound: anotherRound,
				rfid: detection)
		}
		else {
			self.current = .init(
				count: 1,
				anotherRound: true,
				rfid: detection)
		}
		let train = self.current
		DispatchQueue.main.async { [weak self] in
			self?.startStaleCheck(train)
		}
	}

	private func startStaleCheck(_ train: SampledRFIDDetection?) {
		staleTimer?.invalidate()
		guard let train else {
			staleTimer = nil
			return
		}
		staleTimer = Timer.scheduledTimer(withTimeInterval: silenceThresholdSecs, repeats: false) { [weak self] _ in
			guard let self = self else { return }
			if let current = self.current {
				if current.rfid == train.rfid {
					self.current = nil
				}
			}
		}
	}

	public func reset() {
		self.current = nil
		staleTimer?.invalidate()
		staleTimer = nil
		self.received.reset()
	}
}

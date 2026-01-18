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
	public let powerFunction: PFCommand?
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
	private typealias TrainID = BTProperty<BTValueTransformer<RFIDDetection>>
	public typealias PowerFuction = (PFCommand)->()
	private var sensedTrain: TrainID
	public var powerFunction: PowerFuction
	private var staleTimer: Timer?

	private let noiseThresholdMS = 3000
	private let silenceThresholdSecs: TimeInterval = 180.0

	private let trains : [Data: TrainRegistration] = {
		let registrations: [TrainRegistration] = [
			TrainRegistration(
				id: Data(),
				name: "Unknown",
				sound: .none,
				symbol: try? .init(packed: [0x0f01f811, 0x80180700, 0x60000060]),
				powerFunction: nil
			),
			TrainRegistration(
				id: Data([0xC0, 0x05, 0x1F, 0x3B]),
				name: "Maersk",
				sound: .asset("TrainHorn"),
				symbol: try? .init(packed: [0xe07f0fd9, 0xbcf3cf3c, 0x63c63c63]),
				powerFunction: .init(channel: 1, port: .A, power: 5, mode: .single)
			),
			TrainRegistration(
				id: Data([0xF0, 0xBE, 0x1F, 0x3B]),
				name: "Bare Necessities",
				sound: .asset("CatCallWhistle"),
				symbol: try? .init(packed: [0x20440280, 0x1801a658, 0x6149230c]),
				powerFunction: nil
			),
		]
		return Dictionary(uniqueKeysWithValues: registrations.map { ($0.id, $0) })
	}()

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

		withObservationTracking({
				_ = sensedTrain.feedback
			},
			onChange: { [weak self] in
				guard let self = self else { return }
				DispatchQueue.main.async {
					self.updateCurrentTrain(for: self.sensedTrain.feedback)
				}
				withObservationTracking( {
						_ = self.sensedTrain.feedback
					},
					onChange: { [weak self] in
						guard let self = self else { return }
						DispatchQueue.main.async {
							self.updateCurrentTrain(for: self.sensedTrain.feedback)
						}
					}
				)
			}
		)
		updateCurrentTrain(for: sensedTrain.feedback)
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
			let registration = self.trains[detection.id.id] ?? self.trains[Data()]!
			self.currentTrain = .init(
				count: 1,
				anotherRound: true,
				registration: registration,
				rfid: detection)
		}
		let train = self.currentTrain
		if let pf = train?.registration.powerFunction {
			self.powerFunction(pf)
		}
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

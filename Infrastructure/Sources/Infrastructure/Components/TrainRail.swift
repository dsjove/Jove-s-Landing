//
//  RailwayFacility.swift
//  Infrastructure
//
//  Created by David Giovannini on 1/9/26.
//

import Foundation
import BLEByJove

public struct TrainRail {
	public typealias TrainID = BTProperty<BTValueTransformer<RFIDDetection>>
	public private(set) var sensedTrain: TrainID

	public init(device: any BTBroadcaster) {
		self.sensedTrain = TrainID(
			broadcaster: device,
			characteristic: BTCharacteristicIdentity(
				component: FacilityPropComponent.motion,
				category: FacilityPropCategory.sensed,
				channel: BTPropChannel.feedback))
	}

	public func reset() {
		self.sensedTrain.reset()
	}

	public func fullStop() {
	}
}

//
//  RailwayFacility.swift
//  Infrastructure
//
//  Created by David Giovannini on 1/9/26.
//


import Foundation
import BLEByJove

public struct RFIDDetection: Equatable, Hashable, BTSerializable {
	public let timestampMS: UInt32
	public let id: CountedBytes

	public var packedSize: Int {
		timestampMS.packedSize + id.packedSize
	}
	
	public init() {
		timestampMS = 0
		id = .init()
	}

	public func pack(btData data: inout Data) {
		timestampMS.pack(btData: &data)
		id.pack(btData: &data)
	}
	
	public init(unpack data: Data, _ cursor: inout Int) throws {
		timestampMS = try .init(unpack: data, &cursor)
		id = try .init(unpack: data, &cursor)
	}
}

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

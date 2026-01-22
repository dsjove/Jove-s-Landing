//
//  Engine.swift
//  BLEByJove
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Software by Jove. All rights reserved.
//

import Foundation
import BLEByJove

public typealias EngineRational = FogRational<Int8>

public struct Engine {
	public var calibration: BTSubject<EngineRational>
	public var power: BTSubject<EngineRational>
	
	public init(broadcaster: BTBroadcaster) {
		self.calibration = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.motor, FacilityPropCategory.calibration),
			broadcaster,
			EngineRational())
		self.power = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.motor, FacilityPropCategory.power),
			broadcaster,
			EngineRational())
	}
	
	public func reset() {
		calibration.reset()
		power.reset()
	}
}

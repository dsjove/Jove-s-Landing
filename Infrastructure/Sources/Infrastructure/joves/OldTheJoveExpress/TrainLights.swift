//
//  Lights.swift
//  BLEByJove
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Software by Jove. All rights reserved.
//

import Foundation
import BLEByJove

public typealias LightsRational = FogRational<UInt8>

public enum LightCommand: Int8, FogExternalizable, CaseIterable {
	public init() {
		self = .auto
	}
	case auto = -1
	case on = 1
	case off = 0

	public var position: UInt8 {
		switch self {
		case .auto:
			return 127
		case .on:
			return 189
		case .off:
			return 63
		}
	}
	
	public var description: String {
		switch self {
		case .auto:
			return "Auto"
		case .off:
			return "Off"
		case .on:
			return "On"
		}
	}
	
	public var symbol: String {
		switch self {
		case .auto:
			return "🌓"
		case .off:
			return "🌑"
		case .on:
			return "🌕"
		}
	}
}

public struct Lights {
	public var calibration: BTSubject<LightsRational>
	public var power: BTSubject<LightCommand>
	public var state: BTSubject<Bool>
	public var ambient: BTSubject<LightsRational>

	public init(broadcaster: BTBroadcaster) {
		self.calibration = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.lights, FacilityPropCategory.calibration),
			broadcaster,
			LightsRational())
		self.power = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.lights, FacilityPropCategory.power),
			broadcaster,
			.auto)
		self.state = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.lights, FacilityPropCategory.state),
			broadcaster,
			false)
		self.ambient = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.lights, FacilityPropCategory.sensed),
			broadcaster,
			LightsRational())
	}
	
	public func reset() {
		calibration.reset()
		power.reset()
		state.reset()
		ambient.reset()
	}
}

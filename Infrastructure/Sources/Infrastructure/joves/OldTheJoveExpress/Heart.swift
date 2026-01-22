//
//  Heart.swift
//  
//
//  Created by David Giovannini on 7/14/21.
//

import Foundation
import BLEByJove

public struct HeartHealth: FogExternalizable, Equatable, CustomStringConvertible {
	public let cpuUsage: Int16
	public let cpuTemp: Int16
	public let internalTemp: Int16
	public let underVoltage: Bool
	public let charging: Bool

	public init() {
		self.cpuUsage = 0
		self.cpuTemp = 0
		self.internalTemp = 0
		self.underVoltage = false
		self.charging = false
	}

	public init(fog data: Data, at cursor: inout Int, old: Self?) throws {
		self.cpuUsage = try Int16(fog: data, at: &cursor)
		self.cpuTemp = try Int16(fog: data, at: &cursor)
		self.internalTemp = try Int16(fog: data, at: &cursor)
		self.underVoltage = try Bool(fog: data, at: &cursor)
		self.charging = try Bool(fog: data, at: &cursor)
	}
	
	public var fogSize: Int {
		cpuUsage.fogSize +
		cpuTemp.fogSize +
		internalTemp.fogSize +
		underVoltage.fogSize +
		charging.fogSize
	}

	public func write(fog data: inout Data) {
		self.cpuUsage.write(fog: &data)
		self.cpuTemp.write(fog: &data)
		self.internalTemp.write(fog: &data)
		self.underVoltage.write(fog: &data)
		self.charging.write(fog: &data)
	}
	
	public var description: String {
		"\(cpuUsage)% \(cpuTemp)C \(internalTemp)C \(self.underVoltage ? "↓" : "↑")\(self.charging ? "*" : "-")"
	}
}

public struct Heart {
	public var limits: BTSubject<HeartHealth>
	public var beat: BTSubject<UInt8>
	public var fullStop: BTSubject<Bool>
	public var health: BTSubject<HeartHealth>

	public init(broadcaster: BTBroadcaster) {
		self.limits = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.heart, FacilityPropCategory.calibration),
			broadcaster,
			HeartHealth())
		self.fullStop = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.heart, FacilityPropCategory.power),
			broadcaster,
			false)
		self.beat = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.heart, FacilityPropCategory.state),
			broadcaster,
			0)
		self.health = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.heart, FacilityPropCategory.sensed),
			broadcaster,
			HeartHealth())
	}
	
	public func reset() {
		limits.reset()
		fullStop.reset()
		beat.reset()
		health.reset()
	}
}

//
//  Facility.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/26/25.
//

import SBJKit
import BLEByJove
import Foundation
import Network

extension FacilityCategory {
	static let transportation = FacilityCategory("transportation")
	static let housing = FacilityCategory("housing")
}

public typealias IPv4AddressProperty = BTProperty<BTValueTransformer<IPv4Address>>

public protocol MotorizedFacility: Facility {
	associatedtype Lighting: LightingProtocol
	associatedtype Motor: MotorProtocol
	
	var lighting: Lighting { get }
	
	var motor: Motor { get }
}

@Observable
public class UnsupportedFacility: Facility {
	public let id = UUID()
	public let name: String
	public let category: FacilityCategory = .transportation
	public let image: ImageName = .system("questionmark.diamond")

	public let connectionState: BLEByJove.ConnectionState = .disconnected

	public init(name: String) {
		self.name = name
	}

	public func connect() {}

	public func fullStop() {}

	public func disconnect() {}

	public var battery: Double? { 0.0 }

	public func hash(into hasher: inout Hasher) {
		id.hash(into: &hasher)
	}
}

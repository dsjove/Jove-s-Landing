//
//  Facility.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/26/25.
//

import SBJKit
import BLEByJove
import Foundation
import Combine
import Network

public protocol Facility: ObservableObject, Identifiable {
	var id: UUID { get }
	var category: FacilityCategory { get }
	var name: String { get }
	var image: ImageName { get }

	var connectionState: ConnectionState { get }

	var heartBeat: Int { get }

	func connect()

	func fullStop()

	func disconnect()
	
	var battery: Double? { get }
}

public extension Facility {
	var heartBeat: Int { connectionState == .connected ? 0 : -1 }

	var battery: Double? { nil }
}

public typealias IPv4AddressProperty = BTProperty<BTValueTransformer<IPv4Address>>

public protocol MotorizedFacility: Facility {
	associatedtype Lighting: LightingProtocol
	associatedtype Motor: MotorProtocol
	
	var lighting: Lighting { get }
	
	var motor: Motor { get }
}

public class UnsupportedFacility: Facility {
	public let id = UUID()
	public let name: String
	public let category: Infrastructure.FacilityCategory = .transportation
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

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

extension FacilityRepository {
	public convenience init() {
		self.init(facilitiesForDevice: { device in
			let newFacilities: [any Facility]
			if let btDevice = device as? BTDevice {
				switch btDevice.service {
					case JoveMetroLine.Service:
						newFacilities = [JoveMetroLine(device: btDevice)]
					case CityStreets.Service:
						newFacilities = [CityStreets(device: btDevice)]
					case JoveExpress.Service:
						newFacilities = [JoveExpress(device: btDevice)]
					default:
						newFacilities = [UnsupportedFacility(name: btDevice.name)]
				}
			}
			else if let mDNSDevice = device as? MDNSDevice {
				switch mDNSDevice.service {
					case ESPCam.Service:
						newFacilities = [ESPCam(device: mDNSDevice)]
					default:
						newFacilities = [UnsupportedFacility(name: mDNSDevice.name)]
				}
			}
			else if let pfDevice = device as? PFDevice {
				newFacilities = [PFFacility(device: pfDevice, category: .transportation)]
			}
			else {
				newFacilities = [UnsupportedFacility(name: device.name)]
			}
			return newFacilities
		})
	}
}

extension MDNSClient {
	private static var mocking: Bool {
		#if targetEnvironment(simulator)
			true
		#else
			false
		#endif
	}

	public static let services: [String] = {
		var base = [
			ESPCam.Service,
		]
		if (mocking) {
			base.append("Garbage")
		}
		print(base)
		return base
	}()
	
	public convenience init() {
		self.init(services: Self.services)
	}
}

extension BTClient {
	public convenience init() {
		self.init(services: {
			let base = [
				CircuitCube.Service,
				CityStreets.Service,
				JoveExpress.Service,
			]
			print(base.map { "\($0.name)=\($0.identifer.uuidString)"})
			return base
		}())
	}
}

extension PFClient {
	public convenience init() {
		self.init(knownDevices: [], transmit: {_ in })
	}
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

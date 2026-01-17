//
//  FacilitiesFactory.swift
//  Infrastructure
//
//  Created by David Giovannini on 12/24/22.
//

import BLEByJove
import SBJKit
import Foundation

public typealias FacilityEntry = Identified<any Facility>

public class FacilitiesFactory: ObservableObject {
	private var cache: [UUID: [FacilityEntry]] = [:]

	@Published public private(set) var entries: [FacilityEntry] = []

	public init() {
		updateFacilities()
	}

	public func devicesDidChange(_ devices: [any DeviceIdentifiable]) {
		for device in devices {
			implementation(for: device)
		}
		updateFacilities()
	}

	private func updateFacilities() {
		let allEntries: [FacilityEntry] = cache.values.flatMap { $0 }
		let sortedEntries = allEntries.sorted { lhs, rhs in
			let ln = lhs.value.name
			let rn = rhs.value.name
			if ln == rn {
				return lhs.id.uuidString < rhs.id.uuidString
			}
			return ln < rn
		}
		entries = sortedEntries
	}

	@discardableResult
	private func implementation(for device: any DeviceIdentifiable) -> [FacilityEntry] {
		if let existing = cache[device.id] {
			return existing
		}
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

		let entries = newFacilities.map { FacilityEntry($0) }
		cache[device.id, default: []].append(contentsOf: entries)
		return cache[device.id]!
	}
}


extension PFClient {
	public convenience init() {
		self.init(knownDevices: [], transmit: {_ in })
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
	public static let services: [BTServiceIdentity] = {
		var base = [
			CircuitCube.Service,
			CityStreets.Service,
			JoveExpress.Service,
		]
		print(base.map { "\($0.name)=\($0.identifer.uuidString)"})
		return base
	}()

	public convenience init() {
		self.init(services: Self.services)
	}
}


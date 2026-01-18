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
	private let rfid: (RFIDDetection)->()
	private var cache: [UUID: [FacilityEntry]] = [:]

	@Published public private(set) var entries: [FacilityEntry] = []

	private(set) var scanners: [any DeviceScanning] = []

	public func addScanner(_ scanner: any DeviceScanning) {
		scanners.append(scanner)
	}

	public func setScanning(_ scanning: Bool) {
		for scanner in scanners {
			scanner.scanning = scanning
		}
	}

	public init(rfid: @escaping (RFIDDetection)->()) {
		self.rfid = rfid
		updateFacilities()
	}

	public func devicesDidChange(_ devices: [any DeviceIdentifiable]) {
		// Treat the provided devices as the complete, authoritative list from all sources.
		// Build a set of current device IDs.
		let currentIDs = Set(devices.map { $0.id })

		// Ensure implementations exist for all current devices (adds to cache as needed).
		for device in devices {
			implementation(for: device)
		}

		// Remove any cached entries for devices that are no longer present.
		if !cache.isEmpty {
			cache.keys
				.filter { !currentIDs.contains($0) }
				.forEach { cache.removeValue(forKey: $0) }
		}

		// Refresh published entries sorted
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

extension FacilitiesFactory: PowerFunctionsRemote {
	public func transmit(cmd: PFCommand) {
		entries
			.lazy
			.compactMap { $0.value as? PowerFunctionsRemote }
			.first?.transmit(cmd: cmd)
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

// MARK: - Aggregator for authoritative device list across sources
public final class FacilitiesAggregator {
    private let factory: FacilitiesFactory

    // Snapshots from each source
    private var btDevices: [any DeviceIdentifiable] = []
    private var mdnsDevices: [any DeviceIdentifiable] = []
    private var pfDevices: [any DeviceIdentifiable] = []

    public init(factory: FacilitiesFactory) {
        self.factory = factory
    }

    // Update functions for each source. Call these whenever that source changes.
    public func updateBTDevices(_ devices: [any DeviceIdentifiable]) {
        btDevices = devices
        emitCombined()
    }

    public func updateMDNSDevices(_ devices: [any DeviceIdentifiable]) {
        mdnsDevices = devices
        emitCombined()
    }

    public func updatePFDevices(_ devices: [any DeviceIdentifiable]) {
        pfDevices = devices
        emitCombined()
    }

    // Combine all three sources into an authoritative list by id
    private func emitCombined() {
        let combined = btDevices + mdnsDevices + pfDevices
        // Deduplicate by id with first-wins policy; adjust if you need precedence
        let deduped: [any DeviceIdentifiable] = Array(
            Dictionary(grouping: combined, by: { $0.id })
                .compactMap { $0.value.first }
        )
        factory.devicesDidChange(deduped)
    }
}


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

//MARK: Facility Creation

extension FacilityCategory {
	static let transportation = FacilityCategory("transportation")
	static let housing = FacilityCategory("housing")
}

extension FacilityRepository {
	public convenience init() {
		self.init() { device in
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
		}
	}
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
}

public protocol MotorizedFacility: Facility {
	associatedtype Lighting: LightingProtocol
	associatedtype Motor: MotorProtocol

	var motor: Motor { get }
	var lighting: Lighting? { get }
}

public extension MotorizedFacility {
	func fullStop() {
		motor.fullStop()
		lighting?.fullStop()
	}
}

//MARK: Scanner Inits

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
	public convenience init(transmitter: PFTransmitter) {
		self.init(meta: PFClient.meta, transmitter: transmitter)
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

//MARK: Facility Intance Info

extension PFClient {
	static let info: [Data: PFMeta] = {
		let metas: [PFMeta] = [
			PFMeta(
				id: Data([0xC0, 0x05, 0x1F, 0x3B]),
				channel: 1,
				name: "Maersk",
				image: .bundled("Train", .module),
				mode: .single
			)
		]
		return Dictionary(uniqueKeysWithValues: metas.map { ($0.id, $0) })
	}()

	static let meta: (RFIDDetection)->PFMeta? = { id in
		PFClient.info[id.id.id]
	}
}

extension TrainRail {
	static let trains : [Data: TrainRegistration] = {
		let registrations: [TrainRegistration] = [
			TrainRegistration(
				id: Data(),
				name: "Unknown",
				sound: .none,
				symbol: try? .init(packed: [0x0f01f811, 0x80180700, 0x60000060])
			),
			TrainRegistration(
				id: Data([0xC0, 0x05, 0x1F, 0x3B]),
				name: "Maersk",
				sound: .asset("TrainHorn"),
				symbol: try? .init(packed: [0xe07f0fd9, 0xbcf3cf3c, 0x63c63c63])
			),
			TrainRegistration(
				id: Data([0xF0, 0xBE, 0x1F, 0x3B]),
				name: "Bare Necessities",
				sound: .asset("CatCallWhistle"),
				symbol: try? .init(packed: [0x20440280, 0x1801a658, 0x6149230c])
			),
		]
		return Dictionary(uniqueKeysWithValues: registrations.map { ($0.id, $0) })
	}()
}

public typealias IPv4AddressProperty = BTProperty<BTValueTransformer<IPv4Address>>


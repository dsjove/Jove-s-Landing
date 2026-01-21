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
		addScanner(BTClient())
		addScanner(MDNSClient())
		addScanner(PFClient(transmitter: self))
	}
}

//MARK: Facility Specialization

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

public typealias IPv4AddressProperty = BTProperty<BTValueTransformer<IPv4Address>>

//MARK: Facility Instance Info
//TODO: Move instances out of infrastructure package

extension PFClient {
	static let meta: (RFIDDetection)->PFMeta? = { detected in
		TrainRail.trains[detected.id.id]?.info
	}
}

extension TrainRail {
	static let trains : [Data: TrainRegistration] = {
		let registrations: [TrainRegistration] = [
			TrainRegistration(
				info: .init(
					id: Data(),
					channel: 0,
					name: "Unknown",
					image: .bundled("Train", .module),
					mode: .single
				),
				sound: .none,
				symbol: try? .init(packed: [0x0f01f811, 0x80180700, 0x60000060])
			),
			TrainRegistration(
				info: .init(
					id: Data([0xC0, 0x05, 0x1F, 0x3B]),
					channel: 1,
					name: "Maersk",
					image: .bundled("Train", .module),
					mode: .single
				),
				sound: .asset("TrainHorn"),
				symbol: try? .init(packed: [0xe07f0fd9, 0xbcf3cf3c, 0x63c63c63])
			),
			TrainRegistration(
				info: .init(
					id: Data([0xF0, 0xBE, 0x1F, 0x3B]),
					channel: 2,
					name: "Bare Necessities",
					image: .bundled("Train", .module),
					mode: .single
				),
				sound: .asset("CatCallWhistle"),
				symbol: try? .init(packed: [0x20440280, 0x1801a658, 0x6149230c])
			),
		]
		return Dictionary(uniqueKeysWithValues: registrations.map { ($0.info.id, $0) })
	}()
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

//
//  FacilityRepository.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/26/25.
//

import SBJKit
import BLEByJove
import Foundation
import SBJLego

public struct PFFacilityRegistration: PFFacilityMeta, Comparable, Equatable, Identifiable {
	public let id: Data
	public let channel: UInt8
	public var mode: BLEByJove.PFMode = .single
	public var timeout: TimeInterval = 0

	public let category: FacilityCategory
	public let name: String
	public let image: SBJKit.ImageName

	public var sound: SoundPlayer.Source = .none
	//public var symbol: ArduinoR4Matrix? = nil

	public static func < (lhs: PFFacilityRegistration, rhs: PFFacilityRegistration) -> Bool {
		let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
		if nameOrder != .orderedSame {
			return nameOrder == .orderedAscending
		}
		return lhs.id.lexicographicallyPrecedes(rhs.id)
	}

	public static func == (lhs: PFFacilityRegistration, rhs: PFFacilityRegistration) -> Bool {
		lhs.id == rhs.id
	}
}

extension FacilityRepository {
	private static var mocking: Bool {
		#if targetEnvironment(simulator)
			true
		#else
			false
		#endif
	}

	private static var btServices: [BTServiceIdentity] = [
		CircuitCube.Service,
		Christof.Service,
		TrainStation.Service,
		JoveExpress.Service,
	]

	private static let mDnsServices: [String] = {
		var base = [
			ESPCam.Service,
		]
		if (mocking) {
			base.append("Garbage")
		}
		print(base)
		return base
	}()

	public static func jovesLanding() -> Self {
		let facility = Self()
		facility.addScanner(BTClient(services: Self.btServices)) { btDevice in
			switch btDevice.service {
				case JoveMetroLine.Service:
					[JoveMetroLine(device: btDevice)]
				case Christof.Service:
					{
						facility.consumeRFID(.init(rfid:
							.init(reader: 1, id: Christof.lightHouseId)))
						return [Christof(device: btDevice)]
					}()
				case TrainStation.Service:
					[TrainStation(device: btDevice)]
				case JoveExpress.Service:
					[JoveExpress(device: btDevice)]
				default:
					[UnsupportedFacility(name: btDevice.name)]
			}
		}
		facility.addScanner(MDNSClient(services: Self.mDnsServices)) { mDNSDevice in
			switch mDNSDevice.service {
				case ESPCam.Service:
					[ESPCam(device: mDNSDevice)]
				default:
					[UnsupportedFacility(name: mDNSDevice.name)]
			}
		}
		facility.addScanner(PFClient<PFFacilityRegistration>(transmitter: facility) {
			Christof.registrations[$0.rfid.id]
		}) { pfDevice in
			[PFFacility(device: pfDevice)]
		}
		return facility
	}
}

extension Christof {
	static var lightHouseId: Data { .init([0x00, 0x11, 0x22, 0x33]) }

	static let registrations: [Data: PFFacilityRegistration] = {
		let list: [PFFacilityRegistration] = [
			PFFacilityRegistration(
				id: Data(),
				channel: 0,
				category: FacilityCategory.transportation,
				name: "Unknown",
				image: .bundled("Train", SBJLego.Resources.bundle)//,
			),
			PFFacilityRegistration(
				id: Data([0xC0, 0x05, 0x1F, 0x3B]),
				channel: 1,
				category: FacilityCategory.transportation,
				name: "Maersk",
				image: .bundled("Train", SBJLego.Resources.bundle),
				sound: .asset("TrainHorn")
			),
			PFFacilityRegistration(
				id: Data([0xF0, 0xBE, 0x1F, 0x3B]),
				channel: 2,
				timeout: 30,
				category: FacilityCategory.transportation,
				name: "Bare Necessities",
				image: .bundled("Train", SBJLego.Resources.bundle),
				sound: .asset("CatCallWhistle")
			),
			PFFacilityRegistration(
				id: lightHouseId,
				channel: 3,
				category: FacilityCategory.transportation,
				name: "Light House",
				image: .system("light.beacon.min")
			),
		]
		return Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
	}()
}

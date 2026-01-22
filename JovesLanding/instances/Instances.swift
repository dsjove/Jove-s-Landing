//
//  Instances.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/26/25.
//

//TODO: Move Out of infrastructure package

import SBJKit
import BLEByJove
import Foundation
import SBJLego

public struct PFFacilityRegistration: PFFacilityMeta {
	public let id: Data
	public let channel: UInt8
	public var mode: BLEByJove.PFMode = .single
	public var timeout: TimeInterval = 0

	public let category: FacilityCategory
	public let name: String
	public let image: SBJKit.ImageName

	public var sound: SoundPlayer.Source = .none
	public var symbol: ArduinoR4Matrix? = nil
}

//MARK: Facility Creation

extension FacilityRepository {
	public convenience init() {
		self.init() { device in
			if let btDevice = device as? BTDevice {
				switch btDevice.service {
					case JoveMetroLine.Service:
						[JoveMetroLine(device: btDevice)]
					case CityCenter.Service:
						[CityCenter(device: btDevice)]
					case JoveExpress.Service:
						[JoveExpress(device: btDevice)]
					default:
						[UnsupportedFacility(name: btDevice.name)]
				}
			}
			else if let mDNSDevice = device as? MDNSDevice {
				switch mDNSDevice.service {
					case ESPCam.Service:
						[ESPCam(device: mDNSDevice)]
					default:
						[UnsupportedFacility(name: mDNSDevice.name)]
				}
			}
			else if let pfDevice = device as? PFDevice<PFFacilityRegistration> {
				[PFFacility(device: pfDevice)]
			}
			else {
				[UnsupportedFacility(name: "Unknown")]
			}
		}
		addScanner(BTClient())
		addScanner(MDNSClient())
		addScanner(PFClient<PFFacilityRegistration>(transmitter: self))
	}
}

//MARK: Facility Instance Info

extension PFClient<PFFacilityRegistration> {
	static let meta: (SampledRFIDDetection)->PFFacilityRegistration? = { detected in
		CityCenter.trains[detected.rfid.id]
	}
}

extension JoveMetroLine {
	public convenience init() {
		self.init(device: .init(preview: "Sample"))
	}
}

extension JoveExpress {
	public convenience init() {
		self.init(device: .init(preview: "Sample"))
	}
}

extension CityCenter {
	public convenience init() {
		self.init(device: .init(preview: "Sample"))
	}

	static let trains : [Data: PFFacilityRegistration] = {
		let registrations: [PFFacilityRegistration] = [
			PFFacilityRegistration(
				id: Data(),
				channel: 0,
				category: FacilityCategory.transportation,
				name: "Unknown",
				image: .bundled("Train", SBJLego.Resources.bundle),
				symbol: try? .init(packed: [0x0f01f811, 0x80180700, 0x60000060])
			),
			PFFacilityRegistration(
				id: Data([0xC0, 0x05, 0x1F, 0x3B]),
				channel: 1,
				category: FacilityCategory.transportation,
				name: "Maersk",
				image: .bundled("Train", SBJLego.Resources.bundle),
				sound: .asset("TrainHorn"),
				symbol: try? .init(packed: [0xe07f0fd9, 0xbcf3cf3c, 0x63c63c63])
			),
			PFFacilityRegistration(
				id: Data([0xF0, 0xBE, 0x1F, 0x3B]),
				channel: 2,
				timeout: 30,
				category: FacilityCategory.transportation,
				name: "Bare Necessities",
				image: .bundled("Train", SBJLego.Resources.bundle),
				sound: .asset("CatCallWhistle"),
				symbol: try? .init(packed: [0x20440280, 0x1801a658, 0x6149230c])
			),
		]
		return Dictionary(uniqueKeysWithValues: registrations.map { ($0.id, $0) })
	}()
}

//MARK: Scanner Inits

extension BTClient {
	public convenience init() {
		self.init(services: {
			let base = [
				CircuitCube.Service,
				CityCenter.Service,
				JoveExpress.Service,
			]
			print(base.map { "\($0.name)=\($0.identifer.uuidString)"})
			return base
		}())
	}
}

extension PFClient<PFFacilityRegistration> {
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

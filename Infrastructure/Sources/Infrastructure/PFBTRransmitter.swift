import Foundation
import BLEByJove

public struct PFBTRransmitter: PFTransmitter {
	let device: BTDevice

	static let coast: Int8 = -128
	static let brake: Int8 = 0

	public func transmit(cmd: PFCommand) {
		let pfChar = BTCharacteristicIdentity(
				component: FacilityPropComponent.motion,
				category: FacilityPropCategory.power)
		device.send(data: cmd.pack(), to: pfChar)
	}
	
	public var pfConnectionState: ConnectionState {
		device.connectionState
	}
}

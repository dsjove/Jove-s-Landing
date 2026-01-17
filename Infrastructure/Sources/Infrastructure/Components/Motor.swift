//
//  Motor.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/27/25.
//

import Foundation
import BLEByJove

public protocol MotorProtocol {
	associatedtype Power: ControlledProperty where Power.P == Double
	associatedtype Calibration: ControlledProperty where Calibration.P == Double

	var power: Power { get set }
	var calibration: Calibration { get set }
	var increment: Double? { get}
}

public extension MotorProtocol {
	var increment: Double? { nil }

	func reset() {
		self.power.reset()
		self.calibration.reset()
	}

	func fullStop() {
		self.power.control = 0
	}
}

public struct PFMotor: MotorProtocol {
	public typealias Power = TransformedProperty<ScaledTransformer<UInt8>>
	public typealias Calibration = TransformedProperty<ScaledTransformer<UInt8>>
	
	public var power: Power
	public var calibration: Calibration

	public init(device: PFDevice) {
		let calibration = Calibration(
			sendControl: { value in
				return value;
			},
			transfomer: ScaledTransformer(255))
		calibration.control = 0.25
		let power = Power(
			sendControl: { value in
				return value
			},
			transfomer: ScaledTransformer((255)))
		self.power = power

		self.calibration = calibration
	}
}

public struct CCMotor: MotorProtocol {
	public typealias Power = TransformedProperty<ScaledTransformer<Int16>>
	public typealias Calibration = TransformedProperty<ScaledTransformer<Int16>>
	
	public var power: Power
	public var calibration: Calibration

	public init(cube: CircuitCube) {
		class Inner {
			let cube: CircuitCube
			weak var power: Power? = nil
			weak var calib: Calibration? = nil

			init(_ cube: CircuitCube) {
				self.cube = cube
			}

			func apply() -> Int16 {
				var signal = power?.controlMomento ?? 0
				let calib = calib?.controlMomento ?? 255/4
				if abs(signal) < calib {
					signal = 0
					power?.receiveFeedback(newFeedbackMomento: signal)
				}
				Task {
					await cube.power(set: signal, on: .a, dropKey: "motor")
				}
				return signal
			}
		}
		let inner = Inner(cube)

		let calibration = Calibration(
			sendControl: { value in
				let _ = inner.apply()
				return value;
			},
			transfomer: ScaledTransformer(255))
		calibration.control = 0.25

		let power = Power(
			sendControl: { value in
				return inner.apply()
			},
			transfomer: ScaledTransformer((255)))

		inner.power = power
		self.power = power

		inner.calib = calibration
		self.calibration = calibration
	}
}

public struct BTMotor: MotorProtocol {
	public typealias Power = BTProperty<ScaledTransformer<Int8>>
	public typealias Calibration = BTProperty<ScaledTransformer<UInt8>>

	public var power: Power
	public var calibration: Calibration
	public let increment: Double? = 0.01

	public init(device: any BTBroadcaster) {
		self.power = Power(
			broadcaster: device,
			controlChar: BTCharacteristicIdentity(
				component: FacilityPropComponent.motor,
				category: FacilityPropCategory.power,
				channel: BTPropChannel.control),
			feedbackChar: BTCharacteristicIdentity(
				component: FacilityPropComponent.motor,
				category: FacilityPropCategory.power,
				channel: BTPropChannel.feedback),
			transfomer: ScaledTransformer(127))
			
		self.calibration = Calibration(
			broadcaster: device,
			characteristic: BTCharacteristicIdentity(
				component: FacilityPropComponent.motor,
				category: FacilityPropCategory.calibration),
			transfomer: ScaledTransformer(127),
			defaultValue: 0.25)
	}
}

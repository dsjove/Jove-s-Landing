//
//  TheJoveExpress.swift
//  
//
//  Created by David Giovannini on 7/9/21.
//

import Foundation
import Combine
import SwiftUI
import BLEByJove

extension TheJoveExpress: Facility {

	public var category: FacilityCategory { .transportation }
	public var image: Image { Image(systemName: "train.side.front.car") }
	public var name: String { name2.feedback }

	public convenience init() {
		self.init(device: .init(preview: "Sample"))
	}
}

public class TheJoveExpress: ObservableObject {
	public static let Service = BTServiceIdentity(name: "TJEx")
	
	public let id = UUID()
	private let device: BTDevice
	private var sink: Set<AnyCancellable> = []
	public var connectionState: BLEByJove.ConnectionState = .disconnected

	public func fullStop() {}

	public var battery: Double? { 1.0 }

	@Published public private(set) var state: ConnectionState {
		didSet {
			guard oldValue != state else {
				return
			}
			self.stateChange(oldValue)
		}
	}

	public var name2: BTSubject<String>
	public var heart: Heart
	public var engine: Engine
	public var lights: Lights
	public var motion: Motion
	public var camera: Camera
	public var display: Display
	public var sound: Sound
	
	private var beatCheck: Timer?
	private var beatTime: Date?

	public init(device: BTDevice) {
		self.device = device
		self.state = .disconnected
		
		self.name2 = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.system, FacilityPropCategory.calibration),
			device,
			device.name)

		self.heart = Heart(broadcaster: device)
		self.engine = Engine(broadcaster: device)
		self.lights = Lights(broadcaster: device)
		self.motion = Motion(broadcaster: device)
		self.camera = Camera(broadcaster: device)
		self.display = Display(broadcaster: device)
		self.sound = Sound(broadcaster: device)

		device.$connectionState.sink { [weak self] in
			self?.state = $0
		}.store(in: &sink)
		
		self.heart.beat.$feedback.sink { [weak self] _ in
			self?.beatTime = Date()
		}.store(in: &sink)
	}

	deinit {
		self.beatCheck?.invalidate()
	}

	public func connect() {
		self.state = .connecting
		device.connect()
	}

	public func disconnect() {
		device.disconnect()
		self.reset()
	}
	
	public func reset() {
		name2.reset()
		heart.reset()
		engine.reset()
		lights.reset()
		motion.reset()
		camera.reset()
		display.reset()
		sound.reset()
	}
	
	private func stateChange(_ oldValue: ConnectionState) {
		switch state {
		case .disconnected:
			self.reset()
			self.beatCheck?.invalidate()
			self.beatCheck = nil
			self.beatTime = nil
		case .connecting:
			break
		case .connected:
			self.beatTime = Date()
			self.beatCheck?.invalidate()
			self.beatCheck = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { /*[weak self]*/ _ in
				//if let self = self {
					//if self.beatTime!.timeIntervalSinceNow < -5.0 {
						//self.state = .dead
					//}
				//}
			}
		}
	}
}

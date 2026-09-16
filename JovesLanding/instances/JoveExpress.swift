//
//  JoveExpress.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/22/25.
//

import Foundation
import Observation
import SBJFoundation
import BLEByJove
import SBJLego

@MainActor
@Observable
public final class JoveExpress: @MainActor MotorizedFacility {
    public static let Service = BTServiceIdentity(name: "Jove Express")

    public var id: UUID { device.id }

    private let device: BTDevice
    private var observations: [ObserveToken] = []

    public let motor: BTMotor
    public let lighting: BTLighting?

    public convenience init() {
        self.init(device: .init(preview: "Sample"))
    }

    public init(device: BTDevice) {
        self.device = device
        self.connectionState = device.connectionState
        self.motor = BTMotor(device: device)
        self.lighting = BTLighting(device: device)

        observations.append(
            observeValue(
                of: device,
                \.connectionState,
                with: self,
                initialPush: false
            ) { _, state, this in
                this?.connectionState = state
            }
        )
    }

    public var category: FacilityCategory { .transportation }
    public var image: ImageReference { .system("train.side.front.car") }
    public var name: String { Self.Service.name }

    public func connect() {
        device.connect()
    }

    public func disconnect() {
        device.disconnect()
    }

    public private(set) var connectionState: ConnectionState {
        didSet {
            if connectionState == .disconnected {
                reset()
            }
        }
    }

    public func reset() {
        motor.reset()
        lighting?.reset()
    }

    public func fullStop() {
        motor.fullStop()
        lighting?.fullStop()
    }
}

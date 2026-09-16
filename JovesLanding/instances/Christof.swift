//
//  Christof.swift
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
public final class Christof: @MainActor Facility, @MainActor PFTransmitter {
    public static let Service = BTServiceIdentity(name: "Christof")

    public var id: UUID { device.id }

    private let device: BTDevice
    private var observations: [ObserveToken] = []

    public let streetLights: BTLighting
    public let fpTransmitter: PFBTRransmitter

    public private(set) var connectionState: ConnectionState {
        didSet {
            if connectionState == .disconnected {
                reset()
            }
        }
    }

    public var pfConnectionState: ConnectionState {
        connectionState
    }

    public convenience init() {
        self.init(device: .init(preview: "Sample"))
    }

    public init(device: BTDevice) {
        self.device = device
        self.connectionState = device.connectionState
        self.streetLights = BTLighting(device: device)
        self.fpTransmitter = PFBTRransmitter(
            device: device,
            component: FacilityPropComponent.motion,
            category: FacilityPropCategory.power
        )

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
    public var image: ImageReference { .system("building") }
    public var name: String { Self.Service.name }

    public func connect() {
        device.connect()
    }

    public func disconnect() {
        device.disconnect()
    }

    public func transmit(cmd: PFCommand) {
        fpTransmitter.transmit(cmd: cmd)
    }

    public func reset() {
        streetLights.reset()
    }

    public func fullStop() {
        streetLights.fullStop()
    }
}

//
//  TrainDetection.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/22/25.
//

import Foundation
import Observation
import SBJFoundation
import BLEByJove
import SBJLego

public struct TrainDetection {
    let rfid: SampledRFIDDetection
    let registration: PFFacilityRegistration
}

enum DockDetection: UInt8, BTSerializable {
    case none
    case detectPassive
    case dectactCharable

    init() {
        self = .none
    }
}

@MainActor
@Observable
public final class TrainStation: @MainActor Facility, @MainActor RFIDProducing {
    public static let Service = BTServiceIdentity(name: "Train Station")

    public var id: UUID { device.id }

    private let device: BTDevice
    private var observations: [ObserveToken] = []

    public let logoDisplay: ArduinoDisplay
    public let rail: RFIDProducer

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

    public private(set) var currentTrain: TrainDetection?

    public convenience init() {
        self.init(device: .init(preview: "Sample"))
    }

    public init(device: BTDevice) {
        self.device = device
        self.connectionState = device.connectionState
        self.logoDisplay = ArduinoDisplay(device: device)
        self.rail = RFIDProducer(
            device: device,
            component: FacilityPropComponent.system,
            category: FacilityPropCategory.address,
            subCategory: EmptySubCategory(0)
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

        observations.append(
            observeValue(of: rail, \.currentRFID, with: self) { _, value, this in
                this?.updateCurrentRail(value)
            }
        )
    }

    public var category: FacilityCategory { .transportation }
    public var image: ImageReference { .system("tram.fill.tunnel") }
    public var name: String { Self.Service.name }

    public func connect() {
        device.connect()
    }

    public func disconnect() {
        device.disconnect()
    }

    public var currentRFID: SampledRFIDDetection? {
        rail.currentRFID
    }

    public func resetRFID() {
        rail.resetRFID()
        updateCurrentRail(nil)
    }

    private func updateCurrentRail(_ detection: SampledRFIDDetection?) {
        if let detection, !detection.rfid.id.isZero {
            let registration =
                Christof.registrations[detection.rfid.id]
                ?? Christof.registrations[Data()]!

            let train = TrainDetection(rfid: detection, registration: registration)
            currentTrain = train

            SoundPlayer.shared.play(
                train.rfid.anotherRound
                ? train.registration.sound
                : .system(1306)
            )
        } else {
            currentTrain = nil
            logoDisplay.power.control = .init()
        }
    }

    public func reset() {
        logoDisplay.reset()
        rail.resetRFID()
        currentTrain = nil
    }

    public func fullStop() {
        logoDisplay.fullStop()
        currentTrain = nil
    }
}

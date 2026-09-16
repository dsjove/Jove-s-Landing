//
//  JoveMetroLine.swift
//  Infrastructure
//
//  Created by David Giovannini on 12/4/22.
//

import Foundation
import Observation
import SBJFoundation
import BLEByJove
import SBJLego

@MainActor
@Observable
public final class JoveMetroLine: @MainActor MotorizedFacility {
    public static let Service = CircuitCube.Service

    public let id: UUID

    private let cube: CircuitCube
    private var observations: [ObserveToken] = []
    private var heartbeatTask: Task<Void, Never>?

    public let heartBeatSpec: (delay: Int, interval: Int) = (1000, 30)

    public convenience init() {
        self.init(device: .init(preview: "Sample"))
    }

    public init(device: BTDevice) {
        id = device.id
        cube = CircuitCube(device: device)
        connectionState = device.connectionState
        name = device.name
        battery = -1
        motor = CCMotor(cube: cube)
        lighting = CCLighting(cube: cube)

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
            observeValue(
                of: device,
                \.name,
                with: self,
                initialPush: false
            ) { _, name, this in
                this?.name = name
            }
        )
    }

    isolated deinit {
        heartbeatTask?.cancel()
    }

    public var category: FacilityCategory { .transportation }
    public var image: ImageReference { .system("lightrail") }

    public private(set) var name: String

    public var canSetName: Bool { true }

    public func change(name: String) {
        guard name != self.name else { return }
        Task {
            await cube.name(set: name)
        }
    }

    public private(set) var connectionState: ConnectionState {
        didSet {
            switch connectionState {
            case .connected:
                Task {
                    await cube.name()
                }
                startHeartBeat()
            case .connecting:
                break
            case .disconnected:
                reset()
            }
        }
    }

    public private(set) var battery: Double?

    public let motor: CCMotor
    public let lighting: CCLighting?

    public func connect() {
        Task {
            cube.connect()
        }
    }

    public func disconnect() {
        Task {
            cube.disconnect()
        }
    }

    private func updateBattery() async {
        battery = await cube.battery()
    }

    private func reset() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        motor.reset()
        lighting?.reset()
        heartBeat = -1
        battery = -1
    }

    public private(set) var heartBeat: Int = -1 {
        didSet {
            if heartBeat > -1 {
                Task {
                    await updateBattery()
                }
            }
        }
    }

    private func startHeartBeat() {
        heartbeatTask?.cancel()

        let (delayMilliseconds, intervalSeconds) = heartBeatSpec
        guard delayMilliseconds > 0 else { return }

        heartbeatTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(delayMilliseconds))
            guard !Task.isCancelled else { return }

            if intervalSeconds <= 0 {
                self?.heartBeat = 0
                return
            }

            while !Task.isCancelled {
                self?.heartBeat += 1
                try? await Task.sleep(for: .seconds(intervalSeconds))
            }
        }
    }
}

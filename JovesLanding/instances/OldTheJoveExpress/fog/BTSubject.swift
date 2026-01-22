//
//  BTSubject.swift
//  BLEByJove
//
//  Created by David Giovannini on 7/5/21.
//

import Foundation
import Combine
import BLEByJove
/**
BTSubject wraps a FogFeedbackValue and broadcasts via combine and bluetooth
*/
public final class BTSubject<T: FogExternalizable>: Identifiable, ObservableObject {
	public let id = CombineIdentifier()
	private let controlChar: BTCharacteristicIdentity
	private let feedbackChar: BTCharacteristicIdentity
	private weak var broadcaster: BTBroadcaster?
	private var sink: AnyCancellable?
	private var value: FogFeedbackValue<T>

	@Published
	public var control: T {
		didSet {
			self.value.control(control) { value in
				broadcaster?.send(data: value.write(), to: controlChar)
			}
		}
	}
	
	@Published
	public var feedback: T
	
	public convenience init(_ characteristic: BTCharacteristicIdentity, _ broadcaster: BTBroadcaster, _ defaultValue: T) {
		self.init(characteristic, characteristic, broadcaster, defaultValue)
	}
	
	public init(_ controlChar: BTCharacteristicIdentity, _ feedbackChar: BTCharacteristicIdentity, _ broadcaster: BTBroadcaster, _ defaultValue: T) {
		self.controlChar = controlChar
		self.feedbackChar = feedbackChar
		self.value = FogFeedbackValue(defaultValue)
		if let data = broadcaster.read(value: feedbackChar), !data.isEmpty {
			self.value.feedback(try? T(fog: data, old: nil), {_, _ in})
		}
		self.control = self.value.controlled
		self.feedback = self.value.controlled

		self.broadcaster = broadcaster
		self.sink = broadcaster.sink(id: id, to: feedbackChar, with: self.receiveFeedback)
	}
	
	public func reset() {
		value.reset()
		self.control = self.value.controlled
		self.feedback = self.value.controlled
		self.broadcaster?.request(value: feedbackChar)
	}

	private func read(data: Data) -> T? {
		try? T(fog: data, old: self.control)
	}

	private func receiveFeedback(data: Data) {
		self.value.feedback(read(data: data)) { value, asserted in
			self.feedback = value
			if asserted {
				DispatchQueue.main.async {
					let b = self.broadcaster
					self.broadcaster = nil
					self.control = value
					self.broadcaster = b
				}
			}
		}
	}
}

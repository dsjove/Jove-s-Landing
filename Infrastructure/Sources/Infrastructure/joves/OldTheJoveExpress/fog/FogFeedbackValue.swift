//
//  FogFeedbackValue.swift
//  BLEByJove
//
//  Created by David Giovannini on 8/29/17.
//  Copyright © 2017 Software by Jove. All rights reserved.
//

import Foundation

public protocol FeedbackComparing {
	init()
	func feedBackCompare(_ rhs: Self) -> Bool
}

public extension FeedbackComparing where Self: Equatable {
	func feedBackCompare(_ rhs: Self) -> Bool {
		return self == rhs
	}
}

/**
FogFeedbackValue contains three values of T
* default - used on init and reset
* control - initial value and calls lambda on change
* detected - used to store the value received from feedback and calls lambda on change
* 	On feedback, if asserting is true or first detection, then set controlled
*/
public struct FogFeedbackValue<T: FeedbackComparing> {
	private let defaultValue: T
	public private(set) var controlled: T
	public private(set) var detected: T?
	public var value: T { return detected ?? controlled }
	
	public init(_ defaultValue: T) {
		self.defaultValue = defaultValue
		self.controlled = defaultValue
	}
	
	// Have we received any feedback?
	public var hasFeedback: Bool {
		return detected != nil
	}
	
	// Removes feedback value and resets controlled to default
	public mutating func reset() {
		self.controlled = defaultValue
		self.detected = nil
	}
	
	// True when both controlled and received match
	public var isSyncronize: Bool {
		detected != nil && (controlled.feedBackCompare(detected!))
	}
	
	// If control changed then invoke lambda
	@discardableResult
	public mutating func control(_ value: T, _ change: (T) ->()) -> Bool {
		if !(value.feedBackCompare(controlled)) {
			controlled = value
			change(value)
			return true
		}
		return false
	}
	
	public enum ReceiveApplied {
		case no
		case failed
		case asserted
		case yes
	
		var changed: Bool { return self == .asserted || self == .yes }
	}
	
	// If detected changed then invoke lambda
	@discardableResult
	public mutating func feedback(_ value: T?, _ change: (T, Bool) ->()) -> ReceiveApplied {
		guard let value = value else { return .failed }
		let wasNil = detected == nil
		if wasNil || !(value.feedBackCompare(detected!)) {
			detected = value
			change(value, wasNil)
			return wasNil ? .asserted : .yes
		}
		return .no
	}
}

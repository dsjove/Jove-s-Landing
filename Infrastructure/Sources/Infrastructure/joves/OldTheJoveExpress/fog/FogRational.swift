//
//  FogRational.swift
//  BLEByJove
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Software by Jove. All rights reserved.
//

import Foundation

public protocol FogRationalizing: Equatable, FogExternalizable, CustomStringConvertible {
	associatedtype T where T: FixedWidthInteger
	var num: T { get set }
	var den: T { get set }
	init()
}

public extension FogRationalizing {
	init(num: T = 0, den: T = 1) {
		self.init()
		self.num = num
		self.den = den
	}

	init(ratio: Double) {
		self.init()
		self.num = T(ratio * Double(T.max))
		self.den = T.max
	}

	init(fog data: Data, at cursor: inout Int, old: Self?) throws {
		self.init()
		self.num = try T(fog: data, at: &cursor, old: nil)
		self.den = try T(fog: data, at: &cursor, old: nil)
	}

	var ratio: Double {
		Double(num) / Double(den)
	}

	var description: String {
		"\(num)/\(den)"
	}

	static var fogSize: Int {
		T.fogSize + T.fogSize
	}

	var fogSize: Int {
		Self.fogSize
	}

	func write(fog data: inout Data) {
		self.num.write(fog: &data)
		self.den.write(fog: &data)
	}

	static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.num == rhs.num && lhs.den == rhs.den
	}

	static func !=(lhs: Self, rhs: Self) -> Bool {
		lhs.num != rhs.num || lhs.den != rhs.den
	}
}

public struct FogRational<T: FixedWidthInteger> : FogRationalizing {
	public typealias ValueType = T
	public var num: T = 0
	public var den: T = 1
	public init() {}
}

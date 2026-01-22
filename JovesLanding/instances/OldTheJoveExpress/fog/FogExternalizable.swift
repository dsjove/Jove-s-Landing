//
//  FogExternalizable.swift
//  BLEByJove
//
//  Created by David Giovannini on 8/9/17.
//  Copyright © 2017 Software by Jove. All rights reserved.
//

import Foundation

public struct FogError: Error {
	public init() {}
}

public protocol FogWritingExternalizable {
	func write(fog data: inout Data)
	var fogSize: Int { get }
}

public extension FogWritingExternalizable {
	func write() -> Data {
		var data = Data(capacity: self.fogSize)
		self.write(fog: &data)
		return data
	}
}

public protocol FogReadingExternalizable {
	init(fog data: Data, at cursor: inout Int, old: Self?) throws
}

public extension FogReadingExternalizable {
	init(fog data: Data, old: Self?) throws {
		var cursor = 0
		try self.init(fog: data, at: &cursor, old: old)
	}

	init(fog data: Data, at cursor: inout Int) throws {
		try self.init(fog: data, at: &cursor, old: nil)
	}

	init(fog data: Data) throws {
		var cursor = 0
		try self.init(fog: data, at: &cursor, old: nil)
	}
}

public protocol FogExternalizable: FeedbackComparing, FogReadingExternalizable, FogWritingExternalizable {
}

public extension FixedWidthInteger {
	var fogSize: Int {
		Self.fogSize
	}
	
	static var fogSize: Int {
		MemoryLayout<Self>.size
	}
	
	init(fog data: Data, at cursor: inout Int, old: Self?) throws {
		self = Self(bigEndian: data.fogExtract(&cursor))
	}
	
	func write(fog data: inout Data) {
		data.fogAppend(value: self.bigEndian)
	}
}

extension UInt8: FogExternalizable {}
extension Int8: FogExternalizable {}

extension UInt16: FogExternalizable {}
extension Int16: FogExternalizable {}

extension Bool: FogExternalizable {
	public var fogSize: Int {
		Self.fogSize
	}
	
	public static var fogSize: Int {
		UInt8.fogSize
	}
	
	public init(fog data: Data, at cursor: inout Int, old: Self?) throws {
		self = try UInt8(fog: data, at: &cursor) == 0 ? false : true
	}
	
	public func write(fog data: inout Data) {
		UInt8(self ? 1 : 0).write(fog: &data)
	}
}

extension String: FogExternalizable {
	public var fogSize: Int {
		return UInt8.fogSize + self.count
	}
	
	public init(fog data: Data, at cursor: inout Int, old: Self?) throws {
		let len = try UInt8(fog: data, at: &cursor)
		let subData = data.subdata(in: cursor..<(cursor+Int(len)))
		cursor += Int(len)
		if let str = String(data: subData, encoding: .utf8) {
			self = str
			return
		}
		throw FogError()
	}
	
	public func write(fog data: inout Data) {
		let view = self.utf8
		UInt8(view.count).write(fog: &data)
		data.append(contentsOf: view)
	}
}

public extension FogReadingExternalizable where Self: RawRepresentable, Self.RawValue: FogReadingExternalizable {
	init(fog data: Data, at cursor: inout Int, old: Self?) throws {
		let rawValue = try Self.RawValue(fog: data, at: &cursor)
		if let found = Self(rawValue: rawValue) {
			self = found
			return
		}
		throw FogError()
	}
}

public extension FogWritingExternalizable where Self: RawRepresentable, Self.RawValue: FogWritingExternalizable {
	var fogSize: Int {
		rawValue.fogSize
	}
	
	func write(fog data: inout Data) {
		rawValue.write(fog: &data)
	}
}

//
//  Data+Fog.swift
//  BLEByJove
//
//  Created by David Giovannini on 7/29/17.
//  Copyright © 2017 Software by Jove. All rights reserved.
//

import Foundation

public extension Data {
	mutating func fogAppend<T>(value: T) {
		withUnsafePointer(to: value) { (ptr: UnsafePointer<T>) in
			self.append(UnsafeBufferPointer(start: ptr, count: 1))
		}
	}

	func fogExtract<T>(_ cursor: inout Int) -> T {
//		return self.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
//			let pos = u8Ptr.advanced(by: cursor)
//			return pos.withMemoryRebound(to: T.self, capacity: 1) { (c) -> T in
//				cursor += MemoryLayout<T>.size
//				return c.pointee
//			}
//		}
		abort()
	}
}


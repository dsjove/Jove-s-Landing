//
//  FogIPAddress.swift
//  BLEByJove
//
//  Created by David Giovannini on 8/14/21.
//

import Foundation

public struct FogIPAddress: FogExternalizable, Equatable {
	let a: UInt8
	let b: UInt8
	let c: UInt8
	let d: UInt8
	let p: UInt16
	let r: String
	
	public var fogSize: Int {
		6 + r.fogSize
	}
	
	public init() {
		a = 0
		b = 0
		c = 0
		d = 0
		p = 0
		r = ""
	}
	
	public init(fog data: Data, at cursor: inout Int, old: Self?) throws {
		a = try UInt8(fog: data, at: &cursor)
		b = try UInt8(fog: data, at: &cursor)
		c = try UInt8(fog: data, at: &cursor)
		d = try UInt8(fog: data, at: &cursor)
		p = try UInt16(fog: data, at: &cursor)
		r = try String(fog: data, at: &cursor)
	}
	
	public func write(fog data: inout Data) {
		a.write(fog: &data)
		b.write(fog: &data)
		c.write(fog: &data)
		d.write(fog: &data)
		p.write(fog: &data)
		r.write(fog: &data)
	}
	
	public var url: URL? {
		guard a != 0 || b != 0 || c != 0 || d != 0 else {
			return nil
		}
		return URL(string:"http://\(a).\(b).\(c).\(d):\(p)\(r.isEmpty ? "" : "/")\(r)")
	}
}

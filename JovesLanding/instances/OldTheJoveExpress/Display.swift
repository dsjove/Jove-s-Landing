//
//  Display.swift
//  
//
//  Created by David Giovannini on 7/29/21.
//

import Foundation
import BLEByJove

public enum DisplayFont: UInt8, FogExternalizable {
	public init() {
		self = .serif
	}
	case serif
	case sanSerif
	case script
}

public struct DisplayText: FogExternalizable, Equatable {
	public let font: DisplayFont
	public let text: String
	public var fogSize: Int { font.fogSize + text.fogSize }
	
	public init() {
		self.font = .serif
		self.text = ""
	}
	
	public init(fog data: Data, at cursor: inout Int, old: Self?) throws {
		self.font = try DisplayFont(fog: data, at: &cursor)
		self.text = try String(fog: data, at: &cursor)
	}
	
	public func write(fog data: inout Data) {
		font.write(fog: &data)
		text.write(fog: &data)
	}
}

public enum DisplayCommand: Equatable, FogExternalizable {
	public init() {
		self = .clear
	}
	case clear
	case text(DisplayText)
	case image(String)
	
	public init(fog data: Data, at cursor: inout Int, old: Self?) throws {
		let id = try UInt8(fog: data, at: &cursor)
		switch id {
			case 0:
				self = .clear
			case 1:
				self = try .text(DisplayText(fog: data, at: &cursor))
			case 2:
				self = try .image(String(fog: data, at: &cursor))
			default:
				break
		}
		throw FogError()
	}
	
	public func write(fog data: inout Data) {
		self.id.write(fog: &data)
		switch self {
		case .clear:
			break
		case .text(let text):
			text.write(fog: &data)
		case .image(let name):
			name.write(fog: &data)
		}
	}
	
	public var id: UInt8 {
		switch self {
		case .clear:
			return 0
		case .text:
			return 1
		case .image:
			return 2
		}
	}
	
	public var fogSize: Int {
		switch self {
		case .clear:
			return 1
		case .text(let text):
			return  1 + text.fogSize
		case .image(let name):
			return  1 + name.fogSize
		}
	}
}

//FUTURE:
public struct Display {
	public var cmd: BTSubject<DisplayCommand>
	
	public init(broadcaster: BTBroadcaster) {
		self.cmd = BTSubject(
			BTCharacteristicIdentity(FacilityPropComponent.display, FacilityPropCategory.power),
			broadcaster,
			.clear)
	}
	
	public func reset() {
		cmd.reset()
	}
}

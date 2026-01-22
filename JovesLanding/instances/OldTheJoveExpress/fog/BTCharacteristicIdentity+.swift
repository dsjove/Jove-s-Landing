//
//  Untitled.swift
//  Infrastructure
//
//  Created by David Giovannini on 3/26/25.
//

import Foundation
import Combine
import BLEByJove

public extension BTCharacteristicIdentity {
	init(
			_ component: BTComponent,
			_ category: BTCategory) {
		self.init(
			component: component,
			category: category,
			subCategory: EmptySubCategory(),
			channel: BTPropChannel.property)
	}
}

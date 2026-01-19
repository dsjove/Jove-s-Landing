//
//  JoveMetroLineView.swift
//  JovesLanding
//
//  Created by David Giovannini on 12/5/22.
//

import SwiftUI
import Infrastructure
import BLEByJove

typealias JoveMetroLineView = MotorizedFacilityView<JoveMetroLine>

#Preview {
	JoveMetroLineView(facility: JoveMetroLine())
}

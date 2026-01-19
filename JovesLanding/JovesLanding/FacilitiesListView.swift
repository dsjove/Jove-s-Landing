//
//  FacilitiesListView.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/9/21.
//

import SwiftUI
import BLEByJove
import Infrastructure

struct FacilitiesListView: View {
	var facilities: FacilityRepository

	@State private var device: FacilityEntry?
	@State private var visibility: NavigationSplitViewVisibility = .all
	
	var body: some View {
		NavigationSplitView(columnVisibility: $visibility) {
			Group {
				if facilities.facilities.isEmpty {
					Text("No facilities found.")
				} else {
					List(facilities.facilities, selection: $device) { entry in
						NavigationLink(value: entry) {
							FacilityLineView(facility: entry.value)
						}
					}
				}
			}
		}
		detail: {
			FacilityDetailView(facility: device?.value)
				.toolbarBackground(Color.green.opacity(1.0), for: .navigationBar)
#if !os(tvOS)
				.navigationBarTitleDisplayMode(.inline)
#endif
		}
		.onChange(of: device) { _, newValue in
			newValue?.value.connect()
			visibility = newValue != nil ? .detailOnly : .all
		}
		.onLoad {
				facilities.setScanning(true)
		}
	}
}

#Preview {
	FacilitiesListView(facilities: .init())
}

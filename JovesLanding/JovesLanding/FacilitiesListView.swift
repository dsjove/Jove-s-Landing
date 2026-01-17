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
	@ObservedObject var facilities: FacilitiesFactory
	let scanning: (Bool)->()

	@State private var device: FacilityEntry?
	@State private var visibility: NavigationSplitViewVisibility = .all
	
	var body: some View {
		NavigationSplitView(columnVisibility: $visibility) {
			Group {
				if facilities.entries.isEmpty {
					Text("No facilities found.")
				} else {
					List(facilities.entries, selection: $device) { entry in
						NavigationLink(value: entry) {
							FacilityLineView(facility: entry.value)
						}
					}
				}
			}
		}
		detail: {
			FacilityDetailView(impl: device?.value)
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
			scanning(true)
		}
	}
}

#Preview {
	FacilitiesListView(facilities: .init() { _ in }, scanning: { _ in })
}

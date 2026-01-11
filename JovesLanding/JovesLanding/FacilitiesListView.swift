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
	@ObservedObject var bluetooth: BTClient
	@ObservedObject var mDNS: MDNSClient
	let facilities: FacilitiesFactory
	
	@State private var device: FacilityEntry?
	@State private var visibility: NavigationSplitViewVisibility = .all
	
	var body: some View {
		NavigationSplitView(columnVisibility: $visibility) {
			Group {
				if bluetooth.devices.isEmpty && mDNS.devices.isEmpty {
					Text("No facilities found.")
				}
				else {
					VStack {
						List(mDNS.devices, selection: $device) { device in
							let facilities = facilities.implementation(for: device)
							ForEach(facilities) { entry in
								NavigationLink(value: entry) {
									FacilityLineView(facility: entry.facility)
								}
							}
						}
						List(bluetooth.devices, selection: $device) { device in
							let facilities = facilities.implementation(for: device)
							ForEach(facilities) { entry in
								NavigationLink(value: entry) {
									FacilityLineView(facility: entry.facility)
								}
							}
						}
						Spacer()
					}
				}
			}
		}
		detail: {
			FacilityDetailView(impl: device?.facility)
				.toolbarBackground(Color.green.opacity(1.0), for: .navigationBar)
#if !os(tvOS)
				.navigationBarTitleDisplayMode(.inline)
#endif
		}
		.onChange(of: device) { [device] _, newValue in
			if device?.id != newValue?.id {
				newValue?.facility.connect()
			}
			visibility = newValue != nil ? .detailOnly : .all
		}
		.onLoad {
			bluetooth.scanning = true
			mDNS.scanning = true
		}
	}
}

#Preview {
	FacilitiesListView(bluetooth: .init(), mDNS: .init(), facilities: .init())
}

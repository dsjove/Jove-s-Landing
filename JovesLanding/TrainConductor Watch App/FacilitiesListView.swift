//
//  FacilitiesListView.swift
//  TrainConductor Watch App
//
//  Created by David Giovannini on 12/15/22.
//

import SwiftUI
import BLEByJove
import SBJLego

struct FacilitiesListView: View {
	var facilities: FacilityRepository

	var body: some View {
		NavigationStack {
			Group {
				if facilities.facilities.isEmpty {
					Text("No facilities found.")
				}
				else {
					List(facilities.facilities) { entry in
						NavigationLink(value: entry) {
							FacilityLineView(facility: entry.value)
						}
					}
				}
			}
			.onAppear() {
				facilities.setScanning(true)
			}
			.onDisappear() {
				facilities.setScanning(false)
			}
			.navigationDestination(for: FacilityEntry.self) { device in
				FacilityDetailView(facility: device.value)
					.navigationTitle(device.value.name)
					.onAppear() {
						device.value.connect()
					}
					.onDisappear() {
						device.value.disconnect()
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
					.ignoresSafeArea(edges: Edge.Set.all.subtracting(.top))
					.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
			}
		}
	}
}

#Preview {
	FacilitiesListView(facilities: .init())
}

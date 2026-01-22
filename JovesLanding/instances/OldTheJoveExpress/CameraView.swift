//
//  CameraView.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/27/21.
//

import SwiftUI
import BLEByJove
import Infrastructure

struct CameraView: View {
	@ObservedObject var fps: BTSubject<CameraFPS>
	@ObservedObject var power: BTSubject<Bool>
	@ObservedObject var url: BTSubject<FogIPAddress>
	@State private var isPresenting = false
	
	private let connected: Bool

	init(_ camera: Camera, connected: Bool) {
		self.connected = connected
		self.url = camera.url
		self.fps = camera.fps
		self.power = camera.power
	}
	/*
	var content: WebContent {
		let content: WebContent
		if let url = self.url.feedback.url, connected {
			content = .request(URLRequest(url: url))
		}
		else {
			content = .html("Not Connected")
		}
		return content
	}
	*/
	var body: some View {
		VStack {
		/*	let content = self.content
			ContentWebView(content: content)
				.aspectRatio(1.3333, contentMode: .fit)
				.border(Color.gray, width: 0.5)
				.onTapGesture {
					isPresenting.toggle()
				}
				.fullScreenCover(isPresented: $isPresenting, onDismiss: didDismiss) {
					ZStack {
						Image("Metal")
							.resizable()
							.ignoresSafeArea()
						ContentWebView(content: content)
						.onTapGesture {
							isPresenting.toggle()
						}
					}
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.ignoresSafeArea(edges: .all)
				}
				*/
			HStack {
				Toggle(isOn: $power.control, label: EmptyView.init)
					.toggleStyle(CheckboxStyle())
				Picker("", selection: $fps.control) {
					ForEach(CameraFPS.allCases, id: \.self) {
						Text($0.rawValue.description)
					}
				}
				//.pickerStyle(SegmentedPickerStyle())
			}
		}
	}

	func didDismiss() {
	}
}

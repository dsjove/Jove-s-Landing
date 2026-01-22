//
//  TheJoveExpressView.swift
//  JovesLanding
//
//  Created by David Giovannini on 7/9/21.
//

import SwiftUI
import BLEByJove
import Infrastructure

struct TheJoveExpressView: View {
	@ObservedObject var train: TheJoveExpress
	
	var body: some View {
		ZStack {
			Image("Metal")
				.resizable()
				.ignoresSafeArea()
			VStack {
				HStack(alignment: .top, spacing: 8) {
					EngineView(train.engine)
					LightsView(train.lights)
				}.fixedSize(horizontal: false, vertical: true)
				HStack(alignment: .top, spacing: 8) {
					MotionView()
					CameraView(train.camera, connected: train.state == .connected)
				}.fixedSize(horizontal: false, vertical: true)
				HStack(alignment: .top, spacing: 8) {
					Button("Display") {
					}
					Button("Sound") {
					}
				}.fixedSize(horizontal: false, vertical: true)
				Spacer()
			}
			.trainToolbar(train: train)
			.padding(12)
		}
	}
}

struct TrainToolbar: ViewModifier {
	@ObservedObject var train: TheJoveExpress
	@ObservedObject var name: BTSubject<String>
	@State private var editTitle = false

	init(train: TheJoveExpress) {
		self.train = train
		self.name = train.name2
	}

	func body(content: Content) -> some View {
		content.toolbar {
			ToolbarItem(placement: .principal) {
				VStack {
					Text(name.feedback).font(.title)
					HealthView(health: train.heart.health).font(.subheadline)
				}
				.onTapGesture {
					self.editTitle.toggle()
				}
			}
			/*
			ToolbarItem(placement: .navigationBarTrailing) {
				ConnectionView(train: train)
			}
			*/
		}
		/*
		.alert(isPresented: self.$editTitle, TextFieldAlert(
			   title: "Name", placeholder: name.feedback, action: { result in
			   if let result = result, result.isEmpty == false {
				   name.control = result
			   }
		   }))
		   */
	}
}

extension View {
	func trainToolbar(train: TheJoveExpress) -> some View {
		modifier(TrainToolbar(train: train))
	}
}

#Preview {
	TheJoveExpressView(train: TheJoveExpress())
}

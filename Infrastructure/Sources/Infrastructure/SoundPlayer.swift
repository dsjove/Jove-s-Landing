import AVFoundation
import UIKit

final class SoundPlayer: NSObject, AVAudioPlayerDelegate {
	@MainActor static let shared = SoundPlayer()

	private var activePlayers: [AVAudioPlayer] = []

	func play(assetName: String, fileType: AVFileType = .mp3) {
		guard !assetName.isEmpty else {
			return
		}
		guard let asset = NSDataAsset(name: assetName) else {
			return
		}

		do {
			let player = try AVAudioPlayer(
				data: asset.data,
				fileTypeHint: fileType.rawValue
			)
			activePlayers.append(player)
			player.delegate = self
			player.prepareToPlay()
			player.play()
		} catch {
		}
	}

	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool ) {
		activePlayers.removeAll { $0 === player }
	}
}

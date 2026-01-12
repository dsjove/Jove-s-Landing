import AVFoundation
import UIKit
import AudioToolbox

final class SoundPlayer: NSObject, AVAudioPlayerDelegate {
	@MainActor static let shared = SoundPlayer()

	private var activePlayers: [AVAudioPlayer] = []

	enum Source {
		case asset(String, AVFileType = .mp3)
		case system(Int?)

		var asset: (Data, AVFileType)? {
			switch self {
			case let .asset(name, type):
				guard !name.isEmpty, let dataAsset = NSDataAsset(name: name) else { return nil }
				return (dataAsset.data, type)
			case .system:
				return nil
			}
		}

		var sysNum: Int? {
			switch self {
			case .asset:
				return nil
			case let .system(number):
				return number
			}
		}
	}

	func play(_ source: Source) {
		if let (data, fileType) = source.asset {
			do {
				let player = try AVAudioPlayer(
					data: data,
					fileTypeHint: fileType.rawValue
				)
				activePlayers.append(player)
				player.delegate = self
				player.prepareToPlay()
				player.play()
			} catch {
			}
		}
		if let id = source.sysNum {
			let soundID = SystemSoundID(id)
			AudioServicesPlaySystemSound(soundID)
		}
	}

	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		activePlayers.removeAll { $0 === player }
	}
}

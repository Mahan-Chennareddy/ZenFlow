// xcode: set sdk=iOS

import Foundation
import AVFoundation
import Combine

class AudioManager: ObservableObject {
    private var players: [String: AVAudioPlayer] = [:]
    private var currentTrack: String?
    
    @Published var volume: Float = 0.8
    
    func playAmbientSound(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Audio file \(name) not found.")
            return
        }
        
        do {
            if let existingPlayer = players[name] {
                if existingPlayer.isPlaying {
                    existingPlayer.currentTime = 0
                    existingPlayer.play()
                } else {
                    existingPlayer.play()
                }
                currentTrack = name
            } else {
                stopCurrentTrack()
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = volume
                player.prepareToPlay()
                player.play()
                players[name] = player
                currentTrack = name
            }
        } catch {
            print("Failed to initialize player for \(name): \(error)")
        }
    }
    
    func stopCurrentTrack() {
        players.values.forEach { $0.stop() }
    }
    
    func setVolume(_ value: Float) {
        volume = max(0, min(1, value))
        players.values.forEach { $0.volume = volume }
    }
}

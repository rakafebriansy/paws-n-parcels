import Foundation
import AVFoundation

enum SFX: String, CaseIterable {
    case item1A = "Item1A"
    case menu1A = "Menu1A"
    case achievement = "achievement"
    case click4 = "click4"
    case click5 = "click5"
    case grass7 = "grass_7"
    case grass6 = "grasss_6"
    case gravel6 = "gravel_6"
    case gravel8 = "gravel_8"
    case itemHandling1 = "qubodupItemHandling1"
    case appearOnline = "appear-online"
    case paper10 = "Paper 10"
    
    var fileExtension: String {
        switch self {
        case .item1A, .menu1A, .achievement, .itemHandling1, .paper10:
            return "wav"
        case .click4, .click5, .grass7, .grass6, .gravel6, .gravel8, .appearOnline:
            return "m4a"
        }
    }
}

class SoundManager: NSObject, AVAudioPlayerDelegate {
    static let shared = SoundManager()
    
    private var activePlayers: [ObjectIdentifier: AVAudioPlayer] = [:]
    private var playerPools: [SFX: [AVAudioPlayer]] = [:]
    private var volume: Float = 1.0
    
    private override init() {
        super.init()
        if UserDefaults.standard.object(forKey: "sfx") != nil {
            volume = Float(UserDefaults.standard.double(forKey: "sfx") / 100.0)
        }
    }
    
    func setVolume(_ volume: Float) {
        self.volume = volume
        for player in activePlayers.values {
            player.volume = volume
        }
    }
    
    func play(_ sfx: SFX) {
        var finalVolume = volume
        if sfx == .grass6 || sfx == .grass7 || sfx == .gravel6 || sfx == .gravel8 {
            finalVolume = volume * 0.3
        }
        
        if let availablePlayer = playerPools[sfx]?.first(where: { !$0.isPlaying }) {
            availablePlayer.volume = finalVolume
            availablePlayer.play()
            activePlayers[ObjectIdentifier(availablePlayer)] = availablePlayer
            return
        }
        
        guard let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: sfx.fileExtension) else {
            debugLog("[SoundManager] File not found for \(sfx.rawValue).\(sfx.fileExtension)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = finalVolume
            player.delegate = self
            player.play()
            activePlayers[ObjectIdentifier(player)] = player
            
            if playerPools[sfx, default: []].count < 5 {
                playerPools[sfx, default: []].append(player)
            }
        } catch {
            debugLog("[SoundManager] Error playing \(sfx.rawValue): \(error.localizedDescription)")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        activePlayers.removeValue(forKey: ObjectIdentifier(player))
    }
}

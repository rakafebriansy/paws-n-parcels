//
//  GameScene+Audio.swift
//  paws-n-parcels
//
//  Audio management (BGM & SFX volume) extracted from GameScene for modularity.
//

import SpriteKit
import AVFoundation

extension GameScene {
    
    func playBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            debugLog("[BGM] Error setting up audio session: \(error)")
        }
        
        guard let url = Bundle.main.url(forResource: "1. Playground", withExtension: "m4a") else {
            debugLog("[BGM] Error: Could not find BGM file in bundle")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            var targetVolume: Float = 1.0
            if UserDefaults.standard.object(forKey: "bgm") != nil {
                targetVolume = Float(UserDefaults.standard.double(forKey: "bgm") / 100.0)
            }
            player.volume = 0.0
            player.prepareToPlay()
            player.play()
            player.setVolume(targetVolume, fadeDuration: 2.0)
            self.bgmPlayer = player
            debugLog("[BGM] Playing BGM with fade-in, target volume: \(targetVolume).")
        } catch {
            debugLog("[BGM] Error initializing AVAudioPlayer: \(error)")
        }
    }
    
    func setBGMVolume(_ volume: Float) {
        bgmPlayer?.volume = volume
        debugLog("[BGM] Volume set to \(volume).")
    }
    
    func setSFXVolume(_ volume: Float) {
        sfxVolume = volume
        SoundManager.shared.setVolume(volume)
        debugLog("[SFX] Volume set to \(volume).")
    }
}

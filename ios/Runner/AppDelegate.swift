import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var feedbackChannel: FlutterMethodChannel?
  private var successPlayer: AVAudioPlayer?
  private var counterTickPlayer: AVAudioPlayer?
  private var beadCollisionPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    prepareFeedbackSounds()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  func configureFeedbackChannel(for controller: FlutterViewController) {
    feedbackChannel = FlutterMethodChannel(
      name: "pro.kt.zikirmatikv2/feedback",
      binaryMessenger: controller.binaryMessenger
    )

    feedbackChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "vibrate":
        self?.vibrate()
        result(nil)
      case "playSuccessSound":
        self?.playSuccessSound()
        result(nil)
      case "playCounterTickSound":
        self?.playCounterTickSound()
        result(nil)
      case "playBeadCollisionSound":
        self?.playBeadCollisionSound()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func prepareFeedbackSounds() {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .default,
        options: [.mixWithOthers]
      )
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      // Feedback is optional; the app should keep working if audio setup fails.
    }

    successPlayer = makePlayer(named: "success_chime", volume: 0.58)
    counterTickPlayer = makePlayer(named: "counter_tick", volume: 0.42)
    beadCollisionPlayer = makePlayer(named: "glass_tesbih_click", volume: 0.48)
  }

  private func makePlayer(named name: String, volume: Float) -> AVAudioPlayer? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
      return nil
    }

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.volume = volume
      player.prepareToPlay()
      return player
    } catch {
      return nil
    }
  }

  private func playSuccessSound() {
    play(successPlayer)
  }

  private func playCounterTickSound() {
    play(counterTickPlayer)
  }

  private func playBeadCollisionSound() {
    play(beadCollisionPlayer)
  }

  private func play(_ player: AVAudioPlayer?) {
    guard let player else {
      return
    }

    player.currentTime = 0
    player.play()
  }

  private func vibrate() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }
}

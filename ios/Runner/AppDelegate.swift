import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var successPlayer: AVAudioPlayer?
  private var beadCollisionPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    prepareFeedbackSounds()
    configureFeedbackChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func configureFeedbackChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    FlutterMethodChannel(
      name: "pro.zikirmatik.app/feedback",
      binaryMessenger: controller.binaryMessenger
    ).setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "vibrate":
        self?.vibrate()
        result(nil)
      case "playSuccessSound":
        self?.playSuccessSound()
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
      try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      // Feedback is optional; the app should keep working if audio setup fails.
    }

    successPlayer = makePlayer(named: "success_chime", volume: 0.58)
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

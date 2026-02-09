import AVFoundation
import Flutter
import Foundation
import MediaPlayer
import UIKit

public class VolumeListener: NSObject, FlutterStreamHandler {
  private let audioSession: AVAudioSession
  private var eventSink: FlutterEventSink?
  private var isObserving: Bool = false
  private let volumeKey: String = "outputVolume"

  init(audioSession: AVAudioSession) {
    self.audioSession = audioSession
    super.init()
    registerInterruptionObserver()
  }

  deinit {
    removeInterruptionObserver()
  }

  public var isObservingVolume: Bool {
    return isObserving
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    let args = arguments as! [String: Any]
    let fetchInitialVolume = args[EventArgument.fetchInitialVolume] as! Bool

    self.eventSink = events
    registerVolumeObserver()

    if fetchInitialVolume {
      events(audioSession.getVolume())
    }

    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    audioSession.deactivateAudioSession()
    eventSink = nil
    removeVolumeObserver()

    return nil
  }

  private func registerVolumeObserver() {
    guard !isObserving else { return }

    audioSession.setAudioSessionCategory()
    audioSession.activateAudioSession()

    audioSession.addObserver(
      self,
      forKeyPath: volumeKey,
      options: .new,
      context: nil)
    isObserving = true
  }

  private func removeVolumeObserver() {
    if isObserving {
      audioSession.removeObserver(self, forKeyPath: volumeKey)
      isObserving = false
    }
  }

  override public func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    guard keyPath == volumeKey else {
      return
    }
    eventSink?(audioSession.getVolume())
  }

  public func sendVolumeChangeEvent() {
    eventSink?(audioSession.getVolume())
  }

  /// Re-activates the audio session and resumes volume observation.
  /// Call this after another component in the app has changed or deactivated the audio session.
  public func reactivateSession() {
    guard isObserving else { return }
    audioSession.activateAudioSession()
    sendVolumeChangeEvent()
  }

  // MARK: - Interruption Handling

  private func registerInterruptionObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption),
      name: AVAudioSession.interruptionNotification,
      object: audioSession)
  }

  private func removeInterruptionObserver() {
    NotificationCenter.default.removeObserver(
      self,
      name: AVAudioSession.interruptionNotification,
      object: audioSession)
  }

  @objc private func handleInterruption(notification: Notification) {
    guard isObserving,
      let userInfo = notification.userInfo,
      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: typeValue)
    else {
      return
    }

    if type == .ended {
      audioSession.activateAudioSession()
      sendVolumeChangeEvent()
    }
  }
}

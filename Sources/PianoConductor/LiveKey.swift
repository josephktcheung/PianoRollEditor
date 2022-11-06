//
//  LiveKey.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 2/11/2022.
//

import AudioKit
import ComposableArchitecture
import Foundation
import Tonic

extension PianoConductor: DependencyKey {
    public static let liveValue = Self.live()

    public static func live() -> Self {
        let actor = PianoSampler()
        return Self(
            noteOn: { try? await actor.play(pitch: $0) },
            noteOff: { try? await actor.pause(pitch: $0) },
            start: { await actor.start() }
        )
    }

    private actor PianoSampler {
        let audioEngine: AudioEngine
        let instrument: MIDISampler

        init() {
            let audioEngine = AudioEngine()
            let instrument = MIDISampler(name: "Piano")
            audioEngine.output = instrument

            do {
                if let fileURL = Bundle.module.url(forResource: "FluidR3_GM", withExtension: "sf2") {
                    try instrument.loadInstrument(url: fileURL)
                } else {
                    Log("Could not find file")
                }
            } catch {
                Log("Could not load instrument")
            }

            self.audioEngine = audioEngine
            self.instrument = instrument
        }

        func play(pitch: Pitch) throws {
            instrument.play(noteNumber: .init(pitch.midiNoteNumber), velocity: 90, channel: 0)
        }

        func pause(pitch: Pitch) throws {
            instrument.stop(noteNumber: .init(pitch.midiNoteNumber), channel: 0)
        }

        func start() {
            do {
                try audioEngine.start()
            } catch {
                Log("Could not start engine")
            }
        }
    }
}

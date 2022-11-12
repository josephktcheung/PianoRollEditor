//
//  Conductor.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 2/11/2022.
//

import AudioKit
import Tonic

public struct PianoConductor {
    public var noteOn: @Sendable (Pitch) async -> Void
    public var noteOff: @Sendable (Pitch) async -> Void
    public var start: @Sendable () async -> Void
    public var stop: @Sendable () async -> Void
}

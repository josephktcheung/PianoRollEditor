//
//  TestKey.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 2/11/2022.
//

import Dependencies
import XCTestDynamicOverlay

extension DependencyValues {
    public var pianoConductor: PianoConductor {
        get { self[PianoConductor.self] }
        set { self[PianoConductor.self] = newValue }
    }
}

extension PianoConductor: TestDependencyKey {
    public static var testValue = Self(
        noteOn: XCTUnimplemented("\(Self.self).noteOn"),
        noteOff: XCTUnimplemented("\(Self.self).noteOff"),
        start: XCTUnimplemented("\(Self.self).start"),
        stop: XCTUnimplemented("\(Self.self).stop")
    )
}

extension PianoConductor {
    public static let noop = Self(
        noteOn: { _ in },
        noteOff: { _ in },
        start: {},
        stop: {}
    )
}

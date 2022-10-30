//
//  PianoRollEditorDemoApp.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 29/10/2022.
//

import SwiftUI

@main
struct PianoRollEditorDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoView(store: .init(initialState: .init(), reducer: Demo()))
        }
    }
}

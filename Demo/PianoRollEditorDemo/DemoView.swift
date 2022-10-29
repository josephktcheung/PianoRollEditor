//
//  ContentView.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 29/10/2022.
//

import PianoRollEditor
import SwiftUI
import Tonic

struct DemoView: View {
    let pitchRange = Pitch(36)...Pitch(81)

    var body: some View {
        PianoRollEditor(
            store: .init(
                initialState: .init(
                    content: .init(
                        pianoRoll: .init(
                            notes: [
                                .init(color: .red, start: 5, length: 2, pitch: 5, text: "E2"),
                                .init(color: .cyan, start: 7, length: 1, pitch: 8, text: "G2"),
                                .init(color: .green, start: 8, length: 4, pitch: 12, text: "B2"),
                                .init(color: .cyan, start: 12, length: 3, pitch: 16, text: "D#3"),
                            ],
                            length: 100,
                            height: pitchRange.count
                        ),
                        pitchRange: pitchRange
                    )
                ),
                reducer: PianoRollEditorReducer()
            )
        )
        .background(Color(white: 0.3))
    }
}

struct DemoView_Previews: PreviewProvider {
    static var previews: some View {
        DemoView()
    }
}

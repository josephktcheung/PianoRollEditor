//
//  ContentView.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 29/10/2022.
//

import ComposableArchitecture
import PianoRollEditor
import SwiftUI
import Tonic

let pitchRange = Pitch(36)...Pitch(77)

struct Demo: ReducerProtocol {
    struct State: Equatable {
        var editor: PianoRollEditorReducer.State = .init(
            content: .init(
                keyboardAlignment: .right,
                pianoRoll: .init(
                    notes: [
                        .init(start: 5, length: 2, pitch: 5, text: "E2", color: .red),
                        .init(start: 7, length: 1, pitch: 8, text: "G2", color: .cyan),
                        .init(start: 8, length: 4, pitch: 12, text: "B2", color: .green),
                        .init(start: 12, length: 3, pitch: 16, text: "D#3", color: .cyan),
                    ],
                    length: 100,
                    height: pitchRange.count
                ),
                pitchRange: pitchRange,
                pitchSequence: [
                    .init(pitch: 82.4, seconds: 2.5),
                    .init(pitch: 82.6, seconds: 2.6),
                    .init(pitch: 82.7, seconds: 2.8),
                    .init(pitch: 82.3, seconds: 3.0),
                    .init(pitch: 82.5, seconds: 3.2),
                    .init(pitch: 82.6, seconds: 3.4),
                    .init(pitch: 83.0, seconds: 3.5),
                ]
            )
        )
    }

    enum Action: Equatable {
        case editor(PianoRollEditorReducer.Action)
        case viewDidAppear
        case viewDidDisappear
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.editor, action: /Action.editor) {
            PianoRollEditorReducer()
        }
    }
}

struct DemoView: View {
    let store: StoreOf<Demo>

    init(store: StoreOf<Demo>) {
        self.store = store
    }

    var body: some View {
        VStack {
            WithViewStore(store.stateless) { viewStore in
                PianoRollEditor(
                    store: store.scope(state: \.editor, action: Demo.Action.editor)
                )
                .background(Color(white: 0.3))
                .onAppear {
                    viewStore.send(.viewDidAppear)
                }
                .onDisappear {
                    viewStore.send(.viewDidDisappear)
                }
            }
        }
    }
}

struct DemoView_Previews: PreviewProvider {
    static var previews: some View {
        DemoView(store: .init(initialState: .init(), reducer: Demo()))
    }
}

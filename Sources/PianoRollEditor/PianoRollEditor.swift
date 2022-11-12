//
//  PianoRollEditor.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 29/10/2022.
//

import ComposableArchitecture
import Keyboard
import PianoConductor
import PianoRoll
import SolidScroll
import SwiftUI
import Tonic

public struct PianoRollEditorReducer: ReducerProtocol {
    public struct State: Equatable {
        public var content: Content.State
        public var isTimerActive = false
        public var milliSecondsLapsed = 0
        
        public init(
            content: Content.State = .init()
        ) {
            self.content = content
        }
    }
    
    public enum Action: Equatable {
        case content(Content.Action)
    }
    
    public init() {}
    
    @Dependency(\.continuousClock) var clock
    
    private enum TimerID {}
    
    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.content, action: /Action.content) {
            Content()
        }
        
        Reduce { state, action in
            switch action {
            case .content:
                return .none
            }
        }
    }
}

public struct PianoRollEditor: View {
    public var store: StoreOf<PianoRollEditorReducer>

    public init(store: StoreOf<PianoRollEditorReducer>) {
        self.store = store
    }

    public var body: some View {
        PitchDiagramContentView(
            store: store.scope(state: \.content, action: PianoRollEditorReducer.Action.content)
        )
    }
}

#if DEBUG

struct PitchDiagramViewWrapper: View {
    @State var model: PianoRollModel = .init(notes: [], length: 100, height: 50)

    var body: some View {
        PianoRollEditor(store: .init(initialState: .init(), reducer: PianoRollEditorReducer()))
            .background(Color(white: 0.3))

        PianoRollEditor(store: .init(initialState: .init(), reducer: PianoRollEditorReducer()))
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
struct PitchDiagramView_Previews: PreviewProvider {

    static var previews: some View {
        PitchDiagramViewWrapper()
    }
}
#endif


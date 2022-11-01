//
//  PianoRollEditor.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 29/10/2022.
//

import ComposableArchitecture
import Keyboard
import PianoRoll
import SolidScroll
import SwiftUI
import Tonic

public struct PianoRollEditorReducer: ReducerProtocol {
    public struct State: Equatable {
        public var proxy: SolidScrollViewProxy?
        public var content: Content.State
        public var isTimerActive = false
        public var milliSecondsLapsed = 0

        public init(
            proxy: SolidScrollViewProxy? = nil,
            content: Content.State = .init()
        ) {
            self.proxy = proxy
            self.content = content
        }
    }

    public enum Action: Equatable {
        case proxyChanged(SolidScrollViewProxy?)
        case content(Content.Action)
        case play
        case stop
        case onDisappear
        case timerTicked
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
            case let .proxyChanged(proxy):
                state.proxy = proxy
                state.content.offset = state.proxy?.contentOffset.x ?? .zero
                return .none

            case .content:
                return .none

            case .play:
                state.isTimerActive = true
                return .run { [isTimerActive = state.isTimerActive] send in
                    guard isTimerActive else { return }
                    for await _ in self.clock.timer(interval: .milliseconds(50)) {
                      await send(.timerTicked)
                    }
                }
                .cancellable(id: TimerID.self, cancelInFlight: true)

            case .stop:
                state.milliSecondsLapsed = 0
                return .cancel(id: TimerID.self)

            case .timerTicked:
                state.milliSecondsLapsed += 50

                // Find activated pitches
                state.content.activatedPitches = state.content.pianoRollNotes
                    .filter {
                        let startTime = $0.start * 500
                        let endTime = ($0.start + $0.length) * 500
                        return (startTime...endTime).contains(Double(state.milliSecondsLapsed))
                    }
                    .reduce(into: [Pitch: Color]()) { dict, element in
                        let pitch = Array(state.content.pitchRange)[element.pitch - 1]
                        dict[pitch] = element.color
                    }

                guard let proxy = state.proxy else {
                    return .none
                }

                proxy.setContentOffset(
                    .init(
                        x: proxy.contentOffset.x + state.content.gridSize.width / 10,
                        y: proxy.contentOffset.y
                    ),
                    animated: false
                )

                return .none

            case .onDisappear:
              return .cancel(id: TimerID.self)
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
        WithViewStore(store.stateless) { viewStore in
            SolidScrollView([.horizontal, .vertical], showsIndicators: true) {
                PitchDiagramContentView(
                    store: store.scope(state: \.content, action: PianoRollEditorReducer.Action.content)
                )
            }
            .onPreferenceChange(ContainedScrollViewKey.self) {
                viewStore.send(.proxyChanged($0))
            }
        }
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


//
//  ContentView.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 29/10/2022.
//

import Charts
import ComposableArchitecture
import Keyboard
import PianoRoll
import Tonic
import SolidScroll
import SwiftUI

fileprivate let evenSpacingInitialSpacerRatio: [Letter: CGFloat] = [
    .C: 0.0,
    .D: 2.0 / 12.0,
    .E: 4.0 / 12.0,
    .F: 0.0 / 12.0,
    .G: 1.0 / 12.0,
    .A: 3.0 / 12.0,
    .B: 5.0 / 12.0
]

fileprivate let evenSpacingSpacerRatio: [Letter: CGFloat] = [
    .C: 7.0 / 12.0,
    .D: 7.0 / 12.0,
    .E: 7.0 / 12.0,
    .F: 7.0 / 12.0,
    .G: 7.0 / 12.0,
    .A: 7.0 / 12.0,
    .B: 7.0 / 12.0
]

fileprivate let evenSpacingRelativeBlackKeyWidth: CGFloat = 7.0 / 12.0

public struct Content: ReducerProtocol {
    public enum KeyboardAlignment {
        case left
        case right
    }

    public struct PitchSequence: Equatable, Identifiable {
        public var id: Double { time.timeIntervalSince1970 }

        public var pitch: Float
        public var time: Date

        public init(pitch: Float, time: Date) {
            self.pitch = pitch
            self.time = time
        }
    }

    public struct State: Equatable {
        public var activatedPitches: [Pitch: Color]
        public var disabled: Bool
        public var offset: CGPoint {
            guard let contentOffset = proxy?.contentOffset else {
                return .zero
            }
            return .init(x: -contentOffset.x, y: -contentOffset.y)
        }
        public var keyboardAlignment: KeyboardAlignment
        public var pianoRoll: PianoRollModel
        public var pitchRange: ClosedRange<Pitch>
        public var whiteKeyWidth: CGFloat
        public var pitchSequence: [PitchSequence]

        public var spacerHeight: CGFloat {
            whiteKeyWidth * evenSpacingRelativeBlackKeyWidth
        }

        public var gridSize: CGSize {
            .init(width: spacerHeight * 2, height: spacerHeight)
        }

        public var pianoRollHeight: CGFloat {
            CGFloat(pitchRange.count) * gridSize.height
        }

        public var pianoRollWidth: CGFloat {
            CGFloat(pianoRoll.length) * gridSize.width
        }

        public var proxy: SolidScrollViewProxy? = nil

        public init(
            activatedPitches: [Pitch: Color] = [:],
            disabled: Bool = false,
            keyboardAlignment: KeyboardAlignment = .left,
            offset: CGPoint = .zero,
            pianoRoll: PianoRollModel = .init(notes: [], length: 0, height: 0),
            pitchRange: ClosedRange<Pitch> = Pitch(0)...Pitch(10),
            pitchSequence: [PitchSequence] = [],
            whiteKeyWidth: CGFloat = 60
        ) {
            self.activatedPitches = activatedPitches
            self.disabled = disabled
            self.keyboardAlignment = keyboardAlignment
            self.whiteKeyWidth = whiteKeyWidth
            self.pitchRange = pitchRange
            self.pitchSequence = pitchSequence
            self.pianoRoll = pianoRoll
        }
    }

    public enum Action: Equatable {
        case noteOn(Pitch, CGPoint)
        case noteOff(Pitch)
        case pianoRollChanged(PianoRollModel)
        case proxyChanged(SolidScrollViewProxy?)
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .proxyChanged(proxy):
            state.proxy = proxy
            return .none

        case let .pianoRollChanged(model):
            state.pianoRoll = model
            return .none

        case .noteOn, .noteOff:
            return .none
        }
    }
}

struct PitchDiagramContentView: View {
    struct ViewState: Equatable {
        struct Keyboard: Equatable {
            var disabled: Bool
            var whiteKeyWidth: CGFloat
            var pitchRange: ClosedRange<Pitch>
            var pianoRollHeight: CGFloat
            var activatedPitches: [Pitch: Color]

            var keyboardHeight: CGFloat {
                whiteKeyWidth * CGFloat(whiteKeys.count)
            }

            var pitchRangeBoundedByNaturals: ClosedRange<Pitch> {
                var lowerBound = pitchRange.lowerBound
                if lowerBound.note(in: .C).accidental != .natural {
                    lowerBound = Pitch(intValue: lowerBound.intValue - 1)
                }
                var upperBound = pitchRange.upperBound
                if upperBound.note(in: .C).accidental != .natural {
                    upperBound = Pitch(intValue: upperBound.intValue + 1)
                }
                return lowerBound ... upperBound
            }

            var whiteKeys: [Pitch] {
                var returnValue: [Pitch] = []
                for pitch in pitchRangeBoundedByNaturals where pitch.note(in: .C).accidental == .natural {
                    returnValue.append(pitch)
                }
                return returnValue
            }

            init(state: Content.State) {
                self.disabled = state.disabled
                self.whiteKeyWidth = state.whiteKeyWidth
                self.pitchRange = state.pitchRange
                self.pianoRollHeight = state.pianoRollHeight
                self.activatedPitches = state.activatedPitches
            }
        }

        struct PianoRoll: Equatable {
            var editable: Bool
            var model: PianoRollModel
            var gridSize: CGSize

            init(state: Content.State) {
                self.editable = !state.disabled
                self.model = state.pianoRoll
                self.gridSize = .init(width: state.spacerHeight * 2, height: state.spacerHeight)
            }
        }

        struct Line: Equatable {
            var height: CGFloat
            var offset: CGFloat

            init(state: Content.State) {
                self.height = CGFloat(state.pianoRoll.height) * state.spacerHeight
                self.offset = state.offset.y + state.spacerHeight * 2 * 5
            }
        }

        struct PitchLine: Equatable {
            var height: CGFloat
            var width: CGFloat
            var offset: CGPoint
            var pitches: [Content.PitchSequence]

            init(state: Content.State) {
                self.height = state.pianoRollHeight
                self.width = state.pianoRollWidth
                let maxContentOffset: CGPoint = state.proxy?.maxContentOffset ?? .zero
                self.offset = .init(x: state.offset.x + maxContentOffset.x / 2, y: state.offset.y + maxContentOffset.y / 2)
                self.pitches = state.pitchSequence
            }
        }
    }

    private let store: StoreOf<Content>

    init(store: StoreOf<Content>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(store, observe: { $0.keyboardAlignment }) { viewStore in
            HStack(alignment: .bottom, spacing: 0) {
                switch viewStore.state {
                case .right:
                    pianoRoll
                        .coordinateSpace(name: "scroll")
                    ScrollView([.vertical]) {
                        WithViewStore(store, observe: { $0.offset }) { viewStore in
                            keyboard.offset(y: viewStore.state.y)
                        }
                    }
                    .scrollDisabled(true)

                case .left:
                    ScrollView([.vertical]) {
                        WithViewStore(store, observe: { $0.offset }) { viewStore in
                            keyboard.offset(y: viewStore.state.y)
                        }
                    }
                    .scrollDisabled(true)
                    pianoRoll
                        .coordinateSpace(name: "scroll")
                }
            }
        }
    }

    @ViewBuilder private var keyboard: some View {
        WithViewStore(store, observe: ViewState.Keyboard.init) { viewStore in
            KeyboardView(
                activatedPitches: viewStore.activatedPitches,
                disabled: viewStore.disabled,
                pitchRange: viewStore.pitchRange,
                whiteKeyWidth: viewStore.whiteKeyWidth,
                keyboardHeight: viewStore.keyboardHeight,
                pianoRollHeight: viewStore.pianoRollHeight,
                noteOn: { viewStore.send(.noteOn($0, $1)) },
                noteOff: { viewStore.send(.noteOff($0)) }
            )
            .equatable()
            .zIndex(1)
        }
    }

    @ViewBuilder private var pianoRoll: some View {
        ZStack {
            WithViewStore(store.stateless) { viewStore in
                SolidScrollView([.horizontal, .vertical]) {
                    WithViewStore(store, observe: ViewState.PianoRoll.init) { viewStore in
                        PianoRoll(
                            editable: viewStore.editable,
                            model: viewStore.binding(get: \.model, send: Content.Action.pianoRollChanged),
                            gridColor: .white.opacity(0.3),
                            gridSize: viewStore.gridSize
                        )
                    }
                }
                .onPreferenceChange(ContainedScrollViewKey.self) {
                    viewStore.send(.proxyChanged($0))
                }
            }
            pitchLine
        }
    }


    @ViewBuilder private var pitchLine: some View {
        WithViewStore(store, observe: ViewState.PitchLine.init) { viewStore in
            ScrollView([.horizontal, .vertical]) {
                PitchLineChart(pitches: viewStore.pitches)
                    .allowsHitTesting(false)
                    .frame(width: viewStore.width, height: viewStore.height)
                    .offset(x: viewStore.offset.x, y: viewStore.offset.y)
            }
            .scrollDisabled(true)
            .allowsHitTesting(false)
        }
    }
}

struct PitchLineChart: View, Equatable {
    var pitches: [Content.PitchSequence]

    var body: some View {
        Chart(pitches) {
            LineMark(
                x: .value("Time", $0.time),
                y: .value("Pitch", $0.pitch)
            )
            .opacity(0.5)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .foregroundStyle(.white)
    }
}

struct KeyboardView: View, Equatable {
    static func == (lhs: KeyboardView, rhs: KeyboardView) -> Bool {
        lhs.pitchRange == rhs.pitchRange &&
        lhs.whiteKeyWidth == rhs.whiteKeyWidth &&
        lhs.keyboardHeight == rhs.keyboardHeight &&
        lhs.pianoRollHeight == rhs.pianoRollHeight &&
        lhs.activatedPitches == rhs.activatedPitches
    }

    var activatedPitches: [Pitch: Color] = [:]
    var disabled: Bool = false
    var pitchRange: ClosedRange<Pitch>
    var whiteKeyWidth: CGFloat
    var keyboardHeight: CGFloat
    var pianoRollHeight: CGFloat
    var noteOn: (Pitch, CGPoint) -> Void
    var noteOff: (Pitch) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Keyboard(
                layout: .verticalPiano(
                    pitchRange: pitchRange,
                    initialSpacerRatio: evenSpacingInitialSpacerRatio,
                    spacerRatio: evenSpacingSpacerRatio,
                    relativeBlackKeyWidth: evenSpacingRelativeBlackKeyWidth
                ),
                noteOn: noteOn,
                noteOff: noteOff
            ) { pitch, isActivated in
                KeyboardKey(
                    pitch: pitch,
                    isActivated: isActivated,
                    pressedColor: activatedPitches[pitch] ?? .red,
                    alignment: .bottomTrailing,
                    isActivatedExternally: activatedPitches.keys.contains(pitch)
                )
            }
                .frame(width: 100, height: keyboardHeight)
                .offset(y: (pianoRollHeight - keyboardHeight) / 2)
                .disabled(disabled)
        }
        .frame(height: pianoRollHeight)
        .clipped()
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGPoint
    static var defaultValue = CGPoint.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.x += nextValue().x
        value.y += nextValue().y
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PitchDiagramContentView(store: .init(initialState: .init(), reducer: Content()))
    }
}
#endif

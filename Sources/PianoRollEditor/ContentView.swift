//
//  ContentView.swift
//  PianoRollEditorDemo
//
//  Created by Joseph Cheung on 29/10/2022.
//

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
    public struct State: Equatable {
        public var disabled: Bool
        public var offset: CGFloat
        public var pianoRollNotes: [PianoRollNote]
        public var pianoRollLength: Int
        public var pianoRollHeight: Int

        public var pianoRoll: PianoRollModel {
            .init(notes: pianoRollNotes, length: pianoRollLength, height: pianoRollHeight)
        }
        public var pitchRange: ClosedRange<Pitch>
        public var whiteKeyWidth: CGFloat

        public var spacerHeight: CGFloat {
            whiteKeyWidth * evenSpacingRelativeBlackKeyWidth
        }

        public var gridSize: CGSize {
            .init(width: spacerHeight * 2, height: spacerHeight)
        }

        public init(
            disabled: Bool = false,
            offset: CGFloat = .zero,
            pianoRollNotes: [PianoRollNote] = [],
            pianoRollLength: Int = 0,
            pianoRollHeight: Int = 0,
            pitchRange: ClosedRange<Pitch> = Pitch(0)...Pitch(10),
            whiteKeyWidth: CGFloat = 60
        ) {
            self.disabled = disabled
            self.offset = offset
            self.whiteKeyWidth = whiteKeyWidth
            self.pianoRollNotes = pianoRollNotes
            self.pianoRollHeight = pianoRollHeight
            self.pianoRollLength = pianoRollLength
            self.pitchRange = pitchRange
        }
    }

    public enum Action: Equatable {
        case noteOn(Pitch, CGPoint)
        case noteOff(Pitch)
        case pianoRollChanged(PianoRollModel)
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}

struct PitchDiagramContentView: View {
    struct ViewState: Equatable {
        struct Keyboard: Equatable {
            var disabled: Bool
            var offset: CGFloat
            var whiteKeyWidth: CGFloat
            var pitchRange: ClosedRange<Pitch>
            var pianoRollHeight: CGFloat

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
                self.offset = max(state.offset, 0)
                self.pianoRollHeight = CGFloat(pitchRange.count) * state.spacerHeight
            }
        }

        struct PianoRoll: Equatable {
            var editable: Bool
            var model: PianoRollModel
            var gridSize: CGSize

            init(state: Content.State) {
                self.editable = state.disabled
                self.model = state.pianoRoll
                self.gridSize = .init(width: state.spacerHeight * 2, height: state.spacerHeight)
            }
        }

        struct Line: Equatable {
            var height: CGFloat
            var offset: CGFloat

            init(state: Content.State) {
                self.height = CGFloat(state.pianoRollHeight) * state.spacerHeight
                self.offset = state.offset + state.spacerHeight * 2 * 5
            }
        }
    }

    private let store: StoreOf<Content>

    init(store: StoreOf<Content>) {
        self.store = store
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            keyboard
            pianoRoll
        }
    }

    @ViewBuilder private var keyboard: some View {
        WithViewStore(store, observe: ViewState.Keyboard.init) { viewStore in
            KeyboardView(
                disabled: viewStore.disabled,
                pitchRange: viewStore.pitchRange,
                whiteKeyWidth: viewStore.whiteKeyWidth,
                keyboardHeight: viewStore.keyboardHeight,
                pianoRollHeight: viewStore.pianoRollHeight,
                noteOn: { viewStore.send(.noteOn($0, $1)) },
                noteOff: { viewStore.send(.noteOff($0)) }
            )
            .equatable()
            .offset(x: viewStore.offset)
            .zIndex(1)
        }
    }

    @ViewBuilder private var pianoRoll: some View {
        WithViewStore(store, observe: ViewState.PianoRoll.init) { viewStore in
            PianoRoll(
                editable: viewStore.editable,
                model: viewStore.binding(get: \.model, send: Content.Action.pianoRollChanged),
                gridColor: .white.opacity(0.3),
                gridSize: viewStore.gridSize
            )
        }
    }
}

struct KeyboardView: View, Equatable {
    static func == (lhs: KeyboardView, rhs: KeyboardView) -> Bool {
        lhs.pitchRange == rhs.pitchRange &&
        lhs.whiteKeyWidth == rhs.whiteKeyWidth &&
        lhs.keyboardHeight == rhs.keyboardHeight &&
        lhs.pianoRollHeight == rhs.pianoRollHeight
    }

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
                    alignment: .bottomTrailing
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


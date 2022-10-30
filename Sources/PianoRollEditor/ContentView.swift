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

fileprivate let spacerRatio: CGFloat = 7 / 12

public struct Content: ReducerProtocol {
    public struct State: Equatable {
        public var disabled: Bool
        public var offset: CGFloat
        public var pianoRoll: PianoRollModel
        public var pitchRange: ClosedRange<Pitch>
        public var whiteKeyWidth: CGFloat

        public var spacerHeight: CGFloat {
            whiteKeyWidth * spacerRatio
        }

        public var gridSize: CGSize {
            .init(width: spacerHeight * 2, height: spacerHeight)
        }

        public init(
            disabled: Bool = false,
            offset: CGFloat = .zero,
            pianoRoll: PianoRollModel = .init(notes: [], length: 10, height: 10),
            pitchRange: ClosedRange<Pitch> = Pitch(0)...Pitch(10),
            whiteKeyWidth: CGFloat = 60
        ) {
            self.disabled = disabled
            self.offset = offset
            self.whiteKeyWidth = whiteKeyWidth
            self.pianoRoll = pianoRoll
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
                self.offset = state.offset
                self.pianoRollHeight = CGFloat(pitchRange.count) * state.spacerHeight
            }
        }

        struct PianoRoll: Equatable {
            var readOnly: Bool
            var model: PianoRollModel
            var gridSize: CGSize

            init(state: Content.State) {
                self.readOnly = state.disabled
                self.model = state.pianoRoll
                self.gridSize = .init(width: state.spacerHeight * 2, height: state.spacerHeight)
            }
        }

        struct Line: Equatable {
            var height: CGFloat
            var offset: CGFloat

            init(state: Content.State) {
                self.height = CGFloat(state.pianoRoll.height) * state.spacerHeight
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
                model: viewStore.binding(get: \.model, send: Content.Action.pianoRollChanged),
                gridSize: viewStore.gridSize,
                gridColor: .white.opacity(0.3),
                readOnly: viewStore.readOnly
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
                layout: .verticalPiano(pitchRange: pitchRange),
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


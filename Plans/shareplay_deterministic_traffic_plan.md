# SharePlay Deterministic Traffic Plan

**Status:** Planned.

**See also:** [`Requirements/shareplay_multiplayer.md`](../Requirements/shareplay_multiplayer.md) (current shipped SharePlay behavior) · [`shareplay_competitive_mode_plan.md`](shareplay_competitive_mode_plan.md) (original iOS+iPad planning record)

## Summary

Make SharePlay races fairer by giving both players the same generated traffic-row sequence for each round.

Use a host-generated `roundSeed`, but do **not** rely on a shared mutable random stream. Instead, derive each traffic row from `(roundSeed, trafficRowIndex)` so row generation is stable even if one device crashes, pauses, inserts a safety row, or advances frames at a slightly different cadence.

This preserves the current SharePlay model: each device still runs local gameplay, controls, collisions, scoring, lives, leaderboard submission, and final result sync.

## Target Behavior

- Host sends an authoritative traffic seed with each SharePlay `roundStart`.
- Host and guest generate the same ordered sequence of normal traffic rows.
- Each row keeps the existing rule: random car/empty value per column, then if all columns are cars, empty one random column.
- Safety rows from speed-increase protection stay local flow control and do not consume a traffic-row index.
- Solo play keeps using system randomness and should be unaffected.
- Successful SharePlay retry starts a new round with a new host-generated seed.

## Key Design

- Add a deterministic traffic row generator in shared gameplay code. Input: `roundSeed`, `trafficRowIndex`, and column count. Output: one `[GridState.CellState]`.
- Derive row contents from a stable hash or PRNG expansion of `(roundSeed, trafficRowIndex)`, not from previous random calls.
- Replace SharePlay traffic randomness at the `GridStateCalculator` boundary with indexed row generation. Keep the existing `RandomSource` path for solo gameplay.
- Extend SharePlay wire/state models so `roundStart` carries the traffic seed through countdown and into `.inRound`.
- Configure `GameScene` with the SharePlay traffic generator before `startImmediately()` begins the round.

## Algorithm Notes

The current row mechanics are compatible with deterministic traffic, but only if the generator is indexed:

```swift
let rowSeed = stableHash(roundSeed, trafficRowIndex)
var row = columns.map { column in
    stableBit(rowSeed, column) ? .Car : .Empty
}

if row.allSatisfy({ $0 == .Car }) {
    let emptyColumn = stableHash(rowSeed, "emptyColumn") % columns.count
    row[emptyColumn] = .Empty
}
```

A shared mutable seeded PRNG is not robust enough because the current algorithm consumes a variable number of random values: one draw per column, plus one extra draw only for all-car rows, and zero draws for `.updateWithEmptyRow`. Any local divergence in update count would desynchronize all future rows.

## Implementation Changes

- `SharePlayMatchCommand.roundStart`: add `trafficSeed`.
- `SharePlayMatchState`: carry the seed in countdown/in-round states or a round settings model.
- `SharePlayMatchStateMachine`: host creates and sends a fresh seed for each round start; guest adopts the received seed.
- `GameScene` / `GridStateCalculator`: support an optional deterministic traffic mode with a resettable `trafficRowIndex`.
- `GameViewModel+SharePlay`: apply the seed to the scene before starting the SharePlay round.
- `Requirements/shareplay_multiplayer.md`: update the current "no shared game state beyond score/lives/elimination" wording to include shared traffic seed/row sequence.

## Test Plan

- Unit test same `(roundSeed, trafficRowIndex)` produces identical rows across independent generators.
- Unit test different seeds produce different sequences.
- Unit test all-car repair is deterministic and always leaves at least one empty column.
- Unit test `.updateWithEmptyRow` does not consume a traffic-row index.
- Unit test two `GridStateCalculator` instances with the same traffic seed produce matching normal traffic rows across many updates.
- Update SharePlay state-machine and two-peer convergence tests for seeded `roundStart`.
- Add a scene/view-model test proving the SharePlay seed is applied before the round starts.
- Manual 2-device QA: confirm matching traffic rows on initial SharePlay round and after retry.

## Assumptions

- "Same sequence" means the same ordered normal traffic rows, not full frame-by-frame lockstep.
- Local crash timing, pause state, audio recovery, and frame cadence may still differ.
- Safety-row insertion remains local and does not affect the next actual traffic row.
- No precomputed traffic deck is needed for v1.

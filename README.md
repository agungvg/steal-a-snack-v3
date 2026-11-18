[![make.fun — roblox-brainrot-01](https://img.shields.io/badge/make.fun-roblox--brainrot--01-orange)](https://make.fun/bounty/roblox-brainrot-01)
[![Play on Roblox](https://img.shields.io/badge/Play-Roblox-red)](https://www.roblox.com/games/106001400572518)

# Steal a Snack

A 3D brainrot game for make.fun's **roblox-brainrot-01** competition — collect
absurd snack characters that earn cash every second, guard them on your base,
and steal the rare ones from everyone else before they lock their base and
dash home with your catch.

Play it here: https://www.roblox.com/games/106001400572518

## How to play

1. Snacks waddle down the belt in the middle of the map. Click one to buy it
   — it walks to your base and starts earning cash every second.
2. Spend your cash on rarer snacks. Each one earns more per second than the
   last, and your income ticks up live on the HUD.
3. Other players can steal your snacks. Lock your base while you are away,
   and steal theirs while their lock is down.
4. Rebirth once you are rich enough: trade your snacks and cash for a
   permanent income multiplier and climb the ladder again, faster.
5. Waves roll in every few minutes and shift the rarity odds; the weather
   cycles too. The richest players show on the leaderboard.

## The snack ladder

| Snack | Rarity | Price | Income |
| --- | --- | --- | --- |
| Soggy Fry | Common | $50 | $1/s |
| Noodle Ned | Common | $100 | $2/s |
| Dancing Dumpling | Rare | $300 | $5/s |
| Turbo Taco | Rare | $500 | $8/s |
| Lord Lasagna | Epic | $1,500 | $15/s |
| Queen Queso | Epic | $2,500 | $20/s |
| King Kebab | Legendary | $6,000 | $40/s |
| Baron Burger | Legendary | $10,000 | $60/s |
| Eternal Ramen | Mythic | $25,000 | $120/s |

Every snack is a part-built 3D character with its name, rarity, price and
income on a label above its head — no prebuilt assets, everything is built
in code.

## Systems

- **Economy** — buying, per-second income, cash and multiplier handling.
- **Bases** — six slots per player, lockable, with a belt and a built world.
- **Spawner** — snacks walk the belt on a timer, rarities weighted by wave.
- **Steal** — ownership transfer with lock and rate-limit guards.
- **Rebirth** — trade progress for a permanent +0.5x income multiplier.
- **Wave / Weather** — timed waves that shift rarity odds; cycling weather.
- **Leaderboard** — richest players, live on the HUD.
- **Effects / Saves / RateLimit** — buy and steal effects, DataStore saves
  (disabled in Studio, live once published), and per-action rate limits.
- **CharacterFactory** — builds every snack model from parts, with click
  detectors and captions.

All state lives in one place (`src/server/State.luau`); all tuning lives in
one place (`src/shared/Config.luau`).

## Player objects vs state tables

Two objects describe a player, and the modules keep them apart on purpose:

- The **Player instance** (a Roblox `Player`) is what the server passes to
  `Bases`, `Economy`, `Steal` and `Rebirth`. `Bases.createBase` attaches the
  base to it (`.Base`, `.Slots`, `.SlotPositions`, `.LockIndicator`), and the
  income multiplier lives on it (`.Multiplier`, `.Rebirths`).
- The **State table** (`State.getPlayer(userId)`) holds the numbers behind
  that player: `Cash`, `Snacks`, `Locked`, and a `Multiplier`/`Rebirths`
  pair that mirrors the run. Every `State.*` function takes a `userId`, never
  a Player instance.

A module that needs the base (slots, lock indicator) must be handed the
Player instance; a module that only needs cash or the snack list takes the
`userId` and reads State. Mixing the two up is the easiest way to break a
steal or a rebirth — see `tests/test_steal.luau` for the flow that catches it.

## Build

Requires [Rojo](https://github.com/rojo-rbx/rojo):

```sh
rojo build -o game.rbxl
```

Open `game.rbxl` in Roblox Studio to playtest, then publish it to the place
named in `PLAY.json`. The experience's description on Roblox holds the
make.fun play code `makefun-parcel-ranch-highland`, which proves the place
is this entry's.

## Tests

The Luau test suite runs against a stub Roblox environment — no Studio
needed:

```sh
tests/run.sh
```

It checks the config ladder, state, the character factory, the economy,
bases, the spawner, stealing, rebirth, waves, weather, the leaderboard,
saves, rate limiting, and the server bootstrap plus HUD.

## Project layout

```
src/
  server/          Server script + 13 system modules
  shared/Config.luau
  client/Hud.client.luau
default.project.json
tests/             Luau test suite + Roblox stub environment
```

## License

MIT — see [LICENSE](LICENSE).

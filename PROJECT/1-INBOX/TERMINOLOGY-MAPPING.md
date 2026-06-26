Here's your whiteboard cleaned up. It reads as an aviation naming scheme in three layers: a **flight taxonomy** (run types), a **status lifecycle** (session states), and **machine-level constructs**. I've added a proposed swarm meaning for each — swap any that don't fit your model.

**AIRPORT — flights (run / session types)**

The four classes form a scope ladder, longest to shortest. "Airport" itself = the harness (where flights originate and get dispatched).

| Term | Aviation sense | Proposed PDDA/swarm meaning |
|---|---|---|
| Long Haul | Longest-distance flight | Long, multi-phase run (Marathon-style build→review chains) |
| Cross Country | Long but bounded | Multi-step task with a defined endpoint |
| Commuter | Short, routine, repeated | Recurring short run (scheduled / standard job) |
| Bus | Local Bus - Shortest, frequent hop | Single-shot / quick one-off task |

**STAYS — status (session lifecycle)**

Reads as a three-state lifecycle. (You wrote "STAYS" but the items are states — flag if "stays" is intentional.)

| Term | Meaning |
|---|---|
| Preflight | Setup / init — queued, not yet active |
| In Flight | Active session running (= "any active sessions") |
| Grounded | Idle, no activity — stopped / parked |

**AT MACHINE LEVEL — local constructs**

- Ground Control — the orchestrator / coordinator process (the local harness driving the agents)
- Luggage — payload carried between agents or across phases (artifacts, context, handoff state, relays)

**Open slots to fill**
- Where do the X / Y / Z agents sit? Natural fit is *aircraft* (or tail numbers) flying the routes, with Ground Control as the harness — the board doesn't name them yet.
- "Stays" vs "States" — confirm wording.
- Is "Commuter" distinct from "Shuttle" by *frequency* (commuter = scheduled, shuttle = on-demand) or purely by *length*?

Want this as `TERMINOLOGY.md` (GFM) for the repo once you've locked the mappings?
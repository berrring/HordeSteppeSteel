# Checkpoint 1 server validation

Executed from the Roblox Studio Play client against the running Checkpoint 1 server. No test modified server memory directly. The test took a server snapshot, sent disallowed orders through the game command interface, and compared the next server snapshot.

## Resource authority

- Before: Mongol gold 34, food 27, wood 22. Rus gold 34, food 27, wood 22.
- A move received an unexpected resource field. The server declined with **Unexpected command field. No change was made.**
- A request for a resource-setting operation was declined with **This order is not available in Checkpoint 1.**
- After: all six resource balances were identical to the prior snapshot, and the current turn and match remained unchanged.
- As a positive control, turn 2 legitimately credited the Mongol province yields. The resulting balances were gold 42, food 35, wood 25.

The server's field allowlist is in `HordeServer.CommandPolicy`. `HordeServer.Match` computes starting balances and province income. Client data is used only for the requested order, target, and current campaign/turn ticket.

## Order authority and repeat protection

- An order for a Rus army sent by the Mongol player was declined.
- A non-adjacent order and a second march by a spent army were declined.
- While Rus was acting, a duplicate End Turn request was declined with **An order or enemy turn is already being resolved.**
- After turn 2 began, replaying the turn 1 ticket was declined with **That order belongs to an earlier campaign or turn.**
- After starting another campaign, the old campaign ticket was declined. The new world's army locations did not change.
- Output for that first End Turn showed exactly one Rus pass: `closed=1 rusOrders=1 rusTurns=1 next=2 phase=mongol`.

This verification covers command schema, order ownership, and stale and overlapping turn requests in one Studio server. Public multiplayer load and abuse-rate testing are outside scope.

AI review agent for trusted-firmware-a (Cortex-A)
============================

Structured review framework for TF-A Gerrit patches, modeled on
https://github.com/masoncl/review-prompts (kernel review framework).

## Dependencies

- [gerrit-code-review-mcp](https://github.com/cayirtepeomer/gerrit-code-review-mcp) — Gerrit MCP tool (fetch changes, post reviews)
- https://review.trustedfirmware.org/ — TF-A Gerrit instance
- A local TF-A clone and a build environment for the target platform

## Installation

Run the setup script to install the skill and slash commands for Claude Code:

```bash
./setup.sh
```

This installs:
- `~/.claude/skills/tfa/SKILL.md` — auto-loaded when working in a TF-A tree
- `~/.claude/commands/tfa-review.md` — `/tfa-review` slash command
- `~/.claude/commands/tfa-verify.md` — `/tfa-verify` slash command

Re-run `./setup.sh` after editing any file under `skills/` or `slash-commands/`.

## Quick start

```
/tfa-review 45537
```

Or without the slash command:

```
Using review-core.md, review Gerrit change 45537
```

The protocol will ask for your build command before analysis begins.

## File structure

| File | Role |
|------|------|
| `review-core.md` | **Execution protocol** — Tasks 0-9, phased workflow |
| `tfa-review-plan.md` | **Rules catalog** — CM-*, WS-*, CS-* rule tables, report format |
| `false-positive-guide.md` | **Verification gates** — eliminate false positives before reporting |
| `skills/tfa.md` | Claude Code skill (source; installed by setup.sh) |
| `slash-commands/tfa-review.md` | `/tfa-review` command (source; installed by setup.sh) |
| `slash-commands/tfa-verify.md` | `/tfa-verify` command (source; installed by setup.sh) |
| `setup.sh` | Install script |

## Review workflow (Tasks 0-9)

```
Task 0   fetch Gerrit change, collect prior comments, ask for build command
Task 1A  git am → <BUILD_CMD> (background) ──────────────────────────────┐
Task 1B  read changed files                                               │  build
Task 1C  CHANGE-N categorization + TodoWrite                              │  running
Task 2   reachability gate (must confirm before rule analysis)            │  in
Task 3   verify prior Gerrit comments one-by-one                          │  background
Task 4   rule analysis per CHANGE category (CS-*, EH-*, TY-*, ...)       │
Task 5   false-positive elimination                                       │
Task 6   write report  (BUILD: PENDING placeholder)                       │
Task 7   write metadata  (build_status: "pending")                        │
Task 8   wait + read build log, evaluate BV-1..BV-5  ◄────────────────── ┘
Task 9   patch report §6 + metadata with real build result
```

Build verification runs in parallel — the build command is platform-agnostic.
Examples accepted at Task 0:

```
make PLAT=k3 BUILD_BASE=/tmp/build    # TI K3 single platform
./MAKEALL                              # TI all-platform script
make PLAT=fvp                          # Arm reference platform
skip                                   # no local build available
```

## Output

- Report: `/tmp/<change_id>_ps<N>_review_report.md`
- Metadata: `./review-metadata.json`
- The agent asks for confirmation before posting anything to Gerrit

## Slash commands

| Command | Description |
|---------|-------------|
| `/tfa-review <change_id>` | Full review of a Gerrit change (Tasks 0-9) |
| `/tfa-verify` | Run false-positive guide against current findings |

## Reference patches

Issues found in past reviews are catalogued at the bottom of
`tfa-review-plan.md` as concrete examples for rule calibration:

- 45537 — TI K3 clock mux driver
- 45538 — TI K3 clock div driver
- 45540 — TI K3 clock core
- 39036 PS23 — DDR driver
- 39040 PS23 — BL1 support
- TI K3/AM62L SCMI+PSCI (motivated CS-9, CS-10, CS-11, CS-12, CS-13)

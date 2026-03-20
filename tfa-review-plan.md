# TF-A Patch Review Plan

This document codifies the rules applied when reviewing patches submitted to
the Trusted Firmware-A (TF-A) project. Rules are drawn from:

- `docs/process/coding-style.rst`
- `docs/process/coding-guidelines.rst`
- `docs/process/commit-style.rst`
- MISRA C:2012 (as referenced by TF-A)
- Observations from the `ti-am62l-clk` patch series (changes 45537, 45538)

Ask user for:
- Path to their local arm-trusted-firmware clone (used for manual review: reading files, applying patches)
- Path to their build integration tree (a separate clone used for applying and building)
- Path to the build root directory containing `MAKEALL` (run `./MAKEALL` from there)

---

## Process

For each patch under review:

1. Fetch the Gerrit change using the `gerrit-review` MCP tool with `include_comments: true`.
   This retrieves all inline review comments left on every prior patchset by all reviewers
   (author replies count too). Install MCP tool from
   https://playbooks.com/mcp/cayirtepeomer/gerrit-code-review-mcp if not available.
2. Extract every inline Gerrit comment from all prior patchsets. For each comment record:
   - Patchset number it was left on
   - Reviewer name
   - File path and line number
   - The comment text (what the reviewer asked for)
3. Read all changed files on disk (after applying the patch locally).
4. For each prior Gerrit comment, look at the current patchset code and determine whether
   the reviewer's specific request was actually addressed. Mark each as:
   - Yes   — the code change clearly addresses the comment
   - No    — the issue described in the comment is still present unchanged
   - Partial — the code changed but only partially addresses the comment
   Note: the author marking a thread "resolved" in Gerrit does NOT mean the issue is fixed.
   Always verify against the actual code.
5. Check each rule category below for new issues not yet raised in prior comments.
6. Apply the patch to the build integration tree (separate clone) and run `./MAKEALL` from
   the build root directory (the directory containing MAKEALL, not the TFA clone itself).
7. Summarize the findings with links to actual place in gerrit that i can click and add
   comments if appropriate.
8. Save the report as a markdown file (see Report Format section).

---

## Rule Categories

### 1. Commit Message

| ID | Rule | Severity |
|----|------|----------|
| CM-1 | Subject line follows Conventional Commits: `<type>(<scope>): <description>` | ERROR |
| CM-2 | Type is one of: `feat fix build ci docs perf refactor revert style test chore` | ERROR |
| CM-3 | Type, scope, and first letter of description are all lowercase | ERROR |
| CM-4 | Body explains *what* the change does and *why* (motivation, impact, alternatives) | WARNING |
| CM-5 | Body provides enough context for reviewers unfamiliar with the subsystem | WARNING |
| CM-6 | `Signed-off-by:` trailer present with real name and email | ERROR |
| CM-7 | `Change-Id:` trailer present and unique | ERROR |
| CM-8 | Scope exists in `changelog.yaml` or a new entry is added | WARNING |

### 2. File Encoding and Whitespace

| ID | Rule | Severity |
|----|------|----------|
| WS-1 | Source files use UTF-8 encoding | ERROR |
| WS-2 | Line endings are Unix (LF only, no CRLF) | ERROR |
| WS-3 | Indentation uses tabs (8-column), not spaces | ERROR |
| WS-4 | No trailing whitespace on any line | ERROR |
| WS-5 | File ends with exactly one newline (no trailing blank lines) | ERROR |
| WS-6 | Lines are at most 80 characters (soft limit; exceed only when readability demands) | WARNING |

### 3. Comments

| ID | Rule | Severity |
|----|------|----------|
| CO-1 | No `//` single-line comments; use `/* ... */` only | ERROR |
| CO-2 | No Doxygen-style `/** \brief ... */` comments; plain `/* ... */` preferred | WARNING |
| CO-3 | No informal/unprofessional language in comments (e.g., "hack", "fixme", "workaround" without explanation) | WARNING |
| CO-4 | Comments describe *why*, not *what* (the code itself shows what) | WARNING |

### 4. Header Guards

| ID | Rule | Severity |
|----|------|----------|
| HG-1 | Every header has an `#ifndef HEADER_NAME_H` / `#define HEADER_NAME_H` guard | ERROR |
| HG-2 | Closing `#endif` carries a comment matching the guard: `#endif /* HEADER_NAME_H */` | WARNING |
| HG-3 | Guard name matches the filename in all-uppercase with underscores | WARNING |

### 5. Include Ordering

| ID | Rule | Severity |
|----|------|----------|
| IN-1 | Includes in three groups separated by blank lines: (1) system/libc, (2) project `<include/...>`, (3) platform `<plat/...>` | ERROR |
| IN-2 | Within each group, includes are in alphabetical order | WARNING |
| IN-3 | Use `<...>` for headers not in the same directory; `"..."` for same-directory headers | WARNING |
| IN-4 | No project or platform headers appear before system headers | ERROR |

### 6. Naming

| ID | Rule | Severity |
|----|------|----------|
| NM-1 | Functions and local variables: `lower_snake_case` | ERROR |
| NM-2 | Preprocessor macros: `UPPER_SNAKE_CASE` | ERROR |
| NM-3 | No abbreviations that obscure meaning | WARNING |
| NM-4 | Typos in identifiers or comments must be corrected | WARNING |

### 7. Types and Portability

| ID | Rule | Severity |
|----|------|----------|
| TY-1 | Use `uintptr_t` for MMIO register addresses (never `uint32_t` or `unsigned long`) | ERROR |
| TY-2 | Avoid new `typedef` declarations; prefer `struct foo` / `enum foo` directly | WARNING |
| TY-3 | Use `UINT_MAX` (not `ULONG_MAX`) when the variable being compared is `uint32_t` | ERROR |
| TY-4 | Integer literals assigned to unsigned variables carry the `U` suffix (e.g., `1U`) | WARNING |
| TY-5 | No floating-point types (`double`, `float`) in driver/firmware code | ERROR |
| TY-6 | No use of `long` or `unsigned long`; use `long long` / `uint64_t` for 64-bit values | WARNING |
| TY-7 | No implicit boolean conversions from non-boolean expressions (MISRA 14.4) | WARNING |
| TY-8 | Pointer to MMIO or arbitrary address: use `uintptr_t` (see coding-guidelines §pointer types) | ERROR |

### 8. Macros

| ID | Rule | Severity |
|----|------|----------|
| MA-1 | Macros that expand to expressions must not contain undefined behavior (e.g., `__builtin_clz(0)`) | ERROR |
| MA-2 | Bit-field macros (`BIT(n)`) must not skip values without explanation | WARNING |
| MA-3 | Prefer `CASSERT` (from `include/lib/cassert.h`) over project-local compile-time assertion macros | WARNING |
| MA-4 | Do not introduce duplicate functionality already present in TF-A headers | WARNING |

### 9. Variable Declarations

| ID | Rule | Severity |
|----|------|----------|
| VD-1 | Variable declarations must appear at the top of their enclosing block (C90/MISRA rule 8.1) | ERROR |
| VD-2 | No variable declarations inside `else` blocks or `for`/`while` loop bodies | ERROR |
| VD-3 | Variables that are not modified after initialization should be `const` | WARNING |

### 10. Braces and Control Flow

| ID | Rule | Severity |
|----|------|----------|
| BR-1 | All conditional bodies (`if`, `for`, `while`, `do`) must use braces, even single-statement bodies (MISRA 15.6) | ERROR |
| BR-2 | Opening brace on same line as control statement (K&R style); on new line for function definitions | ERROR |
| BR-3 | `switch` `case` labels align with `switch` keyword | WARNING |

### 11. Spacing

| ID | Rule | Severity |
|----|------|----------|
| SP-1 | Single space around arithmetic, assignment, boolean, and comparison operators | ERROR |
| SP-2 | Space between control keyword and opening parenthesis: `if (`, `for (`, `while (` | ERROR |
| SP-3 | No space between function name and opening parenthesis | ERROR |
| SP-4 | Pointer `*` aligns with the variable name, not the type: `uint8_t *foo` | WARNING |
| SP-5 | No space between `*` and function-pointer name in struct definitions | WARNING |

### 12. Error Handling

| ID | Rule | Severity |
|----|------|----------|
| EH-1 | Use `assert()` for programming errors (bad arguments, internal inconsistencies) | WARNING |
| EH-2 | Use `WARN` + recovery for non-critical errors from external sources | WARNING |
| EH-3 | Use `ERROR` + `panic()` for unexpected unrecoverable errors | WARNING |
| EH-4 | Use `ERROR` + `plat_error_handler()` for expected unrecoverable errors | WARNING |
| EH-5 | Do not use `printf`; use `ERROR`, `WARN`, `INFO`, `VERBOSE` macros from `debug.h` | ERROR |

### 13. Makefile

| ID | Rule | Severity |
|----|------|----------|
| MK-1 | Use tabs for indentation, not spaces | ERROR |
| MK-2 | Line continuation `\` must not be followed by trailing spaces | WARNING |
| MK-3 | New source files must be added to the appropriate `_SOURCES` variable | ERROR |

### 14. Build Verification

| ID | Rule | Severity |
|----|------|----------|
| BV-1 | Patch applies cleanly with `git am` (no conflicts, no rejected hunks) | ERROR |
| BV-2 | `git am` produces no whitespace warnings | WARNING |
| BV-3 | `./MAKEALL` completes with no errors for all targets | ERROR |
| BV-4 | `./MAKEALL` produces no new warnings | WARNING |

---

## Review Checklist Workflow

```
For each patch in the series:
  1. [ ] Fetch change from Gerrit (gerrit-review MCP)
  2. [ ] Apply to local review tree (git cherry-pick FETCH_HEAD)
  3. [ ] Apply to build tree (git am), note any whitespace warnings (BV-2)
  4. [ ] Run ./MAKEALL from build root directory (not TFA clone) (BV-3, BV-4)
  5. [ ] Check commit message (CM-1 through CM-8)
  6. [ ] Check each new/modified .h file:
         - Header guard (HG-1, HG-2, HG-3)
         - Include ordering (IN-1 through IN-4)
         - Typedefs (TY-2)
         - Macro definitions (MA-1 through MA-4)
         - Comment style (CO-1, CO-2)
         - Trailing blank line at EOF (WS-5)
  7. [ ] Check each new/modified .c file:
         - Include ordering (IN-1 through IN-4)
         - Variable declarations (VD-1, VD-2)
         - Types (TY-1, TY-3 through TY-8)
         - Comment style (CO-1 through CO-4)
         - Spacing (SP-1 through SP-5)
         - Braces (BR-1, BR-2)
         - Error handling (EH-1 through EH-5)
  8. [ ] Check Makefile changes (MK-1 through MK-3)
  9. [ ] Save the review report as /tmp/<change_id>_ps<N>_review_report.md
         (see Report Format section for required structure)
 10. [ ] Draft review comment and submit via Gerrit
```

## Report format

Save the report to `/tmp/<change_id>_ps<N>_review_report.md`.
Example: `/tmp/45537_ps14_review_report.md`

The markdown file must contain the following sections in order:

### 1. Header

```
# TF-A Patch Review: Change <id> PS<N>

**Subject:** <commit subject line>
**Author:** <name> <<email>>
**Status:** <Gerrit status, e.g. WIP / ACTIVE>
**Reviewed patchset:** <N> (uploaded <date>)
**Change URL:** <https://review.trustedfirmware.org/c/TF-A/trusted-firmware-a/+/<id>>
**Build result:** PASS/FAIL (<details, e.g. "26/26 K3 configs via ./MAKEALL">)
```

### 2. Previous Patchset Review Comment Links

Table of all prior patchsets that received reviewer comments, with direct links and
the PS13→PS14 diff view. Used so the reviewer can quickly navigate to prior context.

```markdown
| Patchset | Reviewer | Comment count | Link |
|----------|----------|---------------|------|
| PS<N> | <reviewer name> | <count> | <https://review.trustedfirmware.org/c/.../+/<id>/<N>> |

Diff view PS<N-1> → PS<N>:
<https://review.trustedfirmware.org/c/.../+/<id>/<N-1>..<N>>
```

### 3. Summary Counts

Two small tables: one for severity breakdown, one for fix-status breakdown.

```markdown
| Severity | Count |     | Status      | Count |
|----------|-------|     |-------------|-------|
| ERROR    | N     |     | FIXED       | N     |
| WARNING  | N     |     | PARTIAL     | N     |
| **Total**| **N** |     | NOT FIXED   | N     |
                         | NEW         | N     |
```

### 4. Consolidated Findings Table

One row per finding. Use a `Notes` column for the description so each finding fits on
one row. Use markdown link syntax `[LNN](url)` in the Link cell.

Column definitions:
- **File**: complete path from the TFA repo root (backtick-quoted)
- **Line**: line number(s) where the issue appears; use `(throughout)` for file-wide issues
- **Rule**: rule ID (e.g. `MA-1`)
- **Sev**: `ERROR` or `WARNING`
- **Preexisting**: `Yes` if raised in a prior patchset review; `No (NEW)` if first seen now
- **Link**: `[LNN](https://review.trustedfirmware.org/c/.../+/<id>/<ps>/<file>@<line>)` — omit `@<line>` for file-level issues
- **Status**: `FIXED`, `PARTIAL`, `NOT FIXED`, or `NEW`
- **Notes**: one-line description of the issue

```markdown
| File | Line | Rule | Sev | Preexisting | Link | Status | Notes |
|------|------|------|-----|-------------|------|--------|-------|
| `drivers/ti/clk/include/ti_clk.h` | 29 | MA-1 | ERROR | Yes | [L29](...@29) | NOT FIXED | `TI_MASK_COVER_FOR_NUMBER`: `__builtin_clz(0)` is UB when `number==0` |
```

### 5. Previous Gerrit Comments Not Addressed

Source: the actual inline Gerrit review comments fetched from the Gerrit API
(`include_comments: true`), from all prior patchsets, from all reviewers.
Do NOT derive this section from your own rule-check findings — only include comments
that a human reviewer explicitly left on the change.

For each prior inline comment, check the current patchset code and record whether the
reviewer's specific request was addressed. The author marking a thread "resolved" in
Gerrit is not evidence of a fix — always verify against the code.

```markdown
## Previous Gerrit Comments Not Addressed

| # | PS | Reviewer | File | Line | Comment Summary | Addressed? |
|---|----|----------|------|------|-----------------|------------|
| 1 | 13 | Nishanth Menon | `ti_clk.h` | 32 | `TI_FREQ_MHZ` uses `double` — no floating-point in firmware | No |
| 2 | 12 | Andrew Davis | `ti_clk_mux.c` | 43 | missing `(uintptr_t)` cast on `reg->reg` | Partial |

**Summary:** N Addressed, N Partial, N Not Addressed out of N prior comments.
Note: all N were marked "resolved" by the author in PS<N>.
```

"Addressed?" = Yes / No / Partial

### 6. Build Verification

```markdown
## Build Verification

| ID | Rule | Result | Notes |
|----|------|--------|-------|
| BV-1 | Patch applies cleanly | PASS/FAIL | |
| BV-2 | No whitespace warnings from `git am` | PASS/FAIL | |
| BV-3 | `./MAKEALL` completes with no errors | PASS/FAIL | <N>/<N> configs pass |
| BV-4 | `./MAKEALL` produces no new warnings | PASS/FAIL | |
```

Include a note if the platform under review is not in MAKEALL's defconfig list (i.e. the
new driver code is not actually compiled by MAKEALL).

---

## Severity Definitions

- **ERROR**: Must be fixed before merging. Would fail CI or violate a hard rule.
- **WARNING**: Should be fixed; reviewer will call it out but may not block merge.

---

## Reference: Issues Found in 45537 (mux driver)

| File | Rule | Finding |
|------|------|---------|
| `ti_clk.h` | TY-5 | `TI_FREQ_MHZ` uses `double` multiplication |
| `ti_clk.h` | MA-1 | `TI_MASK_COVER_FOR_NUMBER` calls `__builtin_clz(0)` (UB when `number == 0`) |
| `ti_clk.h` | CO-2 | Pervasive `/** \brief ... */` Doxygen comment style |
| `ti_clk.h` | MA-2 | `TI_CLK_DATA_FLAG_*` skips `BIT(1)` without comment |
| `ti_clk.h` | HG-2 | `#endif` missing guard comment (`/* TI_CLK_H */`) |
| `ti_clk.h` | NM-4 | Typo "intitialization" in comment |
| `ti_clk_mux.h` | SP-5 | Space before `*` in function pointer: `* (*get_parent)` |
| `ti_clk_mux.h` | CO-2 | Pervasive `/** \brief ... */` Doxygen style |
| `ti_clk_mux.c` | IN-4 | Project headers `<ti_clk_mux.h>`, `<ti_container_of.h>` before `<lib/mmio.h>` |
| `ti_clk_mux.c` | VD-2 | `uint32_t mask` and `uint32_t val` declared inside `else` block |
| `ti_clk_mux.c` | TY-1 | `reg->reg` cast to `(uintptr_t)` at call site; field type should be `uintptr_t` |
| `ti_build_assert.h` | MA-3 | Duplicates `CASSERT` zero-expression form already in TF-A |
| `ti_container_of.h` | WS-5 | Trailing blank line after `#endif` |
| `ti_pm_types.h` | TY-2 | All `ti_*_t` typedefs discouraged |
| `ti_pm_types.h` | CO-2 | `ti_dev_idx_t` has no doc comment |
| `ti_pm_types.h` | HG-2 | `#endif` missing guard comment (`/* TI_PM_TYPES_H */`) |
| commit | CM-4 | Body too brief; no motivation or design rationale |

## Reference: Issues Found in 45538 (div driver)

| File | Rule | Finding |
|------|------|---------|
| `ti_clk_div.h` | TY-1 | `uint32_t reg` in `ti_clk_data_div_reg` / `ti_clk_data_div_reg_go` should be `uintptr_t` |
| `ti_clk_div.h` | CO-2 | Pervasive `/** \brief ... */` Doxygen style |
| `ti_clk_div.c` | IN-4 | `<ti_clk_div.h>`, `<ti_clk_mux.h>` appear before `<lib/mmio.h>` |
| `ti_clk_div.c` | VD-2 | Variable declarations inside `for` loop body in `ti_clk_div_set_freq_dyn_parent` |
| `ti_clk_div.c` | TY-3 | `ULONG_MAX` used in comparison against `uint32_t`; should be `UINT_MAX` |
| `ti_clk_div.c` | TY-7 | `data_div->default_div && drv_div->set_div` — implicit bool conversion |
| `ti_clk_div.c` | TY-4 | `reg_val = 1` missing `U` suffix |
| `ti_clk_div.c` | CO-3 | "Hack" comment in production code |
| `ti_clk.mk` | MK-1 | Mixed tabs/spaces before `\` continuation |
| commit | CM-4 | Body too brief; no motivation or design rationale |

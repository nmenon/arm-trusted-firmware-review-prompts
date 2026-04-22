# TF-A Patch Review Plan

Rules for reviewing TF-A patches. Sources:

- `docs/process/coding-style.rst`
- `docs/process/coding-guidelines.rst`
- `docs/process/commit-style.rst`
- MISRA C:2012 (as referenced by TF-A)
- Observations from `ti-am62l-clk` series (changes 45537, 45538)

Ask user for:
- Path to local arm-trusted-firmware clone (reading files, applying patches)
- Path to build integration tree (separate clone for apply + build)
- Path to build root containing `MAKEALL` (run `./MAKEALL` from there)

---

## Process

For each patch under review:

1. Fetch Gerrit change via `gerrit-review` MCP with `include_comments: true`.
   Retrieves all inline comments from all prior patchsets (author replies included).
   Install from https://playbooks.com/mcp/cayirtepeomer/gerrit-code-review-mcp if missing.
2. Extract every inline Gerrit comment from prior patchsets. For each record:
   - Patchset number
   - Reviewer name
   - File path + line number
   - Comment text (what reviewer asked)
3. Read all changed files on disk (after applying patch locally).
4. For each prior Gerrit comment, check current patchset code — was reviewer's request addressed?
   - Yes — code clearly addresses comment
   - No — issue still present unchanged
   - Partial — code changed but only partly fixes it
   Note: author marking thread "resolved" in Gerrit ≠ fixed. Always verify against code.
5. Check each rule category below for new issues not in prior comments.
6. Apply patch to build integration tree (separate clone). Run `./MAKEALL` from build root
   (dir containing MAKEALL, not TFA clone itself).
7. Summarize findings with Gerrit links for direct commenting.
8. Save report as markdown file (see Report Format section).

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
| IN-5 | No unused `#include` directives — every included header must have at least one identifier (macro, type, function) from it actually used in the file; verify by checking all identifiers in the header against usage in the .c file | WARNING |

### 6. Naming

| ID | Rule | Severity |
|----|------|----------|
| NM-1 | Functions and local variables: `lower_snake_case` | ERROR |
| NM-2 | Preprocessor macros: `UPPER_SNAKE_CASE` | ERROR |
| NM-3 | No abbreviations that obscure meaning | WARNING |
| NM-4 | Typos in identifiers or comments must be corrected | WARNING |
| NM-5 | Platform-specific macros, functions, and types that are not `static` must carry a platform-specific prefix (`ti_`, `TI_`, `k3_`, `K3_`, `am62l_`, `AM62L_` etc.) to avoid future conflicts with TF-A common APIs or standard library names. Generic names like `FIELD_GET`, `FIELD_PREP`, `log2`, `board_init` with no prefix are prohibited at non-static scope. | ERROR |
| NM-6 | Never define identifiers beginning with `__` (double underscore) in platform or driver code; this namespace is reserved for the compiler and C standard library implementation per ISO C11 §7.1.3. | ERROR |
| NM-7 | Before introducing a new platform utility macro or function, search the upstream TF-A tree (`include/`, `lib/`, `drivers/`) for an existing equivalent. Prefer reusing or contributing to a common header over duplicating. Example: `FIELD_GET`/`FIELD_PREP`/`__bf_shf` already exist in `include/drivers/cadence/cdns_nand.h`. | WARNING |

### 7. Types and Portability

| ID | Rule | Severity |
|----|------|----------|
| TY-1 | Use `uintptr_t` for MMIO register addresses (never `uint32_t` or `unsigned long`) | ERROR |
| TY-2 | Avoid new `typedef` declarations; prefer `struct foo` / `enum foo` directly | WARNING |
| TY-3 | Use `UINT_MAX` (not `ULONG_MAX`) when the variable being compared is `uint32_t` | ERROR |
| TY-4 | Integer literals assigned to unsigned variables carry the `U` suffix (e.g., `1U`) | WARNING |
| TY-5 | No floating-point types (`double`, `float`) in driver/firmware code | ERROR |
| TY-6 | No use of `long` or `unsigned long`; use `long long` / `uint64_t` for 64-bit values | WARNING |
| TY-7 | No implicit boolean conversions from non-boolean expressions (MISRA 14.4): pointer comparisons must be explicit `(p != NULL)` not `(p)`; integer comparisons must be explicit `(x != 0U)` not `(x)` | WARNING |
| TY-8 | Pointer to MMIO or arbitrary address: use `uintptr_t` (see coding-guidelines §pointer types) | ERROR |
| TY-9 | Printf format specifiers must match argument type: use `%u` (or `PRIu32` from `<inttypes.h>`) for `uint32_t`, not `%d`; similarly `%lu`/`PRIu64` for `uint64_t`. Mismatched format specifiers are UB and cause compiler warnings. | ERROR |

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
| EH-6 | Before using any variable or parameter as a divisor, guard with `assert(divisor != 0U)` immediately before the division to prevent undefined behavior from divide-by-zero; the divisor guard is a programming-error assertion (not a runtime check) | ERROR |
| EH-7 | Decrement of a reference count or counter must be preceded by an assertion that the count is non-zero (e.g., `assert(__atomic_load_n(&x->ref_count, __ATOMIC_ACQUIRE) > 0U)`); wraparound on underflow silently corrupts state | ERROR |

### 13. Concurrency and Atomic Access

| ID | Rule | Severity |
|----|------|----------|
| CA-1 | Variables accessed via `__atomic_*` operations in any one place must be accessed via `__atomic_load_n()`/`__atomic_store_n()` everywhere — never mix atomic writes with plain (non-atomic) reads of the same variable; inconsistency defeats the memory-ordering guarantee | WARNING |
| CA-2 | Atomic variables must not be read with plain C assignment syntax (e.g., `x = obj->flags`) if they are ever written with an atomic operation elsewhere in the same scope | WARNING |

### 14. Makefile

| ID | Rule | Severity |
|----|------|----------|
| MK-1 | Use tabs for indentation, not spaces | ERROR |
| MK-2 | Line continuation `\` must not be followed by trailing spaces | WARNING |
| MK-3 | New source files must be added to the appropriate `_SOURCES` variable | ERROR |

### 15. Build Verification

| ID | Rule | Severity |
|----|------|----------|
| BV-1 | Patch applies cleanly with `git am` (no conflicts, no rejected hunks) | ERROR |
| BV-2 | `git am` produces no whitespace warnings | WARNING |
| BV-3 | `./MAKEALL` completes with no errors for all targets | ERROR |
| BV-4 | `./MAKEALL` produces no new warnings | WARNING |

### 16. Patch Series Organization

| ID | Rule | Severity |
|----|------|----------|
| PS-1 | Each patch in a series must build cleanly on its own (applied on top of the preceding patch); there must be no forward-compilation dependency where patch N requires a file or symbol introduced only in patch N+1 | ERROR |
| PS-2 | Prefer smaller, focused patches over monolithic ones; each patch should introduce one logical change (new driver, Makefile integration, board config, etc.) | WARNING |
| PS-3 | If patch N adds source files that are not yet wired into a Makefile (because the Makefile change is in patch N+1), document this in the commit message so reviewers know the file is intentionally unreferenced until the next patch | WARNING |

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
         - Unused includes (IN-5): verify every #include is actually used
         - Variable declarations (VD-1, VD-2)
         - Types (TY-1, TY-3 through TY-9)
         - Comment style (CO-1 through CO-4)
         - Spacing (SP-1 through SP-5)
         - Braces (BR-1, BR-2)
         - Error handling (EH-1 through EH-7)
         - Atomic consistency (CA-1, CA-2)
  8. [ ] Check Makefile changes (MK-1 through MK-3)
  8a.[ ] Check patch series atomicity (PS-1): verify each patch builds cleanly without its successors
  9. [ ] Save the review report as /tmp/<change_id>_ps<N>_review_report.md
         (see Report Format section for required structure)
 10. [ ] Draft review comment and submit via Gerrit
```

## Report format

Save to `/tmp/<change_id>_ps<N>_review_report.md`.
Example: `/tmp/45537_ps14_review_report.md`

Required sections in order:

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

Table of prior patchsets with reviewer comments. Include diff view link for quick navigation.

```markdown
| Patchset | Reviewer | Comment count | Link |
|----------|----------|---------------|------|
| PS<N> | <reviewer name> | <count> | <https://review.trustedfirmware.org/c/.../+/<id>/<N>> |

Diff view PS<N-1> → PS<N>:
<https://review.trustedfirmware.org/c/.../+/<id>/<N-1>..<N>>
```

### 3. Summary Counts

Two tables: severity breakdown + fix-status breakdown.

```markdown
| Severity | Count |     | Status      | Count |
|----------|-------|     |-------------|-------|
| ERROR    | N     |     | FIXED       | N     |
| WARNING  | N     |     | PARTIAL     | N     |
| **Total**| **N** |     | NOT FIXED   | N     |
                         | NEW         | N     |
```

### 4. Consolidated Findings Table

One row per finding. Columns:
- **File**: full path from TFA repo root (backtick-quoted)
- **Line**: line number(s); `(throughout)` for file-wide issues
- **Rule**: rule ID (e.g. `MA-1`)
- **Sev**: `ERROR` or `WARNING`
- **Preexisting**: `Yes` if in prior review; `No (NEW)` if first seen
- **Link**: `[LNN](https://review.trustedfirmware.org/c/.../+/<id>/<ps>/<file>@<line>)` — omit `@<line>` for file-level
- **Status**: `FIXED`, `PARTIAL`, `NOT FIXED`, or `NEW`
- **Notes**: one-line description

```markdown
| File | Line | Rule | Sev | Preexisting | Link | Status | Notes |
|------|------|------|-----|-------------|------|--------|-------|
| `drivers/ti/clk/include/ti_clk.h` | 29 | MA-1 | ERROR | Yes | [L29](...@29) | NOT FIXED | `TI_MASK_COVER_FOR_NUMBER`: `__builtin_clz(0)` is UB when `number==0` |
```

### 5. Previous Gerrit Comments Not Addressed

Source: inline Gerrit comments from Gerrit API (`include_comments: true`), all prior patchsets, all reviewers.
Do NOT populate from own rule findings — only human reviewer comments on the change.

For each prior comment, verify in current code whether request was addressed.
Author marking "resolved" in Gerrit ≠ fixed — always check code.

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

Note if platform not in MAKEALL defconfig list (new driver code not actually compiled by MAKEALL).

---

## Severity Definitions

- **ERROR**: Fix before merge. Fails CI or violates hard rule.
- **WARNING**: Should fix; reviewer flags but may not block merge.

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

## Reference: Issues Found in 39036 PS23 (DDR driver) and 39040 PS23 (BL1 support)

| File | Rule | Finding |
|------|------|---------|
| `cps_drv_lpddr4.h` | NM-7 | `CPS_FLD_READ`/`CPS_FLD_WRITE` use `FIELD_GET`/`FIELD_PREP` — identical macros already in `include/drivers/cadence/cdns_nand.h`; include that instead |
| `plat_utils.h` | NM-7 | Entire file is duplicate of `include/drivers/cadence/cdns_nand.h`; remove and reuse existing |
| `plat_utils.h` | NM-6 | `__bf_shf` uses `__` reserved prefix (ISO C11 §7.1.3) |
| `am62l_ddrss.c` | NM-5 | `log2()` shadows stdlib, no platform prefix — rename to `am62l_log2()` |
| `board_config.c` | NM-5 | `board_init()` has no platform prefix — rename to `am62l_board_init()` |
| `cps_drv_lpddr4.h` + `platform.mk` | PS-1 | Series violation: 39036 files cannot compile without `FIELD_GET`/`FIELD_PREP` from 39040 — fix by including `cdns_nand.h` in `cps_drv_lpddr4.h` |
| `am62l_ddrss.c` | EH | PI training status (PI_83) logged but not checked for error bits — silent training failure (Cadence_DDR_PI_User_Guide.pdf p.23 Table 7-1) |
| `am62l_ddrss.c` | EH | `set_main_psc_state()` unbounded polling loops + always returns 0 |
| `am62l_bl1_setup.c` | CO | Non-standard BL1: `bl1_platform_setup()` enters WFI, never returns — TF-A BL2 path dead code; undocumented |
| `plat_utils.h` | EH (SUSPECT) | `__bf_shf(0)` UB if zero mask passed |

## Reference: Issues Found in 45540 PS14 (clock core)

| File | Rule | Finding |
|------|------|---------|
| `ti_clk.c` | IN-2 | System headers not in alphabetical order: `<errno.h>` after `<assert.h>` but before `<limits.h>` and `<stddef.h>` |
| `ti_clk.c` | IN-5 | `<ti_container_of.h>` included but never used (no `container_of` call in file) |
| `ti_clk.c` | TY-7 | `if (p && p->div)` — should be `if ((p != NULL) && (p->div != 0U))` |
| `ti_clk.c` | EH-6 | `UINT32_MAX / div` with no `assert(div != 0U)` — divide-by-zero UB if caller passes zero |
| `ti_clk.c` | VD-1 | Multiple `struct ti_clk *parent` declarations not at top of enclosing block (lines 151, 231, 276, 311, 401) |
| `ti_clk.c` | TY-4 | `if (ret != 0U)` — comparison against `0U` when `ret` is `uint32_t`; also `if (ret)` for non-boolean |
| `ti_clk.c` | TY-9 | `VERBOSE`/`WARN` use `%d` for `uint32_t` arguments; must use `%u` |
| `ti_clk.c` | EH-7 | `__atomic_sub_fetch(&clkp->ref_count, 1U, ...)` with no guard that `ref_count > 0`; double-put wraps `uint8_t` to 255 |
| `ti_clk.c` | CA-1 | `soc_clocks[i].flags` read non-atomically in `ti_clk_init`'s second loop; all other flag accesses use `__atomic_load_n()` |

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

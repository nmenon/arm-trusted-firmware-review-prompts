# TF-A Patch Review Plan

Rules for reviewing TF-A patches. Sources:

- `docs/process/coding-style.rst`
- `docs/process/coding-guidelines.rst`
- `docs/process/commit-style.rst`
- MISRA C:2012 (as referenced by TF-A)
- Pattern analysis of 500 merged `TF-A/trusted-firmware-a` patches (3985 inline reviewer comments mined via Gerrit API)
- https://www.trustedfirmware.org/aipolicy/ (AI-assisted contribution policy)
- Reference patch series: `ti-am62l-clk` (45537, 45538, 45539, 45540), DDR driver (39036 PS23), BL1 support (39040 PS23)

Ask user for:
- Path to local arm-trusted-firmware clone (reading files, applying patches)
- Path to build integration tree (separate clone for apply + build)
- Path to build root containing `MAKEALL` (run `./MAKEALL` from there)

---

## Process

For each patch under review:

1. Fetch Gerrit change via `gerrit-review` MCP with `include_comments: true`.
   Retrieves inline comments from all prior patchsets (author replies included).
   Install: https://playbooks.com/mcp/cayirtepeomer/gerrit-code-review-mcp
2. Extract every inline Gerrit comment from prior patchsets. For each record:
   - Patchset number
   - Reviewer name
   - File path + line number
   - Comment text
3. Read all changed files (after applying patch locally).
4. For each prior Gerrit comment, check current code — addressed?
   - Yes — clearly addressed
   - No — still present
   - Partial — only partly fixed
   Note: "resolved" in Gerrit ≠ fixed. Always verify against code.
5. Check rule categories below for new issues not in prior comments.
6. Apply patch to build integration tree (separate clone). Run `./MAKEALL` from build root
   (dir containing MAKEALL, not TFA clone itself).
7. Summarize findings with Gerrit links.
8. Save report (see Report Format section).
9. Ask: "Submit to Gerrit? (default: NO)" — wait for explicit YES. Never submit autonomously.

---

## Rule Categories

### 1. Commit Message

| ID | Rule | Severity |
|----|------|----------|
| CM-1 | Subject: `<type>(<scope>): <description>` (Conventional Commits) | ERROR |
| CM-2 | Type ∈ `feat fix build ci docs perf refactor revert style test chore` | ERROR |
| CM-3 | Type, scope, description first letter: all lowercase | ERROR |
| CM-4 | Body: *what* + *why* (motivation, impact, alternatives) | WARNING |
| CM-5 | Body: enough context for reviewer unfamiliar with subsystem | WARNING |
| CM-6 | `Signed-off-by:` present; real name + email | ERROR |
| CM-7 | `Change-Id:` present + unique | ERROR |
| CM-8 | Scope in `changelog.yaml`; add entry if missing | WARNING |
| CM-9 | New build options → `docs/getting_started/build-options.rst`. Dependencies → `make_helpers/constraints.mk` with informative `$(error ...)`/`$(warning ...)` | ERROR |

### 2. File Encoding and Whitespace

| ID | Rule | Severity |
|----|------|----------|
| WS-1 | UTF-8 encoding | ERROR |
| WS-2 | LF only (no CRLF) | ERROR |
| WS-3 | Tabs for indentation (8-col), not spaces | ERROR |
| WS-4 | No trailing whitespace | ERROR |
| WS-5 | Exactly one newline at EOF; no trailing blank lines | ERROR |
| WS-6 | ≤80 chars/line (soft; exceed only for readability) | WARNING |
| WS-7 | New `.c` `.h` `.S` `.mk`: first line `/* SPDX-License-Identifier: BSD-3-Clause */`; missing/conflicting = blocker | ERROR |
| WS-8 | Corporate copyright line format: `Copyright (C) YEAR <Company Full Legal Name> - https://<company-url>` (uppercase `C`, full legal entity name, `https://` URL, no trailing slash). YEAR is a single year or range (`YYYY` or `YYYY-YYYY`); new file added in a prior year should carry range through current year (e.g. `2025-2026`); single year acceptable only if creation and current year match. Common wrong variants: lowercase `c`, abbreviated company name, `http://`, trailing `/`, year not updated to reflect current year. | WARNING |

### 3. Comments

| ID | Rule | Severity |
|----|------|----------|
| CO-1 | No `//` comments; `/* ... */` only | ERROR |
| CO-2 | No `/** \brief ... */` Doxygen style; use `/* ... */` | WARNING |
| CO-3 | No `hack`/`fixme`/`workaround` without explanation | WARNING |
| CO-4 | Comments: *why*, not *what* | WARNING |
| CO-5 | Non-trivial `static` helpers: comment explaining purpose + `bool` param semantics when not inferrable from name | WARNING |
| CO-6 | `static inline` in headers: doc comment required, same as exported functions. Trivial one-liner wrappers (single expression, self-evident name) are exempt — same "non-trivial" threshold as CO-5. | WARNING |
| CO-7 | Return type ↔ docs must agree; `uint32_t` return with "true/false" docs = ambiguous → fix type or docs | WARNING |
| CO-8 | Comments must reflect actual intent; don't call intentional behavior "workaround"/"hack"/"bad config" — misleads reviewers | WARNING |

### 4. Header Guards

| ID | Rule | Severity |
|----|------|----------|
| HG-1 | Every header: `#ifndef HEADER_NAME_H` / `#define HEADER_NAME_H` guard | ERROR |
| HG-2 | `#endif` carries matching comment: `#endif /* HEADER_NAME_H */` | WARNING |
| HG-3 | Guard name = filename all-uppercase with underscores | WARNING |

### 5. Include Ordering

| ID | Rule | Severity |
|----|------|----------|
| IN-1 | Three include groups, blank-line separated: (1) system/libc (2) project `<include/...>` (3) platform `<plat/...>`. No blank lines within a group. | ERROR |
| IN-2 | Within each group: alphabetical order | WARNING |
| IN-3 | `<...>` for non-local headers; `"..."` for same-dir | WARNING |
| IN-4 | No project/platform headers before system headers | ERROR |
| IN-5 | No unused `#include`; every header must contribute ≥1 used identifier (macro/type/fn) | WARNING |
| IN-6 | `<cdefs.h>` = TF-A project header (`include/cdefs.h`) → group 2, not group 1. All `include/` tree headers = group 2. | ERROR |

### 6. Naming

| ID | Rule | Severity |
|----|------|----------|
| NM-1 | Functions + local variables: `lower_snake_case` | ERROR |
| NM-2 | Preprocessor macros: `UPPER_SNAKE_CASE` | ERROR |
| NM-3 | No abbreviations that obscure meaning | WARNING |
| NM-4 | Fix typos in identifiers + comments | WARNING |
| NM-5 | Non-`static` platform symbols: platform prefix required (`ti_`, `TI_`, `k3_`, `K3_`, `am62l_`, `AM62L_`, …). Unprefixed names at non-static scope silently shadow TF-A common APIs or stdlib — e.g. `log2` shadows `<math.h>`, `board_init` collides with future TF-A API. Prohibited. | ERROR |
| NM-6 | No `__`-prefixed identifiers in platform/driver code; reserved for compiler + stdlib (ISO C11 §7.1.3) | ERROR |
| NM-7 | Search `include/` `lib/` `drivers/` for equivalent before adding new util macro/fn. Example: `FIELD_GET`/`FIELD_PREP`/`__bf_shf` already in `include/drivers/cadence/cdns_nand.h`. | WARNING |
| NM-8 | TI platform header filenames: `ti_` prefix required for new headers in `drivers/ti/` and `plat/ti/` (e.g. `ti_scmi_clock.h` not `scmi_clock.h`). Unprefixed names in the platform tree collide with upstream TF-A or driver headers. | WARNING |
| NM-9 | CPU feature flags: `ENABLE_FEAT_<FEATURE>` prefix required. Generic `ENABLE_<X>` deprecated. Legacy replacement: one-cycle backward compat via `constraints.mk` deprecation warning. | WARNING |

### 7. Types and Portability

| ID | Rule | Severity |
|----|------|----------|
| TY-1 | `uintptr_t` for MMIO addresses; not `uint32_t` or `unsigned long` | ERROR |
| TY-2 | No new `typedef`; use `struct foo` / `enum foo` directly | WARNING |
| TY-3 | `UINT_MAX` not `ULONG_MAX` when comparing `uint32_t` | ERROR |
| TY-4 | Unsigned integer literals: `U` suffix (e.g. `1U`) | WARNING |
| TY-5 | No `double`/`float` in driver/firmware code | ERROR |
| TY-6 | No `long`/`unsigned long`; use `long long`/`uint64_t` for 64-bit | WARNING |
| TY-7 | No implicit bool conversion (MISRA 14.4): `(p != NULL)` not `(p)`; `(x != 0U)` not `(x)` | WARNING |
| TY-8 | `uintptr_t` for MMIO/arbitrary address pointers (coding-guidelines §pointer types) | ERROR |
| TY-9 | Format specifier must match type: `%u`/`PRIu32` for `uint32_t` (not `%d`); `%lu`/`PRIu64` for `uint64_t`. Mismatch = UB + compiler warning. | ERROR |
| TY-10 | `uint32_t` literals: `U` suffix (`0U`, `1U`), not `UL`. `UL` = 64-bit on AArch64 → implicit width conversion. Exception: `uintptr_t` MMIO macros may use `UL`/`ULL`. | WARNING |
| TY-11 | Bitwise flag ops: `(uint32_t)` casts must be consistent within a function. Mix of cast/no-cast on same field hides truncation bugs. | WARNING |
| TY-12 | `size_t` for `sizeof()` results, element counts, and buffer lengths passed to `memcpy`/`memset`. `uint32_t` truncates on 64-bit for sizes >4 GiB and causes signed/unsigned warnings with stdlib. | WARNING |

### 8. Macros

| ID | Rule | Severity |
|----|------|----------|
| MA-1 | Macro expressions: no UB (e.g. `__builtin_clz(0)` when arg may be 0) | ERROR |
| MA-2 | `BIT(n)` flag macros: no skipped values without comment | WARNING |
| MA-3 | Prefer `CASSERT` (`include/lib/cassert.h`) over local compile-time assert macros | WARNING |
| MA-4 | No duplicate functionality already in TF-A headers | WARNING |
| MA-5 | Use `ARRAY_SIZE()` (`include/lib/utils_def.h`) instead of hardcoded counts: `for (i = 0U; i < ARRAY_SIZE(arr); i++)` | WARNING |
| MA-6 | HW register state literals (e.g. PSC `0U`/`2U`): named macros + TRM section citation required; bare magic numbers prohibited | WARNING |
| MA-7 | `#define FEAT_X 1` + `#ifdef FEAT_X ... #else ...` = permanent dead `#else`. Remove dead block, make flag configurable, or comment that `#else` is a retained reference/stub. Exception: `constraints.mk` backward-compat aliases (per NM-9) may use this pattern transiently during a one-cycle deprecation period — must be removed in the following release. | ERROR |
| MA-8 | Size-critical structs: `CASSERT(sizeof(struct_name) == EXPECTED_BYTES, ...)` required | WARNING |
| MA-9 | No data array definitions in `.h` files. Arrays/structs with initializers (`foo_t table[] = {...}`) must live in `.c` files; headers declare only `extern`. Data definitions in headers cause multiple-definition linker errors if included in more than one TU. | ERROR |

### 9. Variable Declarations

| ID | Rule | Severity |
|----|------|----------|
| VD-1 | Declarations at top of enclosing block (C90/MISRA 8.1) | ERROR |
| VD-2 | No declarations inside `else` or loop bodies | ERROR |
| VD-3 | Unmodified variables: declare `const` | WARNING |
| VD-4 | MISRA 15.5 (single exit) = Advisory; NOT enforced. Early returns OK + preferred for readability. VD-1 still applies regardless of return count. | INFO |
| VD-5 | No unnecessary forward declarations for `static` fns. Reorganize so helpers defined before first use; forward decls in single TU = maintenance burden, no compiler benefit. | WARNING |

### 10. Braces and Control Flow

| ID | Rule | Severity |
|----|------|----------|
| BR-1 | All `if`/`for`/`while`/`do` bodies: braces always, even single-statement (MISRA 15.6) | ERROR |
| BR-2 | Opening brace: same line as control statement (K&R); new line for function definitions | ERROR |
| BR-3 | `case` labels align with `switch` | WARNING |
| BR-4 | `switch` over `enum`: enumerate every value explicitly; no `default:`-only catch-all. Exhaustive cases enable compiler warning on new enum values. If `default:` needed, still list all known values above it. | WARNING |

### 11. Spacing

| ID | Rule | Severity |
|----|------|----------|
| SP-1 | Single space around operators (arithmetic, assignment, bool, comparison) | ERROR |
| SP-2 | Space between keyword + `(`: `if (`, `for (`, `while (` | ERROR |
| SP-3 | No space between function name + `(` | ERROR |
| SP-4 | `*` near variable name, not type: `uint8_t *foo` | WARNING |
| SP-5 | No space: `*` + fn-pointer name in struct | WARNING |
| SP-6 | Multi-line call args: align with opening `(` using spaces (coding-style.html#alignment) | WARNING |
| SP-7 | Single blank line between logically distinct phases within a function (e.g. validation → computation → return). No blank line between every statement; one blank line per phase boundary max. | WARNING |

### 12. Error Handling

| ID | Rule | Severity |
|----|------|----------|
| EH-1 | `assert()` for programming errors (bad args, internal inconsistencies) | WARNING |
| EH-2 | `WARN` + recovery for non-critical external errors | WARNING |
| EH-3 | `ERROR` + `panic()` for unexpected unrecoverable errors | WARNING |
| EH-4 | `ERROR` + `plat_error_handler()` for expected unrecoverable errors | WARNING |
| EH-5 | No `printf`; use `ERROR`/`WARN`/`INFO`/`VERBOSE` from `debug.h` | ERROR |
| EH-6 | Before any division: `assert(divisor != 0U)`. Programming-error assertion, not runtime check. | ERROR |
| EH-7 | Ref count decrement: assert non-zero first (e.g. `assert(__atomic_load_n(&x->ref_count, __ATOMIC_ACQUIRE) > 0U)`). Underflow wraparound silently corrupts state. | ERROR |
| EH-8 | Potentially overflowing `uint64_t` arithmetic: `check_u64_overflow()` (`include/lib/utils_def.h`); `uint32_t`: `check_u32_overflow()`. Ad-hoc `UINT64_MAX`/`SIZE_MAX` comparison without comment = insufficient. | WARNING |
| EH-9 | Int-returning fns must propagate real errors. Always-`return 0` fn → use `void` or document rationale. `if (ret != 0)` after always-0 fn = dead code. Don't swallow timeouts/failures. | WARNING |
| EH-10 | Log levels: `VERBOSE`=debug traces; `INFO`=init milestones; `WARN`=recoverable + fallback; `ERROR`=unrecoverable → `panic()`/`plat_error_handler()`. Wrong level = flagged. | WARNING |
| EH-11 | Check return values of called functions before using output. Unchecked failures silently propagate corrupt state. Exception: functions documented as always-succeeding (`void` or contract-guaranteed `0`). | WARNING |
| EH-12 | Never use `assert()` as a bounds/security check on inputs from untrusted sources (NS shared memory, SCMI agent_id, SCMI pd_id/clock_id, external callers). `assert()` triggers `panic()` in secure world = NS-triggered DoS. Replace with `if (id >= MAX) return ERROR_CODE;`. | ERROR |
| EH-13 | Integer arithmetic used for tolerance/range calculations (e.g. `min = val/10*9`): verify edge cases where truncation causes incorrect results (e.g. `val < 10` → `min=max=0`). Guard against overflow for large values (`val/10*11` overflows `uint64_t`). | WARNING |

### 13. Concurrency and Atomic Access

| ID | Rule | Severity |
|----|------|----------|
| CA-1 | Vars touched by any `__atomic_*` op: use `__atomic_load_n()`/`__atomic_store_n()` everywhere. Never mix atomic write + plain read — defeats memory ordering. | WARNING |
| CA-2 | No plain read (`x = obj->flags`) of vars written atomically elsewhere in scope | WARNING |
| CA-3 | Shared MMIO / inter-CPU communication on multi-core: include ARMv8 memory barriers. Match barrier to hazard: `dsb sy` before/after DMA; `dmb ish` for CPU-to-CPU shared data; `isb` after system register writes. | WARNING |

### 14. Makefile

| ID | Rule | Severity |
|----|------|----------|
| MK-1 | Tabs for indentation, not spaces | ERROR |
| MK-2 | No trailing spaces after `\` continuation | WARNING |
| MK-3 | New source files: add to appropriate `_SOURCES` variable | ERROR |

### 15. Documentation (RST)

| ID | Rule | Severity |
|----|------|----------|
| DOC-1 | New driver under `drivers/`: add/update page in `docs/drivers/` (purpose, usage, platform config) | WARNING |
| DOC-2 | New platform port under `plat/`: add page in `docs/plat/` (platform overview, build instructions, limitations) | WARNING |
| DOC-3 | New/changed build options → `docs/getting_started/build-options.rst` (see also CM-9) | WARNING |
| DOC-4 | `plat_*` hook changes, BL handoff struct changes, shared header API changes → update `docs/porting-guide.rst` | WARNING |

### 16. Build Verification

| ID | Rule | Severity |
|----|------|----------|
| BV-1 | `git am` applies cleanly (no conflicts, no rejected hunks) | ERROR |
| BV-2 | `git am`: no whitespace warnings | WARNING |
| BV-3 | `./MAKEALL`: no errors for all targets | ERROR |
| BV-4 | `./MAKEALL`: no new warnings | WARNING |
| BV-5 | CI style check: no new errors/warnings; no "WARNING: adding a line without newline at end of file". Manual: `git diff HEAD~1..HEAD \| ./scripts/checkpatch.pl --no-tree` | WARNING |

### 17. Patch Series Organization

| ID | Rule | Severity |
|----|------|----------|
| PS-1 | Each patch builds cleanly alone; no forward dependency where N needs symbol from N+1 | ERROR |
| PS-2 | Small, focused patches; one logical change per patch (driver, Makefile, board config, etc.) | WARNING |
| PS-3 | Patch N adds files not yet in Makefile (wired in N+1): note in commit message that file is intentionally unreferenced | WARNING |
| PS-4 | New/modified platform port: update `docs/about/maintainers.rst` with path + code owner. Missing = no `Code-Owner-Review+1` = no merge. | WARNING |
| PS-5 | Series ordering: foundational first — shared headers before consumers; driver core before Makefile; common code before platform-specific. Wrong order forces reviewers to read patches against missing context. | WARNING |

### 18. Correctness and Security

Checks beyond style — verify the code actually does what it claims.

| ID | Rule | Severity |
|----|------|----------|
| CS-1 | `assert()` on inputs from NS world = DoS. Use bounds-check + error return (see EH-12). | ERROR |
| CS-2 | Verify array accesses from external/SCMI inputs are bounds-checked before use (e.g. `pd_id < ARRAY_SIZE(table)`, `scmi_id < clock_table_size`). Out-of-bounds in secure world = privilege escalation. | ERROR |
| CS-3 | Check for signed/unsigned mismatch on error return comparisons: `unsigned int *p; ... if (*p < 0)` is always false — error never detected. | ERROR |
| CS-4 | Check for dead code caused by hardcoded values (e.g. `flags = 0U` with `if (flags & EXCLUSIVE)` never true). Document or remove. | WARNING |
| CS-5 | Initialization ordering: subsystem N must be fully initialized before any caller can invoke it via N's API. If SCMI transport is live but clock ops not yet registered, any SCMI clock request races with uninitialized state. | WARNING |
| CS-6 | Memory region mappings: end address must not exceed last valid register in TRM. Map only what is required; overmapping grants device-mode access to unmapped holes (data abort risk). Cite TRM section and address range. | WARNING |
| CS-7 | `return 0` / `return SCMI_SUCCESS` at function end must be verified: ensure no intermediate `ret = -EIO` path exists that is then silently discarded. Final return must propagate real status. | ERROR |
| CS-8 | For `plat_scmi_*` hooks: verify that all SCMI inputs (agent_id, scmi_id, pd_id, parent_id) are range-checked against actual table sizes before array access. NS caller controls these fields via shared memory. | ERROR |

### 19. AI-Assisted Contributions

Per https://www.trustedfirmware.org/aipolicy/

| ID | Rule | Severity |
|----|------|----------|
| AI-1 | AI-assisted contribution: add `Co-developed-by: <Tool Name>` trailer. Future: may switch to `Assisted-by:`. CI name-mismatch warning on `Co-developed-by:`/`Signed-off-by:` = expected false positive, not an error. | WARNING |
| AI-2 | AI tool license: output use must not conflict with BSD-3-Clause or Open Source Definition. | ERROR |
| AI-3 | AI output with third-party copyrighted material: confirm BSD-3-Clause-compatible license + provide attribution/license info in commit or file. | ERROR |
| AI-4 | Follow employer's AI policy; may be stricter than TF-A's. | WARNING |

---

## Review Checklist Workflow

```
For each patch in the series:
  1. [ ] Fetch change from Gerrit (gerrit-review MCP)
  2. [ ] Apply to local review tree (git cherry-pick FETCH_HEAD)
  3. [ ] Apply to build tree (git am), note any whitespace warnings (BV-2)
  4. [ ] Run `./MAKEALL` from build root (not TFA clone) (BV-3, BV-4)
  4a.[ ] Run checkpatch style check (BV-5)
  5. [ ] Check commit message (CM-1 through CM-9)
  5a.[ ] AI-assisted? Check `Co-developed-by:` trailer (AI-1); verify license compat (AI-2, AI-3)
  6. [ ] Check each new/modified .h file:
         - SPDX license header present (WS-7)
         - Header guard (HG-1, HG-2, HG-3)
         - Include ordering (IN-1 through IN-4, IN-6: <cdefs.h> is group 2)
         - Typedefs (TY-2)
         - Macro definitions (MA-1 through MA-8)
         - Comment style (CO-1, CO-2)
         - Inline function documentation (CO-6, CO-7, CO-8)
         - Trailing blank line at EOF (WS-5)
  7. [ ] Check each new/modified .c file:
         - SPDX license header + corporate copyright format (WS-7, WS-8)
         - Include ordering (IN-1 through IN-4, IN-6: no blank within group)
         - Unused includes (IN-5): verify every `#include` is used
         - Variable declarations (VD-1 through VD-5); early returns OK (VD-4)
         - Types (TY-1, TY-3 through TY-12)
         - Comment style (CO-1 through CO-8)
         - Static helper comments (CO-5)
         - Spacing (SP-1 through SP-7)
         - Braces (BR-1 through BR-4)
         - Error handling (EH-1 through EH-13)
         - Atomic + barrier consistency (CA-1 through CA-3)
         - Correctness/security: bounds on SCMI inputs (CS-1..CS-8)
         - Deep analysis: dead code, silent error drops, init ordering (CS-4..CS-7)
  8. [ ] Check Makefile changes (MK-1 through MK-3)
  8a.[ ] Check patch series atomicity (PS-1): verify each patch builds cleanly without its successors
  8b.[ ] New platform port? Check maintainers.rst + docs/plat/ updated (PS-4, PS-5, DOC-2)
  8c.[ ] New driver? Check docs/drivers/ updated (DOC-1)
  8d.[ ] API/porting-guide changes? Check docs/porting-guide.rst updated (DOC-4)
  9. [ ] Save report: `/tmp/<change_id>_ps<N>_review_report.md`
 10. [ ] Present report to user
 11. [ ] Ask: "Submit to Gerrit? (default: NO)" — wait for explicit YES. Never submit autonomously.
```

## Report format

Save to `/tmp/<change_id>_ps<N>_review_report.md`.
Example: `/tmp/45537_ps14_review_report.md`

Sections in order:

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

Prior patchsets with reviewer comments + diff view link.

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
- **File**: full path from TFA root (backtick-quoted). Use `commit` for commit message.
- **Line**: line number(s) as clickable Gerrit links using format:
  - Regular file: `[LINE](https://review.trustedfirmware.org/c/TF-A/trusted-firmware-a/+/<id>/<ps>/<filepath>@<line>)`
  - Commit message: `[LINE](https://review.trustedfirmware.org/c/TF-A/trusted-firmware-a/+/<id>/<ps>//COMMIT_MSG@<line>)` (double-slash before COMMIT_MSG is correct Gerrit format)
  - `(throughout)` for file-wide issues with no specific line
- **Rule**: rule ID (e.g. `MA-1`)
- **Sev**: `ERROR` or `WARNING`
- **Preexisting**: `Yes` if prior review; `No (NEW)` if first seen
- **Link**: `[LNN](https://review.trustedfirmware.org/c/.../+/<id>/<ps>/<file>@<line>)` — omit `@<line>` for file-level
- **Status**: `FIXED`, `PARTIAL`, `NOT FIXED`, or `NEW`
- **Notes**: one-line description

```markdown
| File | Line | Rule | Sev | Preexisting | Link | Status | Notes |
|------|------|------|-----|-------------|------|--------|-------|
| `drivers/ti/clk/include/ti_clk.h` | 29 | MA-1 | ERROR | Yes | [L29](...@29) | NOT FIXED | `TI_MASK_COVER_FOR_NUMBER`: `__builtin_clz(0)` is UB when `number==0` |
```

### 5. Previous Gerrit Comments Not Addressed

Source: Gerrit API (`include_comments: true`), all patchsets, all reviewers.
Don't populate from own findings — only comments left by human reviewers.

For each, verify in current code whether addressed.
"Resolved" in Gerrit ≠ fixed — always check code.

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

Note if platform not in MAKEALL defconfig list (driver not compiled by MAKEALL).

### 7. Agentic Independent Review (optional but recommended)

Use an independent agentic review (e.g. a second Claude session, a separate AI review environment, or another LLM) to independently verify key findings via voting/consensus. Report accuracy of each agentic finding vs manual analysis. Note any false positives or false negatives.

### 8. Deep Correctness and Security Analysis

For each changed function, check:
- All error paths propagate `ret` correctly — no `return 0` silently discarding `-EIO`
- SCMI inputs (`agent_id`, `pd_id`, `scmi_id`) bounds-checked before array access
- No `assert()` on NS-controlled inputs (DoS risk)
- Signed/unsigned mismatch on error return checks (`if (*unsigned_ptr < 0)` = always false)
- Integer overflow in tolerance/range arithmetic
- No dead code from hardcoded variables (`flags = 0U`)
- Initialization ordering: APIs not callable before subsystem is ready
- Memory map regions don't exceed last valid register (cite TRM)

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

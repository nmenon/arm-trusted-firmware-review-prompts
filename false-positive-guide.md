# TF-A Review False-Positive Verification Guide

Apply these checks to any suspected finding before including it in a review.
A finding that fails any gate should be dropped or downgraded.

## General Gates

### G1: Is the code actually in the diff?
- Only flag code that the patch introduced or modified.
- Pre-existing code in context lines is NOT the author's responsibility in
  this review (it may be worth a separate comment, but label it clearly).

### G2: Is the path reachable?
- Verify the changed code path can actually execute under the patch's
  stated use case.
- Check `#ifdef` / `IS_ENABLED()` guards, Makefile `SOURCES` inclusion,
  and `CONFIG_` guards in `.mk` files.
- If the code is never compiled or never called, do not report a bug.

### G3: Read the full function, not just the hunk
- Always expand context to the entire function before reporting.
- A check that looks missing in a hunk may exist earlier in the function.
- A type that looks wrong in a hunk may be correct given its declaration.

### G4: Platform vs. upstream scope
- Platform-local `static` functions do not need a platform prefix (NM-5).
  NM-5 applies only to non-`static` symbols at external linkage.
- `static inline` helpers in a `.c` file that are not in a header are
  platform-internal; the comment requirement (CO-6) applies to headers only
  for such helpers.

---

## Rule-Specific Notes

### Comments (CO-*)
- **CO-1 (`//` comments)**: Compiler-generated or tool-output lines in `.S`
  files may use `//`; this is intentional. Only flag hand-written C/header
  source.
- **CO-5 / CO-6 (static helper comments)**: One-liner wrappers whose name
  and argument types make their purpose self-evident are exempt. The test is
  whether a reviewer unfamiliar with the subsystem would need a comment.

### Types (TY-*)
- **TY-7 (implicit bool)**: Legacy TF-A code is full of `if (ptr)` and
  `if (val)`. Only flag instances introduced or modified by the current patch.
- **TY-2 (no typedef)**: Do not retroactively flag existing `typedef`s that
  the patch merely uses (e.g. PSCI or SMC type aliases). Only flag new
  `typedef` declarations added by the patch.
- **TY-10 (U vs UL suffix)**: `uintptr_t` MMIO macros may legitimately use
  `UL` or `ULL`. Only flag `uint32_t` literals missing the `U` suffix.

### Macros (MA-*)
- **MA-1 (`__builtin_clz(0)`)**: Only UB when the argument can actually be
  zero. If the caller site always guarantees a non-zero argument, this is a
  false positive — document the guarantee and drop the finding.
- **MA-7 (permanent dead `#else`)**: Exempt if the `#else` block contains a
  `#error` or `static_assert` that would trigger on bad config — that is
  deliberate defensive coding, not dead code.

### Error Handling (EH-*)
- **EH-9 (always returns 0)**: Confirm the function truly always returns 0
  by reading its full body, not just the return statement in the hunk. A
  function with early `return -EINVAL` that the diff did not touch is NOT
  "always 0".
- **EH-12 (`assert()` on NS inputs)**: Only applicable to paths reachable
  from NS world (SCMI handlers, SiP SMC handlers, shared-memory reads).
  An `assert()` inside a `static` init function called only during BL31
  platform setup is not a DoS risk.

### Correctness / Security (CS-*)
- **CS-1 / CS-8 (SCMI bounds)**: Confirm the input is actually NS-supplied.
  Internal callers with compile-time constant arguments are not a risk.
- **CS-9 (unsigned subtraction)**: Only flag if the result is written to an
  output buffer or used as a subsequent array index with a value that would
  be incorrect on underflow. If the result is only used in a comparison that
  is then handled by a branch, and the branch covers the underflow case, this
  is a false positive.
- **CS-12 (firewall reconfig)**: Permissive firewall configurations during
  early BL31 init are expected and intentional. Verify the call site is
  `ti_soc_init()` or an equivalent early-init hook, not reachable after NS
  world launches. If confined to early init, this is a false positive for
  CS-12 — but still worth an INFO comment if the permissive range is wide.
- **CS-13 (SMC dispatcher)**: Check whether the `default:` case truly returns
  `SMC_UNK`. A `default: break;` that falls through to a post-switch
  `SMC_RET1(handle, SMC_UNK)` is equivalent and not a bug.

### Build / Whitespace (BV-*, WS-*)
- **BV-4 (new warnings)**: Run the same toolchain as CI. Warnings from a
  newer GCC on the host that CI does not use are informational only — label
  them as such and do not mark them ERROR.
- **WS-6 (line length)**: Long lines in `#define` macros or string literals
  that cannot be wrapped without reducing readability are acceptable. Only
  flag if the line can be wrapped cleanly.

### Naming (NM-*)
- **NM-7 (duplicate utility)**: Before flagging, confirm the existing macro
  has an identical semantic contract (same argument types, same truncation
  behavior). Near-duplicates with different edge-case semantics are NOT
  flagged by NM-7.

---

## Cross-check Pattern

For every finding still standing after the gates above:

1. **Read the full function** — expand past the hunk.
2. **Trace the call chain one level up** — does the caller already sanitize
   the input, making the check redundant?
3. **Check if it was flagged in a prior patchset** — if the author replied
   "intentional" or "WONTFIX" in Gerrit and the behavior is unchanged,
   label the finding as PREEXISTING/NOT FIXED rather than NEW.
4. **Confirm with a code snippet** — every reported bug must include a
   concrete code path showing how the bug manifests. If you cannot write
   that snippet, drop the finding.

# TF-A Patch Review Protocol

You are performing a deep review of a TF-A Gerrit change.
This is not a casual skim — it is exhaustive, systematic analysis of
every change introduced by the patch and every prior review comment.

Load `tfa-review-plan.md` immediately. It contains the rule catalog
(CM-*, WS-*, CO-*, TY-*, CS-*, etc.) and the report format.
Every finding below must cite a rule ID from that file.

## Analysis Philosophy

This analysis assumes the patch has bugs, including in its comments
and commit message. Every change, assertion, and comment must be
proven correct — otherwise flag it as a finding.

- New APIs are checked for consistency and ease of use.
- Any deviation from TF-A coding style is reported as a finding.
- "resolved" in Gerrit ≠ fixed. Always verify in code.

## FILE LOADING

1. Load `tfa-review-plan.md` before doing anything else.
2. Load `false-positive-guide.md` before writing the final report.

## EXCLUSIONS

- Do not flag pre-existing issues in unchanged context lines unless
  the patch makes them actively worse (e.g. by adding a caller).
- Do not report issues in files the patch does not touch.

---

## Task 0: Setup and Context Management

1. Resolve the Gerrit change to review:
   - If a change ID or URL was given, use it.
   - Otherwise ask the user.

2. Fetch the change:
   ```
   fetch_gerrit_change(change_id, include_comments=True)
   ```
   Record:
   - Change ID, subject, author, current patchset number, status
   - All inline comments from all prior patchsets:
     patchset, reviewer, file path, line number, comment text

3. Identify the local TF-A tree:
   - Ask if not already known from session context.

4. Ask the user for build configuration (do this before any analysis):

   > "What build command(s) should I run to verify this patch?
   >  Examples:
   >    make PLAT=k3 BUILD_BASE=/tmp/build  (single platform)
   >    ./MAKEALL  (TI all-platform script)
   >    make PLAT=fvp  (Arm reference platform)
   >    skip  (no local build available)
   >  Please also give the working directory for the build command."

   Record:
   - `BUILD_CMD`    — the command(s) to run, exactly as typed
   - `BUILD_DIR`    — working directory (may differ from TF-A clone root)
   - `BUILD_LOG`    — `/tmp/build_<change_id>.log`  (auto-assigned)

   If the user says "skip" or has no local tree, set `BUILD_CMD=SKIP` and
   mark BV-3/BV-4 as SKIPPED for the rest of the review.

5. Plan the analysis — before making additional tool calls:
   - Read the full diff line-by-line.
   - Understand the commit's purpose from the message.
   - Note every file changed and the nature of each change.
   - Do NOT jump to analysis yet.

6. Output:
   ```
   CHANGE: <id>  PATCHSET: <N>  AUTHOR: <name>
   SUBJECT: <subject>
   STATUS: <Gerrit status>
   PRIOR COMMENTS: <count> across <N> patchsets
   FILES CHANGED: <list>
   BUILD_CMD: <command or SKIP>
   BUILD_DIR: <path>
   ```

---

## Task 1: Change Categorization

NOTE: Do not begin rule analysis until Task 1 is complete.
Gather context first, categorize second, analyze third.

### 1A: Launch build in background (FIRST step of Task 1)

Apply the patch and start the user's build command in the background
**before** reading files. The build runs in parallel with Tasks 1-6
and its results are collected in Task 8.

If `BUILD_CMD=SKIP` (set in Task 0), skip this entire step.

```bash
# Step 1: apply patch (fast, sequential — must complete before build starts)
cd <tfa_clone>
git am FETCH_HEAD
# Capture any whitespace warnings from git am (BV-2)
# Save output to /tmp/gitam_<change_id>.log

# Step 2: launch user's build command in background — do NOT wait for it
cd <BUILD_DIR>
<BUILD_CMD> 2>&1 | tee <BUILD_LOG>
# (use run_in_background: true so Task 1B continues immediately)
```

Also launch checkpatch in background:
```bash
git -C <tfa_clone> diff HEAD~1..HEAD | \
    ./scripts/checkpatch.pl --no-tree 2>&1 | tee /tmp/checkpatch_<change_id>.log
# (use run_in_background: true)
```

Record the background task IDs so Task 8 can wait on them.

Output:
```
BUILD: launched in background (task <id>) — cmd: <BUILD_CMD>
CHECKPATCH: launched in background (task <id>)
```
or
```
BUILD: SKIPPED (user elected to skip build verification)
```

### 1B: Read all changed files

For each file in the diff:
- Read the full file (not just the hunk) from the local TF-A tree.
- Use the `Read` tool on the actual file path.
- For deleted functions, note that they no longer exist.

### 1C: Categorize changes

Break the diff into fine-grained CHANGE categories.
Create one category per:
- Each modified function
- Each control-flow change (one per loop, one per changed return/break)
- Each resource allocation or free
- Each new or removed `#include`
- Each new macro, type, or struct
- Each Makefile or build-option change

Add all categories to TodoWrite as CHANGE-1, CHANGE-2, ...

### 1D: Print categories

Output each category:
```
CHANGE-N: <short description>  [<file>:<line>]
```

Example:
```
CHANGE-1: new function ti_clk_div_set_freq_dyn_parent  [ti_clk_div.c:145]
CHANGE-2: return path in ti_clk_div_set_freq — added early return on error  [ti_clk_div.c:87]
CHANGE-3: new struct ti_clk_data_div_reg in header  [ti_clk_div.h:23]
CHANGE-4: added ti_clk_div.c to SOURCES in Makefile  [ti_clk.mk:12]
```

---

## Task 2: Reachability Gate

**Mandatory before rule analysis.**

For each CHANGE category:
- Is the changed code compiled for the stated platform?
  Check `platform.mk`, `Makefile`, `$(SOURCES)` variables.
- Is the changed function reachable from any call site?
  Grep for callers in the TF-A tree.
- Are any `#ifdef` / `$(filter ...)` guards preventing execution?

Output:
```
REACHABILITY: confirmed — all changes reachable
```
or
```
REACHABILITY: CHANGE-N blocked — <reason>; skip rule analysis for this change
```

---

## Task 3: Prior Gerrit Comment Verification

For each inline comment from prior patchsets (collected in Task 0):

1. Find the corresponding code location in the current patchset.
2. Determine whether the comment was addressed:
   - **FIXED**: the issue is gone
   - **PARTIAL**: partially addressed but still present
   - **NOT FIXED**: unchanged; author may have marked "resolved" in Gerrit but code is the same
3. Record in a table: `PS | Reviewer | File | Line | Summary | Status`

Output a running tally:
```
PRIOR COMMENTS: N FIXED, N PARTIAL, N NOT FIXED out of N total
```

---

## Task 4: Rule Analysis

For each CHANGE category (Task 1B), apply the rule categories from
`tfa-review-plan.md` in order.

Work through the checklist from `tfa-review-plan.md` §Review Checklist Workflow:
- Commit message rules (CM-*)
- File encoding / whitespace (WS-*)
- Comments (CO-*)
- Header guards (HG-*)
- Include ordering (IN-*)
- Naming (NM-*)
- Types and portability (TY-*)
- Macros (MA-*)
- Variable declarations (VD-*)
- Braces and control flow (BR-*)
- Spacing (SP-*)
- Error handling (EH-*)
- Concurrency and atomic access (CA-*)
- Makefile (MK-*)
- Documentation (DOC-*)
- Patch series organization (PS-*)
- Correctness and security (CS-*)
- AI-assisted contributions (AI-*)

For every finding, record:
- File, line number (as Gerrit link), rule ID, severity (ERROR/WARNING),
  whether it was flagged in a prior patchset (PREEXISTING vs NEW),
  one-line description.

### Mandatory deep checks (CS-* rules)

For every changed function, verify:
1. All error paths propagate `ret` — no silent `return 0` discarding `-EIO`
2. SCMI inputs (`agent_id`, `pd_id`, `scmi_id`) bounds-checked before array access
3. No `assert()` on NS-controlled inputs (DoS risk — CS-1, EH-12)
4. No signed/unsigned mismatch on error comparisons (`if (*unsigned < 0)` = always false — CS-3)
5. Unsigned subtraction used as derived index: guard `a >= b` before `a - b` (CS-9)
6. Narrowing cast on `BASE + offset`: `CASSERT` or runtime upper-bound check (CS-10)
7. IPC checksum stubs: flag security-critical callers (CS-11)
8. Hardware protection unit reconfig: init-path-only, args not NS-derived (CS-12)
9. SMC dispatcher: every `case` ends with `SMC_RET*`; `default:` returns `SMC_UNK` (CS-13)

---

## Task 5: False-Positive Verification

Load `false-positive-guide.md`.

For every finding from Task 4:
- Apply each gate in the guide.
- Drop findings that fail a gate; note which gate eliminated them.
- Downgrade findings where appropriate (ERROR → WARNING).

Output after verification:
```
FALSE POSITIVES ELIMINATED: N
  - CHANGE-N <rule>: <gate that eliminated it>
FINDINGS CONFIRMED: N
```

---

## Task 6: Report (preliminary — build result PENDING)

Load `tfa-review-plan.md` §Report format.

Save the report to `/tmp/<change_id>_ps<N>_review_report.md`.

The report must contain all sections from the plan's report format:
1. Header (change ID, author, status, build result — write `BUILD: PENDING`)
2. Previous patchset review comment links
3. Summary counts (severity + fix-status tables)
4. Consolidated findings table (file, line as Gerrit link, rule, sev, preexisting, status, notes)
5. Previous Gerrit comments not addressed
6. Build verification — write `PENDING: see Task 9` as placeholder
7. Deep correctness and security analysis

---

## Task 7: Metadata JSON (preliminary)

Create `./review-metadata.json` in the current working directory.
Set `"build_status": "pending"` — Task 9 will update it.

CRITICAL: This exact format, no extra fields.

```json
{
  "change_id": "<Gerrit change number>",
  "patchset": <N>,
  "author": "<string>",
  "subject": "<string>",
  "issues_found": <number>,
  "issue_severity_score": "<none|low|medium|high|urgent>",
  "issue_severity_explanation": "<one sentence>",
  "build_status": "pending"
}
```

Severity scale:
- **none**: no findings
- **low**: style/warning-only; safe to merge
- **medium**: errors that should be fixed but do not affect safety/security
- **high**: potential runtime failures, incorrect behavior visible to callers
- **urgent**: security vulnerability, NS-to-S escalation, system crash/panic risk

---

## Task 8: Collect Build Results

Wait for the background build and checkpatch tasks launched in Task 1A
to complete, then evaluate their output.

If the build was SKIPPED in Task 1A, mark all BV checks as SKIPPED and
proceed to Task 9.

### 8A: Evaluate git am (BV-1, BV-2)

Read `/tmp/gitam_<change_id>.log`:
- **BV-1**: Did `git am` apply cleanly? (no rejected hunks)
- **BV-2**: Did `git am` emit any whitespace warnings?

### 8B: Evaluate build command (BV-3, BV-4)

Read `<BUILD_LOG>` (the log path recorded in Task 0):
- **BV-3**: Did `<BUILD_CMD>` complete with zero errors?
  - PASS / FAIL (list any error lines or failing targets)
- **BV-4**: Any new warnings vs. the parent commit?
  - Compare with a baseline run on `HEAD~1` if available; otherwise flag
    any warning lines that reference files changed by this patch.

### 8C: Evaluate checkpatch (BV-5)

Read `/tmp/checkpatch_<change_id>.log`:
- **BV-5**: Any new checkpatch ERRORs or WARNINGs?

### 8D: Build summary output

```
BV-1 (applies cleanly):      PASS / FAIL
BV-2 (no whitespace warns):  PASS / FAIL
BV-3 (build no errors):      PASS / FAIL / SKIPPED  [cmd: <BUILD_CMD>]
BV-4 (no new warnings):      PASS / FAIL / SKIPPED
BV-5 (checkpatch clean):     PASS / FAIL
```

---

## Task 9: Finalize Report and Metadata

Update the report and metadata with the build results from Task 8.

### 9A: Update report

Open `/tmp/<change_id>_ps<N>_review_report.md` and:
1. Replace `BUILD: PENDING` in the header with `BUILD: PASS` or `BUILD: FAIL`
2. Replace the `PENDING: see Task 9` placeholder in section 6 with the
   full BV table from Task 8D
3. Add any build findings (BV-3/BV-4/BV-5 failures) as new rows in the
   consolidated findings table (section 4) with severity ERROR or WARNING
4. Update the summary counts table (section 3) to include build findings

### 9B: Update metadata

Rewrite `./review-metadata.json`:
- Set `"build_status"` to `"pass"`, `"fail"`, or `"skipped"`
- If build failures were found, re-evaluate `"issue_severity_score"`:
  a build error (BV-3 FAIL) is at minimum **medium**; adjust upward
  if the failure is in a safety or security path
- Update `"issues_found"` to include build findings

CRITICAL: Same format as Task 7, now with `build_status` populated.

```json
{
  "change_id": "<Gerrit change number>",
  "patchset": <N>,
  "author": "<string>",
  "subject": "<string>",
  "issues_found": <number>,
  "issue_severity_score": "<none|low|medium|high|urgent>",
  "issue_severity_explanation": "<one sentence>",
  "build_status": "<pass|fail|skipped>"
}
```

---

## Mandatory Final Output

Always conclude with:
```
FINAL FINDINGS: <N errors, N warnings>
FINAL SEVERITY: <none|low|medium|high|urgent>
BUILD: <pass|fail|skipped>
REPORT: /tmp/<change_id>_ps<N>_review_report.md
```

Then ask:
```
Submit review to Gerrit? (default: NO)
```

Never submit without explicit YES from the user.

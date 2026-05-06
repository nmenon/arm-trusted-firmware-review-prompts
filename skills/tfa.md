---
name: tfa
description: Load anytime the working directory is an arm-trusted-firmware (TF-A) tree, and always load it when answering questions inside the TF-A tree. TF-A knowledge, subsystem-specific details, analysis, review, and debugging protocols.
invocation_policy: automatic
---

## ALWAYS READ
1. Load `{{TFA_REVIEW_PROMPTS_DIR}}/tfa-review-plan.md`

You consistently skip reading additional prompt files. These files are
MANDATORY. This skill exists as a framework for loading additional TF-A
review prompts.

## File Relationships

- `review-core.md` — **execution protocol** (Tasks 0-8, how to run the review)
- `tfa-review-plan.md` — **rules catalog** (CM-*, WS-*, CS-* rule tables, report format)
- `false-positive-guide.md` — **verification gates** (eliminate false positives before reporting)

## Configuration

The review prompts directory is configured during installation:
- **TFA_REVIEW_PROMPTS_DIR**: {{TFA_REVIEW_PROMPTS_DIR}}

## Capabilities

### Patch Review
When asked to review a TF-A patch, Gerrit change, or series of changes:
1. Load `{{TFA_REVIEW_PROMPTS_DIR}}/review-core.md`
2. Follow the complete protocol defined there (Tasks 0-8)
3. `review-core.md` will direct you to load `tfa-review-plan.md` for rules

### False-Positive Verification
When a finding looks suspect or the user wants to verify:
1. Load `{{TFA_REVIEW_PROMPTS_DIR}}/false-positive-guide.md`
2. Apply each verification check systematically

### Gerrit Submission
Never submit a review to Gerrit autonomously. Always:
1. Present the full report to the user first
2. Ask: "Submit to Gerrit? (default: NO)"
3. Wait for explicit YES before calling `submit_gerrit_review`

## Key Facts

- TF-A uses **Gerrit** at https://review.trustedfirmware.org, not GitHub PRs
- Coding style: tabs (8-col), K&R braces, C89/C90 declarations at block top
- Comment style: `/* ... */` only; no `//`; no Doxygen `/** \brief */`
- MMIO addresses: `uintptr_t`, never `uint32_t`
- No `typedef`; no `double`/`float` in firmware code
- Build: `./MAKEALL` from the build-root directory (not the TF-A clone)
- `assert()` on NS-controlled inputs is a DoS — use bounds-check + error return
- MISRA C:2012 advisory rules are referenced but not mechanically enforced
- Platform symbol namespace: `ti_`, `TI_`, `k3_`, `K3_`, `am62l_`, `AM62L_`

## Output

- Patch reviews produce a markdown report saved to
  `/tmp/<change_id>_ps<N>_review_report.md`
- Reports are formatted for Gerrit inline comments (plain text preferred)
- Never submit to Gerrit without explicit user confirmation

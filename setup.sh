#!/bin/bash
#
# Setup script for arm-trusted-firmware review prompts.
#
# Installs the TF-A skill and slash commands for Claude Code.
#
# Usage: ./setup.sh
#
# Installs:
#   ~/.claude/skills/tfa/SKILL.md     - auto-loaded when in a TF-A tree
#   ~/.claude/commands/tfa-review.md  - /tfa-review slash command
#   ~/.claude/commands/tfa-verify.md  - /tfa-verify slash command

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILL_DIR="$HOME/.claude/skills/tfa"
COMMANDS_DIR="$HOME/.claude/commands"

echo "TF-A review prompts directory: $SCRIPT_DIR"
echo ""

# Install skill
mkdir -p "$SKILL_DIR"
sed "s|{{TFA_REVIEW_PROMPTS_DIR}}|$SCRIPT_DIR|g" \
    "$SCRIPT_DIR/skills/tfa.md" > "$SKILL_DIR/SKILL.md"
echo "Installed skill:"
echo "  $SKILL_DIR/SKILL.md"

# Install slash commands
mkdir -p "$COMMANDS_DIR"
echo ""
echo "Installed slash commands:"
for cmd_file in "$SCRIPT_DIR/slash-commands"/*.md; do
    if [ -f "$cmd_file" ]; then
        cmd_name=$(basename "$cmd_file")
        sed "s|{{REVIEW_DIR}}|$SCRIPT_DIR|g" "$cmd_file" > "$COMMANDS_DIR/$cmd_name"
        echo "  /${cmd_name%.md}"
    fi
done

echo ""
echo "Setup complete!"
echo ""
echo "The tfa skill loads automatically in TF-A trees."
echo "Use /tfa-review <change_id> to review a Gerrit change."
echo "Use /tfa-verify to check current findings for false positives."

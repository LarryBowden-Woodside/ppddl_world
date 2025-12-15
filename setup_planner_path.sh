#!/bin/bash
# Quick script to set PPDDL_PLANNER_CMD without interactive prompts

# Check for binary in expected location
if [ -f "./probabilistic-ff-install/probabilistic-ff/ff" ]; then
    BINARY_PATH="$(pwd)/probabilistic-ff-install/probabilistic-ff/ff"
elif [ -f "./probabilistic-ff-install/probabilistic-ff/probabilistic-ff" ]; then
    BINARY_PATH="$(pwd)/probabilistic-ff-install/probabilistic-ff/probabilistic-ff"
elif [ -n "$1" ] && [ -f "$1" ]; then
    BINARY_PATH="$1"
else
    echo "Error: probabilistic-ff binary not found"
    echo "Usage: $0 [path-to-probabilistic-ff]"
    echo "Or compile it first: cd probabilistic-ff-install/probabilistic-ff && make"
    exit 1
fi

export PPDDL_PLANNER_CMD="$BINARY_PATH -o {domain} -f {problem}"
echo "✓ Set PPDDL_PLANNER_CMD to: $PPDDL_PLANNER_CMD"

# Add to shell config
SHELL_RC=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ]; then
    sed -i '/PPDDL_PLANNER_CMD/d' "$SHELL_RC"
    echo "" >> "$SHELL_RC"
    echo "# PPDDL Planner Configuration" >> "$SHELL_RC"
    echo "export PPDDL_PLANNER_CMD=\"$BINARY_PATH -o {domain} -f {problem}\"" >> "$SHELL_RC"
    echo "✓ Added to $SHELL_RC"
fi

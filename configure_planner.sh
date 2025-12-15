#!/bin/bash
# Quick configuration script for probabilistic-ff planner

set -e

echo "=========================================="
echo "Configure PPDDL Planner (probabilistic-ff)"
echo "=========================================="
echo ""

# Check if probabilistic-ff is available
PROBABILISTIC_FF_PATH=""

# Check common locations
if [ -f "./probabilistic-ff-install/probabilistic-ff/ff" ]; then
    PROBABILISTIC_FF_PATH="$(pwd)/probabilistic-ff-install/probabilistic-ff/ff"
    echo "✓ Found probabilistic-ff in ./probabilistic-ff-install/probabilistic-ff/ff"
elif [ -f "./probabilistic-ff-install/probabilistic-ff/probabilistic-ff" ]; then
    PROBABILISTIC_FF_PATH="$(pwd)/probabilistic-ff-install/probabilistic-ff/probabilistic-ff"
    echo "✓ Found probabilistic-ff in ./probabilistic-ff-install/probabilistic-ff/probabilistic-ff"
elif command -v probabilistic-ff &> /dev/null; then
    PROBABILISTIC_FF_PATH="probabilistic-ff"
    echo "✓ probabilistic-ff found in PATH"
elif [ -f "../probabilistic-ff/probabilistic-ff" ]; then
    PROBABILISTIC_FF_PATH="$(cd .. && pwd)/probabilistic-ff/probabilistic-ff"
    echo "✓ Found probabilistic-ff in ../probabilistic-ff/"
else
    echo "✗ probabilistic-ff not found"
    echo ""
    echo "The binary hasn't been compiled yet. To complete compilation:"
    echo "  1. Install dependencies: sudo apt-get install flex bison"
    echo "  2. Compile: cd probabilistic-ff-install/probabilistic-ff && make"
    echo ""
    echo "Or if you have probabilistic-ff elsewhere, set it via environment variable:"
    echo "  export PROBABILISTIC_FF_PATH=\"/path/to/probabilistic-ff\""
    echo "  ./configure_planner.sh"
    echo ""
    
    # Check for environment variable
    if [ -n "$PROBABILISTIC_FF_PATH" ] && [ -f "$PROBABILISTIC_FF_PATH" ]; then
        echo "✓ Using PROBABILISTIC_FF_PATH: $PROBABILISTIC_FF_PATH"
        # PROBABILISTIC_FF_PATH is already set, continue
    else
        echo "Skipping configuration. To set manually:"
        echo "  export PPDDL_PLANNER_CMD=\"<path-to-probabilistic-ff> -o {domain} -f {problem}\""
        exit 1
    fi
fi

# Use environment variable if set
if [ -n "$PROBABILISTIC_FF_PATH" ]; then
    # Already set from environment variable
    :
elif [ -z "$PROBABILISTIC_FF_PATH" ]; then
    echo "Error: Could not determine probabilistic-ff path"
    exit 1
fi

echo ""
echo "Setting PPDDL_PLANNER_CMD to:"
echo "  $PROBABILISTIC_FF_PATH -o {domain} -f {problem}"
echo ""

# Add to current shell
export PPDDL_PLANNER_CMD="$PROBABILISTIC_FF_PATH -o {domain} -f {problem}"

# Add to bashrc/zshrc
SHELL_RC=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ]; then
    # Remove old entry if exists
    sed -i '/PPDDL_PLANNER_CMD/d' "$SHELL_RC"
    # Add new entry
    echo "" >> "$SHELL_RC"
    echo "# PPDDL Planner Configuration" >> "$SHELL_RC"
    echo "export PPDDL_PLANNER_CMD=\"$PROBABILISTIC_FF_PATH -o {domain} -f {problem}\"" >> "$SHELL_RC"
    echo ""
    echo "✓ Added to $SHELL_RC"
    echo "  (Run 'source $SHELL_RC' or restart terminal to apply)"
else
    echo "⚠ Could not find .bashrc or .zshrc"
    echo "  Manually add to your shell config:"
    echo "  export PPDDL_PLANNER_CMD=\"$PROBABILISTIC_FF_PATH -o {domain} -f {problem}\""
fi

echo ""
echo "=========================================="
echo "Configuration complete!"
echo "=========================================="
echo ""
echo "Current session: PPDDL_PLANNER_CMD is set"
if [ -n "$SHELL_RC" ]; then
    echo "Permanent: Added to $SHELL_RC"
fi
echo ""
echo "Test with:"
echo "  python3 unified_demo.py --continuous --adapt-iterations 3"
echo ""

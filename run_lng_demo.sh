#!/bin/bash
#
# LNG Offtake Demo - Quick Run Script
#
# This script runs the complete LNG offtake demonstration with all three approaches
# and generates executive-ready visualizations.
#
# Usage:
#   ./run_lng_demo.sh [quick|full]
#
#   quick - Run baseline and hybrid only (fast, ~3 mins)
#   full  - Run all three approaches with learning (complete, ~7 mins)
#

set -o errexit
set -o pipefail

# Configuration
OUTPUT_DIR="lng_offtake_output"
MODE="${1:-full}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "\n${BLUE}================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Main script
print_header "LNG OFFTAKE OPTIMIZATION DEMO"

echo "Mode: $MODE"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Check dependencies
print_header "Checking Dependencies"

if ! command -v python3 &> /dev/null; then
    print_error "Python 3 not found. Please install Python 3.8+"
    exit 1
fi
print_success "Python 3 found"

if ! python3 -c "import numpy" &> /dev/null; then
    print_warning "NumPy not found. Installing..."
    pip install numpy
fi
print_success "NumPy available"

if ! python3 -c "import matplotlib" &> /dev/null; then
    print_warning "Matplotlib not found. Installing..."
    pip install matplotlib
fi
print_success "Matplotlib available"

# Check OpenAI API key
if [ -z "$OPENAI_API_KEY" ]; then
    print_warning "OPENAI_API_KEY not set. Attempting to use default key from script..."
    # Set default API key if not provided (for demo purposes)
    export OPENAI_API_KEY="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"
    print_success "OpenAI API key configured (from script default)"
else
    print_success "OpenAI API key configured"
fi

# Check planner
if [ -z "$PPDDL_PLANNER_CMD" ]; then
    print_warning "PPDDL_PLANNER_CMD not set. Planner execution will be skipped."
    print_warning "PPDDL files will still be generated for inspection."
else
    print_success "PPDDL planner configured"
fi

# Clean previous outputs
if [ -d "$OUTPUT_DIR" ]; then
    print_warning "Cleaning previous outputs in $OUTPUT_DIR"
    rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"

# Run demo based on mode
if [ "$MODE" = "quick" ]; then
    print_header "Running Quick Demo (Baseline + Hybrid)"
    
    echo "This will take approximately 3-5 minutes..."
    echo ""
    
    timeout 600s python3 main.py \
        --approach baseline \
        --output-dir "$OUTPUT_DIR" \
        2>&1 | tee "$OUTPUT_DIR/demo_log.txt"
    
    print_success "Baseline approach complete"
    
    timeout 600s python3 main.py \
        --approach hybrid \
        --output-dir "$OUTPUT_DIR" \
        2>&1 | tee -a "$OUTPUT_DIR/demo_log.txt"
    
    print_success "Hybrid approach complete"
    
elif [ "$MODE" = "full" ]; then
    print_header "Running Full Demo (All Approaches + Learning)"
    
    echo "This will take approximately 7-10 minutes..."
    echo ""
    
    timeout 900s python3 main.py \
        --approach all \
        --compare \
        --iterations 10 \
        --obs-per-iter 10 \
        --output-dir "$OUTPUT_DIR" \
        2>&1 | tee "$OUTPUT_DIR/demo_log.txt"
    
    print_success "All approaches complete"
    
else
    print_error "Unknown mode: $MODE"
    echo "Usage: $0 [quick|full]"
    exit 1
fi

# Generate visualizations
print_header "Generating Visualizations"

timeout 120s python3 lng_offtake_viz.py "$OUTPUT_DIR" 2>&1 | tee -a "$OUTPUT_DIR/demo_log.txt"

if [ -f "$OUTPUT_DIR/executive_summary.png" ]; then
    print_success "Visualizations generated"
else
    print_warning "Visualization generation had issues. Check log."
fi

# Summary
print_header "DEMO COMPLETE"

echo "Results saved to: $OUTPUT_DIR"
echo ""
echo "Generated files:"
echo "  📄 PPDDL domains and problems"
ls -lh "$OUTPUT_DIR"/*.ppddl 2>/dev/null | awk '{print "     - " $9 " (" $5 ")"}'

echo ""
echo "  📊 Analysis files"
ls -lh "$OUTPUT_DIR"/*.json 2>/dev/null | awk '{print "     - " $9 " (" $5 ")"}'

echo ""
echo "  🖼️  Visualizations"
ls -lh "$OUTPUT_DIR"/*.png 2>/dev/null | awk '{print "     - " $9 " (" $5 ")"}'

echo ""
echo "Key files for presentation:"
print_success "executive_summary.png - Single-page summary for your boss"
print_success "comparison.json - Quantitative comparison metrics"
print_success "learning_history.json - HHV learning convergence data"

echo ""
echo "Next steps:"
echo "  1. Open $OUTPUT_DIR/executive_summary.png"
echo "  2. Review LNG_OFFTAKE_README.md for detailed explanation"
echo "  3. Examine generated PPDDL files"
echo "  4. Check planner outputs for plan quality"

print_header "View Results"

# Try to open visualization automatically
if command -v xdg-open &> /dev/null; then
    echo "Opening executive summary..."
    xdg-open "$OUTPUT_DIR/executive_summary.png" 2>/dev/null || true
elif command -v open &> /dev/null; then
    echo "Opening executive summary..."
    open "$OUTPUT_DIR/executive_summary.png" 2>/dev/null || true
else
    echo "To view results, open: $OUTPUT_DIR/executive_summary.png"
fi

echo ""
print_success "Demo complete! 🚀"


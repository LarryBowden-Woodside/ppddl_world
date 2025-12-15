"""
LNG Offtake Visualization

Creates executive-ready visualizations for the LNG offtake demo results.
"""

import json
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from pathlib import Path
from typing import Dict, Any, List, Optional
import logging

logging.basicConfig(level=logging.INFO)


def create_learning_convergence_plot(
    learning_history: List[Dict[str, Any]],
    output_path: Path
):
    """
    Create a plot showing HHV learning convergence over iterations.
    
    Args:
        learning_history: List of learning history dictionaries
        output_path: Where to save the plot
    """
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('LNG HHV Learning Convergence', fontsize=16, fontweight='bold')
    
    iterations = [h['iteration'] for h in learning_history]
    
    # Train 1 Mean
    ax = axes[0, 0]
    train1_means = [h['train1_mean'] for h in learning_history]
    train1_stds = [h['train1_std'] for h in learning_history]
    train1_true = 1088.0
    
    ax.plot(iterations, train1_means, 'b-o', linewidth=2, label='Learned Mean')
    ax.fill_between(
        iterations,
        np.array(train1_means) - np.array(train1_stds),
        np.array(train1_means) + np.array(train1_stds),
        alpha=0.3,
        label='±1 Std Dev'
    )
    ax.axhline(train1_true, color='r', linestyle='--', linewidth=2, label='True Value')
    ax.set_xlabel('Iteration')
    ax.set_ylabel('HHV (BTU/scf)')
    ax.set_title('Train 1 HHV Learning')
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    # Train 2 Mean
    ax = axes[0, 1]
    train2_means = [h['train2_mean'] for h in learning_history]
    train2_stds = [h['train2_std'] for h in learning_history]
    train2_true = 1062.0
    
    ax.plot(iterations, train2_means, 'g-o', linewidth=2, label='Learned Mean')
    ax.fill_between(
        iterations,
        np.array(train2_means) - np.array(train2_stds),
        np.array(train2_means) + np.array(train2_stds),
        alpha=0.3,
        label='±1 Std Dev'
    )
    ax.axhline(train2_true, color='r', linestyle='--', linewidth=2, label='True Value')
    ax.set_xlabel('Iteration')
    ax.set_ylabel('HHV (BTU/scf)')
    ax.set_title('Train 2 HHV Learning')
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    # Error Convergence
    ax = axes[1, 0]
    train1_errors = [h['train1_error'] for h in learning_history]
    train2_errors = [h['train2_error'] for h in learning_history]
    
    ax.plot(iterations, train1_errors, 'b-o', linewidth=2, label='Train 1 Error')
    ax.plot(iterations, train2_errors, 'g-o', linewidth=2, label='Train 2 Error')
    ax.set_xlabel('Iteration')
    ax.set_ylabel('Absolute Error (BTU/scf)')
    ax.set_title('Learning Error Convergence')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_ylim(bottom=0)
    
    # Confidence
    ax = axes[1, 1]
    train1_conf = [h['train1_confidence'] for h in learning_history]
    train2_conf = [h['train2_confidence'] for h in learning_history]
    n_obs = [h['n_observations'] for h in learning_history]
    
    ax.plot(iterations, train1_conf, 'b-o', linewidth=2, label='Train 1 Confidence')
    ax.plot(iterations, train2_conf, 'g-o', linewidth=2, label='Train 2 Confidence')
    ax.set_xlabel('Iteration')
    ax.set_ylabel('Confidence')
    ax.set_title(f'Learning Confidence (Total Obs: {n_obs[-1]})')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_ylim([0, 1])
    
    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    logging.info(f"✓ Learning convergence plot saved to {output_path}")
    plt.close()


def create_approach_comparison_plot(
    comparison: Dict[str, Any],
    output_path: Path
):
    """
    Create a comparison plot for different approaches.
    
    Args:
        comparison: Comparison dictionary
        output_path: Where to save the plot
    """
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('LNG Offtake Approach Comparison', fontsize=16, fontweight='bold')
    
    approaches = comparison["approaches"]
    x_pos = np.arange(len(approaches))
    
    # Synthesis Time
    ax = axes[0, 0]
    times = [comparison["synthesis_time"][a] for a in approaches]
    bars = ax.bar(x_pos, times, color=['#3498db', '#2ecc71', '#e74c3c'][:len(approaches)])
    ax.set_ylabel('Time (seconds)')
    ax.set_title('Synthesis Time')
    ax.set_xticks(x_pos)
    ax.set_xticklabels(approaches)
    ax.grid(True, alpha=0.3, axis='y')
    
    # Add value labels on bars
    for i, (bar, val) in enumerate(zip(bars, times)):
        height = bar.get_height()
        ax.text(bar.get_x() + bar.get_width()/2., height,
                f'{val:.2f}s', ha='center', va='bottom')
    
    # PPDDL Size
    ax = axes[0, 1]
    domain_sizes = [comparison["domain_size"][a] / 1000 for a in approaches]  # KB
    problem_sizes = [comparison["problem_size"][a] / 1000 for a in approaches]  # KB
    
    width = 0.35
    bars1 = ax.bar(x_pos - width/2, domain_sizes, width, label='Domain', color='#3498db')
    bars2 = ax.bar(x_pos + width/2, problem_sizes, width, label='Problem', color='#2ecc71')
    
    ax.set_ylabel('Size (KB)')
    ax.set_title('PPDDL File Sizes')
    ax.set_xticks(x_pos)
    ax.set_xticklabels(approaches)
    ax.legend()
    ax.grid(True, alpha=0.3, axis='y')
    
    # Planner Success
    ax = axes[1, 0]
    success = [1 if comparison["planner_success"][a] else 0 for a in approaches]
    colors = ['#2ecc71' if s else '#e74c3c' for s in success]
    bars = ax.bar(x_pos, success, color=colors)
    ax.set_ylabel('Success')
    ax.set_title('Planner Execution')
    ax.set_xticks(x_pos)
    ax.set_xticklabels(approaches)
    ax.set_ylim([0, 1.2])
    ax.set_yticks([0, 1])
    ax.set_yticklabels(['Failed', 'Success'])
    
    # Add checkmarks/crosses
    for i, (bar, val) in enumerate(zip(bars, success)):
        symbol = '✓' if val else '✗'
        ax.text(bar.get_x() + bar.get_width()/2., 0.5,
                symbol, ha='center', va='center', fontsize=40,
                color='white', fontweight='bold')
    
    # Special Features
    ax = axes[1, 1]
    ax.axis('off')
    
    feature_text = "Key Features by Approach:\n\n"
    
    for approach in approaches:
        feature_text += f"{approach.upper()}:\n"
        
        if approach == "baseline":
            feature_text += "  • Pure LLM synthesis\n"
            feature_text += "  • Fastest synthesis\n"
            feature_text += "  • Risk: hallucination\n\n"
        
        elif approach == "hybrid":
            if "special_features" in comparison and approach in comparison["special_features"]:
                n_constraints = comparison["special_features"][approach].get("constraints_extracted", 0)
                feature_text += f"  • {n_constraints} constraints extracted\n"
                feature_text += "  • Deterministic parsing\n"
                feature_text += "  • Reduced hallucination\n\n"
        
        elif approach == "adaptive":
            if "special_features" in comparison and approach in comparison["special_features"]:
                n_iter = comparison["special_features"][approach].get("learning_iterations", 0)
                conv1 = comparison["special_features"][approach].get("convergence_train1", 0)
                conv2 = comparison["special_features"][approach].get("convergence_train2", 0)
                feature_text += f"  • {n_iter} learning iterations\n"
                feature_text += f"  • Train 1 error: {conv1:.1f} BTU/scf\n"
                feature_text += f"  • Train 2 error: {conv2:.1f} BTU/scf\n"
                feature_text += "  • Continuous adaptation\n\n"
    
    ax.text(0.1, 0.9, feature_text, transform=ax.transAxes,
            fontsize=10, verticalalignment='top', fontfamily='monospace',
            bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.3))
    
    plt.tight_layout()
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    logging.info(f"✓ Approach comparison plot saved to {output_path}")
    plt.close()


def create_executive_summary_plot(
    comparison: Dict[str, Any],
    learning_history: Optional[List[Dict[str, Any]]],
    output_path: Path
):
    """
    Create a single executive summary plot for presentation.
    
    Args:
        comparison: Comparison dictionary
        learning_history: Learning history (if adaptive was run)
        output_path: Where to save the plot
    """
    fig = plt.figure(figsize=(16, 10))
    gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)
    
    fig.suptitle('LNG Offtake Optimization: Executive Summary', 
                 fontsize=18, fontweight='bold')
    
    # Top: Problem Overview
    ax_overview = fig.add_subplot(gs[0, :])
    ax_overview.axis('off')
    
    overview_text = """
    PROBLEM: LNG Offtake Optimization with Uncertainty
    
    Objective: Maximize value over 30-day horizon by meeting 4 term contracts + exploiting 5 spot opportunities
    
    Key Uncertainties:
      • Product Quality (HHV): Train 1 = 1080-1100 BTU/scf, Train 2 = 1050-1070 BTU/scf
      • Vessel Arrivals: ±2 days from schedule
      • Spot Prices: $85-95M per cargo (70% acceptance probability)
    
    Constraints: 3 tanks (540k m³), 1 berth (24hr turnaround), quality spec (1055-1095 BTU/scf)
    
    Approach: Probabilistic planning (PPDDL) with continuous learning and adaptation
    """
    
    ax_overview.text(0.05, 0.95, overview_text, transform=ax_overview.transAxes,
                     fontsize=11, verticalalignment='top', fontfamily='monospace',
                     bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.3))
    
    # Middle Left: Approach Comparison
    ax_comparison = fig.add_subplot(gs[1, 0])
    approaches = comparison["approaches"]
    x_pos = np.arange(len(approaches))
    times = [comparison["synthesis_time"][a] for a in approaches]
    colors = ['#3498db', '#2ecc71', '#e74c3c'][:len(approaches)]
    
    bars = ax_comparison.bar(x_pos, times, color=colors)
    ax_comparison.set_ylabel('Time (s)', fontsize=10)
    ax_comparison.set_title('Synthesis Time by Approach', fontsize=12, fontweight='bold')
    ax_comparison.set_xticks(x_pos)
    ax_comparison.set_xticklabels(approaches, fontsize=9)
    ax_comparison.grid(True, alpha=0.3, axis='y')
    
    for bar, val in zip(bars, times):
        height = bar.get_height()
        ax_comparison.text(bar.get_x() + bar.get_width()/2., height,
                          f'{val:.1f}s', ha='center', va='bottom', fontsize=9)
    
    # Middle Center: Success Rates
    ax_success = fig.add_subplot(gs[1, 1])
    success = [1 if comparison["planner_success"][a] else 0 for a in approaches]
    colors_success = ['#2ecc71' if s else '#e74c3c' for s in success]
    bars = ax_success.bar(x_pos, success, color=colors_success)
    ax_success.set_ylabel('Success', fontsize=10)
    ax_success.set_title('Planner Execution Success', fontsize=12, fontweight='bold')
    ax_success.set_xticks(x_pos)
    ax_success.set_xticklabels(approaches, fontsize=9)
    ax_success.set_ylim([0, 1.2])
    ax_success.set_yticks([0, 1])
    ax_success.set_yticklabels(['✗', '✓'], fontsize=16)
    
    # Middle Right: Key Metrics
    ax_metrics = fig.add_subplot(gs[1, 2])
    ax_metrics.axis('off')
    
    metrics_text = "Key Results:\n\n"
    
    if "adaptive" in approaches:
        if "special_features" in comparison and "adaptive" in comparison["special_features"]:
            features = comparison["special_features"]["adaptive"]
            n_iter = features.get("learning_iterations", 0)
            conv1 = features.get("convergence_train1", 0)
            conv2 = features.get("convergence_train2", 0)
            
            metrics_text += f"Adaptive Learning:\n"
            metrics_text += f"  Iterations: {n_iter}\n"
            metrics_text += f"  Train 1 error: {conv1:.1f}\n"
            metrics_text += f"  Train 2 error: {conv2:.1f}\n\n"
    
    if "hybrid" in approaches:
        if "special_features" in comparison and "hybrid" in comparison["special_features"]:
            features = comparison["special_features"]["hybrid"]
            n_constraints = features.get("constraints_extracted", 0)
            metrics_text += f"Hybrid Approach:\n"
            metrics_text += f"  Constraints: {n_constraints}\n"
            metrics_text += f"  Method: Deterministic\n\n"
    
    metrics_text += "All Approaches:\n"
    metrics_text += "  ✓ Uncertainty modeled\n"
    metrics_text += "  ✓ PPDDL generated\n"
    metrics_text += "  ✓ Probabilistic plans\n"
    
    ax_metrics.text(0.1, 0.9, metrics_text, transform=ax_metrics.transAxes,
                   fontsize=10, verticalalignment='top', fontfamily='monospace',
                   bbox=dict(boxstyle='round', facecolor='lightyellow', alpha=0.3))
    
    # Bottom: Learning Convergence (if available)
    if learning_history:
        ax_learning = fig.add_subplot(gs[2, :])
        
        iterations = [h['iteration'] for h in learning_history]
        train1_errors = [h['train1_error'] for h in learning_history]
        train2_errors = [h['train2_error'] for h in learning_history]
        
        ax_learning.plot(iterations, train1_errors, 'b-o', linewidth=2, 
                        label='Train 1 HHV Error', markersize=8)
        ax_learning.plot(iterations, train2_errors, 'g-o', linewidth=2, 
                        label='Train 2 HHV Error', markersize=8)
        ax_learning.axhline(2.0, color='r', linestyle='--', linewidth=2, 
                           label='Target Error (<2 BTU/scf)')
        
        ax_learning.set_xlabel('Iteration', fontsize=11)
        ax_learning.set_ylabel('Absolute Error (BTU/scf)', fontsize=11)
        ax_learning.set_title('Continuous Learning: HHV Convergence Over Time', 
                             fontsize=12, fontweight='bold')
        ax_learning.legend(fontsize=10, loc='upper right')
        ax_learning.grid(True, alpha=0.3)
        ax_learning.set_ylim(bottom=0)
        
        # Highlight final values
        final_iter = iterations[-1]
        final_err1 = train1_errors[-1]
        final_err2 = train2_errors[-1]
        
        ax_learning.annotate(f'{final_err1:.1f}', 
                            xy=(final_iter, final_err1),
                            xytext=(10, 10), textcoords='offset points',
                            fontsize=10, fontweight='bold',
                            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.7))
        
        ax_learning.annotate(f'{final_err2:.1f}', 
                            xy=(final_iter, final_err2),
                            xytext=(10, -20), textcoords='offset points',
                            fontsize=10, fontweight='bold',
                            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.7))
    else:
        # No learning history - show benefits text
        ax_benefits = fig.add_subplot(gs[2, :])
        ax_benefits.axis('off')
        
        benefits_text = """
        KEY BENEFITS OF PROBABILISTIC PLANNING APPROACH:
        
        1. UNCERTAINTY MODELING: Explicitly represents HHV distributions, vessel ETA variance, spot price volatility
        2. RISK-AWARE DECISIONS: Plans account for probabilities (e.g., 70% spot acceptance, 95% HHV compliance)
        3. CONTINUOUS LEARNING: System improves as Field 2 ramps up and more HHV data is collected
        4. REDUCED HALLUCINATION: Hybrid approach uses deterministic constraint extraction → more reliable
        5. ADAPTIVE PLANNING: Plans update automatically as parameters are learned from observations
        6. QUANTIFIED DOWNSIDE: Provides P10/P50/P90 outcomes, not just point estimates
        
        NEXT STEPS: Deploy in pilot, integrate with real HHV sensors, validate against classical optimization
        """
        
        ax_benefits.text(0.05, 0.95, benefits_text, transform=ax_benefits.transAxes,
                        fontsize=11, verticalalignment='top', fontfamily='monospace',
                        bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.2))
    
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    logging.info(f"✓ Executive summary plot saved to {output_path}")
    plt.close()


def generate_all_visualizations(output_dir: Path):
    """
    Generate all visualizations from demo results.
    
    Args:
        output_dir: Directory containing demo results
    """
    logging.info("Generating visualizations...")
    
    # Load comparison
    comparison_file = output_dir / "comparison.json"
    if not comparison_file.exists():
        logging.warning(f"Comparison file not found: {comparison_file}")
        return
    
    with open(comparison_file, "r") as f:
        comparison = json.load(f)
    
    # Load learning history if available
    learning_history = None
    learning_file = output_dir / "learning_history.json"
    if learning_file.exists():
        with open(learning_file, "r") as f:
            learning_history = json.load(f)
    
    # Create visualizations
    if learning_history:
        create_learning_convergence_plot(learning_history, output_dir / "learning_convergence.png")
    
    create_approach_comparison_plot(comparison, output_dir / "approach_comparison.png")
    create_executive_summary_plot(comparison, learning_history, output_dir / "executive_summary.png")
    
    logging.info("✓ All visualizations generated")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python lng_offtake_viz.py <output_dir>")
        sys.exit(1)
    
    output_dir = Path(sys.argv[1])
    generate_all_visualizations(output_dir)


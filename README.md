# Replication of Does AI help humans make better decisions? (Imai et al., PNAS forthcoming)

This repository documents my replication of the empirical framework proposed by Kosuke Imai and co-authors in their paper:

Does AI help humans make better decisions? A statistical evaluation framework for experimental and observational studies.

#✨ Motivation

To deepen my understanding of causal inference with AI-assisted decision-making.

To gain hands-on experience with MCMC estimation, Inverse Probability Weighting (IPW/AIPW), and policy learning techniques.

# Repository structure
README.md
-scripts/
00_install.R # Robust installation (CRAN → r-universe → GitHub fallback)
10_quick_mcmc_synth.R # MCMC route on synthetic data (saves RDS)
20_psa_aipw.R # AIPW route on interim PSA data (illustration only)
30_policy_learning.R # Policy learning (Δloss weights, l01, monotone policy via Gurobi)
-report/
replication.Rmd # R Markdown source
replication.html # Rendered one-click report
-figures/
mcmc_diagnostics.pdf # Exported figures (diagnostics, preference regions, etc.)


# 📊 What the report shows
- MCMC diagnostics on bundled synthetic data
- APCE via IPW (stable to knit, interpretable table output)
- AIPW illustration: Human+AI vs Human, AI vs Human bounds, and preference plots across FP:FN ratios
- Policy learning: Δloss weights and a monotone “when to provide AI suggestions” policy

# ⚠️ Notes
- PSA datasets bundled in aihuman are interim and for illustration only.
- MCMC results are read from saved RDS for reproducibility and speed.
- Policy learning requires a working Gurobi installation.

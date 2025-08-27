# Imai et al. (PNAS) — MCMC-first Replication Scaffold

This project gives you a **step-by-step, MCMC-first** replication workflow for:
**"Does AI help humans make better decisions? A statistical evaluation framework for experimental and observational studies."**

It includes:
- Robust installation (CRAN → R-universe → GitHub fallback)
- **MCMC route** on synthetic data to verify pipeline
- AIPW route for interim PSA data (for illustration only)
- **Policy learning** script with **weights (wts)** construction and **l01 (FP:FN)**
- One-click HTML report

> Note: PSA datasets bundled in the package are **interim** and **only for illustrating methods**, not for drawing substantive conclusions.

---

## 0) Prereqs
- R ≥ 4.2 (recommended 4.3/4.4)
- Rtools (Windows) / Xcode CLT (macOS) / build-essential (Linux)
- Optional: **Gurobi** (for policy learning; academic license available)

---

## 1) Install packages (robust)
Open R and run:

```r
source('scripts/00_install.R')
```

This will try CRAN first; if it fails, it switches to the developer repo or GitHub.

---

## 2) Quick MCMC test (synthetic data)
```r
source('scripts/10_quick_mcmc_synth.R')
```
This runs `AiEvalmcmc()` on bundled synthetic data and saves summaries.

---

## 3) AIPW on interim PSA data (illustration)
```r
source('scripts/20_psa_aipw.R')
```

---

## 4) Policy learning (weights & l01)
1. Install and license **Gurobi**.
2. Run:
```r
source('scripts/30_policy_learning.R')
```
This script computes **per‑case expected loss differences** (AI vs Human) under your chosen `l01` and solves a **monotone** policy via MILP.

---

## 5) Knit an HTML report
Open `report/replication.Rmd` in RStudio and Knit.

---

## Troubleshooting
- If `aihuman` fails to install from CRAN, we try **r‑universe** and then **GitHub**.
- On macOS with M1/M2, ensure Command Line Tools installed; on Windows, install Rtools and set `PATH`.
- For Gurobi, ensure `library(gurobi)` works inside R before running policy learning.


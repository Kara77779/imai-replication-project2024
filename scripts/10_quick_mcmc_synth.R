# scripts/10_quick_mcmc_synth.R
library(aihuman)

set.seed(42)
data(synth)  # bundled synthetic data

# MCMC (Bayesian) route
fit_mcmc <- AiEvalmcmc(data = synth, n.mcmc = 2000)  # adjust up for publication-grade
print(summary(fit_mcmc))
print(APCEsummary(fit_mcmc))

saveRDS(fit_mcmc, 'out_fit_mcmc_synth.rds')

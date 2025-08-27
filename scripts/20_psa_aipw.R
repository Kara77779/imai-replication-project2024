# scripts/20_psa_aipw.R
# AIPW on interim PSA data (for illustration only — not for substantive inference)
library(aihuman)
library(dplyr)

Z <- aihuman::NCAdata$Z
D <- if_else(aihuman::NCAdata$D == 0, 0, 1)
A <- aihuman::PSAdata$DMF
Y <- aihuman::NCAdata$Y

race_vec <- aihuman::NCAdata %>% mutate(race = if_else(White == 1,'White','Non-white')) %>% pull(race)
gender_vec <- aihuman::NCAdata %>% mutate(gender = if_else(Sex == 1,'Male','Female')) %>% pull(gender)

cov_mat <- aihuman::NCAdata %>%
  select(-c(Y,D,Z)) %>%
  bind_cols(FTAScore = aihuman::PSAdata$FTAScore,
            NCAScore = aihuman::PSAdata$NCAScore,
            NVCAFlag = aihuman::PSAdata$NVCAFlag) %>%
  as.matrix()

nuis_func    <- compute_nuisance_functions(Y=Y, D=D, Z=Z, V=cov_mat, shrinkage=0.01, n.trees=1000)
nuis_func_ai <- compute_nuisance_functions_ai(Y=Y, D=D, Z=Z, A=A, V=cov_mat, shrinkage=0.01, n.trees=1000)

# Human+AI vs Human
print(
  compute_stats_aipw(Y=Y, D=D, Z=Z, nuis_funcs=nuis_func, true.pscore=rep(0.5,length(D)), X=NULL, l01=1)
)
plot_diff_human_aipw(Y=Y, D=D, Z=Z, nuis_funcs=nuis_func, l01=1, true.pscore=rep(0.5,length(D)),
                     subgroup1=race_vec, subgroup2=gender_vec,
                     label.subgroup1='Race', label.subgroup2='Gender',
                     x.order=c('Overall','Non-white','White','Female','Male'))

# AI vs Human bounds
print(
compute_bounds_aipw(Y=Y, D=D, Z=Z, A=A, nuis_funcs=nuis_func, nuis_funcs_ai=nuis_func_ai, true.pscore=rep(0.5,length(D)), X=NULL, l01=1)
)

# Preference regions (when to prefer whom) across loss ratios
plot_preference(Y=Y, D=D, Z=Z, A=A, z_compare=0, nuis_funcs=nuis_func, nuis_funcs_ai=nuis_func_ai,
                l01_seq=10^seq(-2,2,length.out=100), alpha=0.05, true.pscore=rep(0.5,length(D)),
                subgroup1=race_vec, subgroup2=gender_vec,
                label.subgroup1='Race', label.subgroup2='Gender')

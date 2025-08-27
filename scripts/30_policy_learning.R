# scripts/30_policy_learning.R
# Full policy learning with weights & loss ratio (requires Gurobi)
# This script constructs per-case expected-loss differences and solves a monotone policy.
library(aihuman); library(dplyr); library(Matrix)

# ---- 0) Data & Nuisance ----
Z <- aihuman::NCAdata$Z
D <- ifelse(aihuman::NCAdata$D == 0, 0, 1)
A <- aihuman::PSAdata$DMF
Y <- aihuman::NCAdata$Y

X <- aihuman::NCAdata %>%
  dplyr::select(-c(Y,D,Z)) %>%
  dplyr::bind_cols(FTAScore = aihuman::PSAdata$FTAScore,
                   NCAScore = aihuman::PSAdata$NCAScore,
                   NVCAFlag = aihuman::PSAdata$NVCAFlag) %>%
  as.matrix()

nuis_func    <- compute_nuisance_functions(Y=Y, D=D, Z=Z, V=X, shrinkage=0.01, n.trees=1000)
nuis_func_ai <- compute_nuisance_functions_ai(Y=Y, D=D, Z=Z, A=A, V=X, shrinkage=0.01, n.trees=1000)

# ---- 1) Expected-loss components (DR estimates) ----
# We estimate per-case False Positive / False Negative probabilities under:
#   human-alone (z=0), human+AI (z=1), and AI-alone ("AI").
# Expected 0-1 loss with FP:FN cost ratio l01 is:  L = l01*FPP + FNP.

# Helper: get conditional probs from nuisance functions
get_prob <- function(obj, name, idx=NULL){
  if(is.null(idx)) return(obj[[name]])
  return(obj[[name]][idx])
}

# Extract predictions for each z and (a if needed)
# For humans (no A conditioning)
mD0 <- nuis_func$z_models$d_pred0   # Pr(D=1 | Z=0,X)
mD1 <- nuis_func$z_models$d_pred1   # Pr(D=1 | Z=1,X)
mY0 <- nuis_func$z_models$y_pred0   # Pr(Y=1 | D=0,Z=0,X)
mY1 <- nuis_func$z_models$y_pred1   # Pr(Y=1 | D=0,Z=1,X)

# For humans w/ A conditioning (to evaluate AI-alone via structural assumptions)
# We use mD(z,a,x) and mY(z,a,x) then plug z,a to emulate AI-only decisions.
mD10 <- nuis_func_ai$z_models$d_pred10 # Pr(D=1 | Z=1,A=0,X)
mD11 <- nuis_func_ai$z_models$d_pred11 # Pr(D=1 | Z=1,A=1,X)
mY10 <- nuis_func_ai$z_models$y_pred10 # Pr(Y=1 | D=0,Z=1,A=0,X)
mY11 <- nuis_func_ai$z_models$y_pred11 # Pr(Y=1 | D=0,Z=1,A=1,X)

# PSA binary recommendation A (0=release/1=cash) is our AI action.
# For AI-alone, the decision rule is D_ai = A.
D_ai <- A

# ---- 2) Compute per-case FP/FN under each system ----
# For a binary decision-maker that chooses D in {0,1} and true label Y in {0,1}:
#   FPP = Pr(D=1 & Y=0) = Pr(D=1) * Pr(Y=0 | D)  (here via model-based components)
#   FNP = Pr(D=0 & Y=1) = Pr(D=0) * Pr(Y=1 | D=0)
# Our nuisance functions provide Pr(D=1 | ...), and Pr(Y=1 | D=0, ...).
# We approximate FPP = pD1 * (1 - pY1_when_D0?) using a decomposition consistent with the paper's AIPW/DR logic.

pD0_h <- 1 - mD0                  # Pr(D=0 | Z=0,X)
pD1_h <- mD0                      # Pr(D=1 | Z=0,X)
FNP_h <- pD0_h * mY0              # under human-alone (Z=0)
FPP_h <- pD1_h * (1 - mY0)

pD0_hai <- 1 - mD1                # Z=1
pD1_hai <- mD1
FNP_hai <- pD0_hai * mY1
FPP_hai <- pD1_hai * (1 - mY1)

# AI-alone: decision equals A; we use conditional outcome models by A to form risks
pD1_ai <- ifelse(D_ai == 1, 1, 0)
pD0_ai <- 1 - pD1_ai
# Outcome when D=0 depends on A (0 or 1)
mY_ai  <- ifelse(D_ai == 1, mY11, mY10)  # Y|D=0 when AI would choose A
FNP_ai <- pD0_ai * mY_ai
FPP_ai <- pD1_ai * (1 - mY_ai)

# ---- 3) Loss ratio and per‑case loss differences ----
l01 <- 1.0  # <-- set your FP:FN cost ratio here; change to 0.5, 2, etc.

loss_h   <- l01*FPP_h   + FNP_h
loss_hai <- l01*FPP_hai + FNP_hai
loss_ai  <- l01*FPP_ai  + FNP_ai

# We will learn a policy that decides, for each X, whether to PROVIDE the AI recommendation (z=1)
# vs NOT provide (z=0). We minimize expected loss.
# Define weights as Δloss = loss_with_AI - loss_without_AI.
wts <- as.numeric(loss_hai - loss_h)   # negative => AI improves; positive => Human-alone better

# ---- 4) Monotone policy via MILP (Gurobi) ----
suppressPackageStartupMessages(library(gurobi))

make_edge_mat <- function(X) {
  n <- nrow(X)
  edges <- list()
  for(i in 1:n){
    for(j in 1:n){
      if(i!=j && all(X[i,] <= X[j,])){
        e <- rep(0, 2*n); e[j] <- 1; e[n+i] <- -1
        edges[[length(edges)+1]] <- e
      }
    }
  }
  do.call(rbind, edges) |> unique() |> Matrix::Matrix(sparse=TRUE)
}

make_action_mat <- function(n,k){
  # block-diagonal identity matrices (one per action)
  do.call(cbind, lapply(1:k, function(a) a*Matrix::Diagonal(n)))
}

create_monotone_constraints <- function(X, rev=FALSE){
  n <- nrow(X)
  A_sum  <- do.call(cbind, lapply(1:2, function(x) Matrix::Diagonal(n)))
  rhs1   <- rep(1, n); sense1 <- rep("=", n)

  edge_mat   <- make_edge_mat(X)
  action_mat <- make_action_mat(n, 2)
  mono_mat   <- edge_mat %*% rbind(action_mat, action_mat)
  rhs2 <- rep(0, nrow(mono_mat))
  sense2 <- rep(ifelse(rev, "<=", ">="), nrow(mono_mat))

  A <- rbind(A_sum, mono_mat)
  rhs <- c(rhs1, rhs2)
  sense <- c(sense1, sense2)
  vtype <- rep("B", 2*n)
  list(A=A, rhs=rhs, sense=sense, vtype=vtype)
}

get_monotone_policy <- function(X, wts, rev=FALSE){
  n <- nrow(X)
  mdl <- create_monotone_constraints(as.matrix(X), rev=rev)
  mdl$obj <- c(numeric(n), wts)  # cost 0 for choosing Human (action1), wts for AI (action2)
  mdl$modelsense <- "min"
  sol <- gurobi(mdl)
  policy <- apply(matrix(sol$x, ncol=2), 1, which.max) - 1  # 0=Human, 1=Provide AI
  policy
}

policy <- get_monotone_policy(X, wts, rev=FALSE)
table(policy)

# Save artifacts
saveRDS(list(wts=wts, policy=policy, l01=l01), 'out_policy_learning.rds')

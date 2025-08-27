# scripts/00_install.R
opts <- list(repos = c(CRAN = "https://cloud.r-project.org"))
options(repos = opts$repos)

need <- function(pkgs){
  new <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  if(length(new)) install.packages(new)
  invisible(lapply(pkgs, require, character.only = TRUE))
}

# 1) Try CRAN
try({
  install.packages("aihuman")
}, silent = TRUE)

if (!("aihuman" %in% installed.packages()[, "Package"])) {
  message("CRAN failed; trying r-universe...")
  install.packages('aihuman', repos = c('https://sooahnshin.r-universe.dev', 'https://cloud.r-project.org'))
}

if (!("aihuman" %in% installed.packages()[, "Package"])) {
  message("r-universe failed; trying GitHub...")
  if (!("remotes" %in% installed.packages()[, "Package"])) install.packages("remotes")
  remotes::install_github("sooahnshin/aihuman", dependencies = TRUE, build_vignettes = TRUE)
}

need(c("aihuman","tidyverse","Matrix","ggplot2","gridExtra","bayesplot"))
message("Install done.")

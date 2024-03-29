% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dbn_inference.R
\name{smooth_ts}
\alias{smooth_ts}
\title{Performs smoothing with the GDBN over a dataset}
\usage{
smooth_ts(
  dt,
  fit,
  size = NULL,
  obj_vars,
  ini = dim(dt)[1],
  len = ini - 1,
  print_res = TRUE,
  plot_res = TRUE,
  prov_ev = NULL
)
}
\arguments{
\item{dt}{data.table object with the TS data}

\item{fit}{dbn.fit object}

\item{size}{number of time slices of the net. Deprecated, will be removed in the future}

\item{obj_vars}{variables to be predicted. Should be in the oldest time step}

\item{ini}{starting point in the dataset to smooth}

\item{len}{length of the smoothing}

\item{print_res}{if TRUE prints the mae and sd metrics of the smoothing}

\item{plot_res}{if TRUE plots the results of the smoothing}

\item{prov_ev}{variables to be provided as evidence in each smoothing step. Should be in the oldest time step}
}
\value{
a list with the original values and the results of the smoothing
}
\description{
Given a dbn.fit object, the size of the net and a folded dataset,
performs a smoothing of a trajectory. Smoothing is the opposite of 
forecasting: given a starting point, predict backwards in time to obtain
the time series that generated that point.
}
\examples{
size = 3
data(motor)
dt_train <- motor[200:900]
dt_val <- motor[901:1000]
obj <- c("pm_t_2")
net <- learn_dbn_struc(dt_train, size)
f_dt_train <- fold_dt(dt_train, size)
f_dt_val <- fold_dt(dt_val, size)
fit <- fit_dbn_params(net, f_dt_train, method = "mle-g")
res <- suppressWarnings(smooth_ts(f_dt_val, fit, 
        obj_vars = obj, len = 10, print_res = FALSE, plot_res = FALSE))
}

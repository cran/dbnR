% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dbn_learn.R
\name{learn_dbn_struc}
\alias{learn_dbn_struc}
\title{Learns the structure of a markovian n DBN model from data}
\usage{
learn_dbn_struc(dt, size = 2, method = "dmmhc", f_dt = NULL, ...)
}
\arguments{
\item{dt}{the data.frame or data.table to be used}

\item{size}{number of time slices of the net. Markovian 1 would be size 2}

\item{method}{the structure learning method of choice to use}

\item{f_dt}{previously folded dataset, in case some specific rows have to be removed after the folding}

\item{...}{additional parameters for \code{\link[bnlearn]{rsmax2}} function}
}
\value{
a "dbn" S3 object with the structure of the network
}
\description{
Learns a gaussian dynamic Bayesian network from a dataset. 
It allows the creation of markovian n nets rather than only markov 1.
}
\examples{
data("motor")
net <- learn_dbn_struc(motor, size = 3)
}

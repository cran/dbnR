% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/structure_learning_psoho.R
\name{Causlist}
\alias{Causlist}
\title{R6 class that defines causal lists in the PSO}
\arguments{
\item{ordering}{a vector with the names of the nodes in t_0}

\item{size}{number of timeslices of the DBN}
}
\value{
A new 'causlist' object
}
\description{
Constructor of the 'Causlist' class
}
\details{
The causal lists will be the base of the positions and the velocities
in the pso part of the algorithm.
}
\section{Fields}{

\describe{
\item{\code{cl}}{List of causal units}

\item{\code{size}}{Size of the DBN}

\item{\code{ordering}}{String vector defining the order of the nodes in a timeslice}
}}

\keyword{internal}

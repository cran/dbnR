% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/structure_learning_natpsoho.R
\name{natCauslist}
\alias{natCauslist}
\title{R6 class that defines causal lists in the PSO}
\arguments{
\item{ordering}{a vector with the names of the nodes in t_0}

\item{ordering_raw}{a vector with the names of the nodes without the appended "_t_0"}
}
\value{
A new 'natCauslist' object
}
\description{
Constructor of the 'natCauslist' class
}
\details{
The causal lists will be the base of the positions and the velocities
in the pso part of the algorithm. They will not have the same structure
as their binary counterparts, but their class skeleton will serve as a
base.
}
\section{Fields}{

\describe{
\item{\code{cl}}{List of causal units}

\item{\code{ordering}}{String vector defining the order of the nodes in t_0}

\item{\code{ordering}}{String vector defining the order of the nodes without the appended "_t_0"}
}}

\keyword{internal}

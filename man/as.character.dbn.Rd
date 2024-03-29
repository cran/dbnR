% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bnlearn_compat.R
\name{as.character.dbn}
\alias{as.character.dbn}
\title{Convert a network structure into a model string}
\usage{
\method{as.character}{dbn}(x, ...)
}
\arguments{
\item{x}{a "dbn" object}

\item{...}{additional parameters}
}
\value{
string representing the DBN model
}
\description{
Generic method for converting a "dbn" S3 object into a string.
Calls bnlearn's \code{\link{as.character}} underneath.
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bnlearn_compat.R
\name{rbn.dbn.fit}
\alias{rbn.dbn.fit}
\title{Simulates random samples from a fitted DBN}
\usage{
rbn.dbn.fit(x, n, ...)
}
\arguments{
\item{x}{the fitted network}

\item{n}{number of samples}

\item{...}{additional parameters}
}
\value{
the sampled dataset
}
\description{
Generic method for "dbn.fit" S3 objects. 
Calls bnlearn's \code{\link[bnlearn]{rbn}} underneath.
}

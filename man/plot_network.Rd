% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dbn_visualization.R
\name{plot_network}
\alias{plot_network}
\title{Plots a Bayesian networks in a hierarchical way}
\usage{
plot_network(structure)
}
\arguments{
\item{structure}{the structure or fit of the network.}
}
\description{
Calculates the levels of each node and then plots them in a hierarchical
layout in visNetwork.
}
\examples{
\donttest{
dt_train <- dbnR::motor[200:2500]
net <- bnlearn::mmhc(dt_train)
plot_network(net)
fit <- bnlearn::bn.fit(net, dt_train, method = "mle")
plot_network(fit) # Works for both the structure and the fitted net
}
}

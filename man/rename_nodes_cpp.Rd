% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{rename_nodes_cpp}
\alias{rename_nodes_cpp}
\title{Return a list of nodes with the time slice appended up to the desired size
of the network}
\usage{
rename_nodes_cpp(nodes, size)
}
\arguments{
\item{nodes}{a list with the names of the nodes in the network}

\item{size}{the size of the DBN}
}
\value{
a list with the renamed nodes in each timeslice
}
\description{
Return a list of nodes with the time slice appended up to the desired size
of the network
}
\keyword{internal}

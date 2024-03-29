% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/structure_learning_natpsoho.R
\name{natPsoCtrl}
\alias{natPsoCtrl}
\title{R6 class that defines the PSO controller}
\arguments{
\item{n_it}{maximum number of iterations of the pso algorithm}

\item{in_cte}{parameter that varies the effect of the inertia}

\item{gb_cte}{parameter that varies the effect of the global best}

\item{lb_cte}{parameter that varies the effect of the local best}

\item{r_probs}{vector that defines the range of random variation of gb_cte and lb_cte}

\item{cte}{boolean that defines whether the parameters remain constant or vary as the execution progresses}

\item{nodes}{a vector with the names of the nodes}

\item{ordering}{a vector with the names of the nodes in t_0}

\item{max_size}{maximum number of timeslices of the DBN}

\item{n_inds}{number of particles that the algorithm will simultaneously process}

\item{v_probs}{vector that defines the random velocity initialization probabilities}

\item{p}{parameter of the truncated geometric distribution for sampling edges}

\item{score}{bnlearn score function used}
}
\value{
A new 'natPsoCtrl' object

the ordering with the names cropped
}
\description{
Constructor of the 'natPsoCtrl' class

If the names of the nodes have "_t_0" appended at the end, remove it

Initialize the particles for the algorithm to random positions and velocities.
}
\details{
The controller will encapsulate the particles and run the algorithm. This
time, it extends the class "PsoCtrl" in the "structure_learning_psoho.R"
file, because both controllers are practically the same. The particles,
positions and velocities are too different to extend one another though.
}
\keyword{internal}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllClasses.R
\docType{methods}
\name{SurvMatrix}
\alias{SurvMatrix}
\alias{SurvEvents}
\alias{SurvProbs}
\alias{[,SurvMatrix,ANY,ANY,ANY-method}
\alias{SurvMatrix,ANY,ANY,ANY}
\title{SurvMatrix Class Constructor}
\usage{
SurvEvents(object = numeric(), times = NULL)

SurvProbs(object = numeric(), times = NULL)

\S4method{[}{SurvMatrix,ANY,ANY,ANY}(x, i, j, ..., drop = FALSE)
}
\arguments{
\item{object}{matrix, or object that can be converted to one, of predicted
survival events or probabilities with columns and rows representing
prediction times and cases, respectively.}

\item{times}{numeric vector of the survival prediction times.}

\item{x}{object from which to extract elements.}

\item{i, j, ...}{indices specifying elements to extract.}

\item{drop}{logical indicating that the result be returned as a
\code{numeric} coerced to the lowest dimension possible if \code{TRUE} or
as a 2-dimensional \code{SurvMatrix} object otherwise.}
}
\value{
Object that is of the same class as the constructor name and inherits
from \code{SurvMatrix}.  Examples of these objects are the predicted survival
events and probabilities returned by the \code{predict} function.
}
\description{
Create an object of predicted survival events or probabilites for use with
metrics provided by the \pkg{MachineShop} package.
}
\seealso{
\code{\link{metrics}}, \code{\link{predict}}
}
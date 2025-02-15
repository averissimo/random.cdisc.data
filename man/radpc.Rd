% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/radpc.R
\name{radpc}
\alias{radpc}
\title{Pharmacokinetics Analysis Dataset (ADPC)}
\usage{
radpc(
  adsl,
  avalu = "ug/mL",
  constants = c(D = 100, ka = 0.8, ke = 1),
  duration = 2,
  seed = NULL,
  na_percentage = 0,
  na_vars = list(AVAL = c(NA, 0.1)),
  cached = FALSE
)
}
\arguments{
\item{adsl}{(\code{data.frame})\cr Subject-Level Analysis Dataset (ADSL).}

\item{avalu}{(\code{character})\cr Analysis value units.}

\item{constants}{(\verb{character vector})\cr Constant parameters to be used in formulas for creating analysis values.}

\item{duration}{(\code{numeric})\cr Duration in number of days.}

\item{seed}{(\code{numeric})\cr Seed to use for reproducible random number generation.}

\item{na_percentage}{(\code{proportion})\cr Default percentage of values to be replaced by \code{NA}.}

\item{na_vars}{(\code{list})\cr A named list where the name of each element is a column name of \code{ds}. Each
element of this list should be a numeric vector with two elements:
\itemize{
\item{\code{seed} (\code{numeric})\cr The seed to be used for this element - can be \code{NA}.}
\item{\code{percentage} (\code{proportion})\cr Percentage of elements to be replaced with \code{NA}.
If \code{NA}, \code{na_percentage} is used as a default.}
}}

\item{cached}{boolean whether the cached ADPC data \code{cadpc} should be returned or new data
should be generated. If set to \code{TRUE} then the other arguments to \code{radpc} will be ignored.}
}
\value{
\code{data.frame}
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#stable}{\figure{lifecycle-stable.svg}{options: alt='[Stable]'}}}{\strong{[Stable]}}

Function for generating a random Pharmacokinetics Analysis Dataset for a given
Subject-Level Analysis Dataset.
}
\details{
One record per study, subject, parameter, and time point.
}
\examples{
library(random.cdisc.data)
adsl <- radsl(N = 10, seed = 1, study_duration = 2)

adpc <- radpc(adsl, seed = 2)
adpc

adpc <- radpc(adsl, seed = 2, duration = 3)
adpc
}

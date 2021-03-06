% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/dataDocs.R
\docType{data}
\name{inaugCorpus}
\alias{inaugCorpus}
\alias{inaugTexts}
\title{A corpus of US presidential inaugural addresses from 1789-2013}
\description{
\code{inaugCorpus} is the \link{quanteda-package} corpus object of US presidents' inaugural addresses since 1789.
Document variables contain the year of the address and the last name of the president.

\code{inaugTexts} is the character vector of US presidential inaugaration speeches
}
\examples{
# some operations on the inaugural corpus
summary(inaugCorpus)
head(docvars(inaugCorpus), 10)
# working with the character vector only
str(inaugTexts)
head(docvars(inaugCorpus), 10)
mycorpus <- corpus(inaugTexts)
}
\references{
\url{https://archive.org/details/Inaugural-Address-Corpus-1789-2009} and
\url{http://www.presidency.ucsb.edu/inaugurals.php}.
}


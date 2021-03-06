% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/tokenize.R
\name{tokenize}
\alias{clean}
\alias{is.tokenizedTexts}
\alias{tokenise}
\alias{tokenize}
\alias{tokenize.character}
\alias{tokenize.corpus}
\title{tokenize a set of texts}
\usage{
tokenize(x, ...)

\method{tokenize}{character}(x, what = c("word", "sentence", "character",
  "fastestword", "fasterword"), removeNumbers = FALSE, removePunct = FALSE,
  removeSeparators = TRUE, removeTwitter = FALSE, removeHyphens = FALSE,
  ngrams = 1L, window = 1L, concatenator = "_", simplify = FALSE,
  verbose = FALSE, ...)

\method{tokenize}{corpus}(x, ...)

is.tokenizedTexts(x)
}
\arguments{
\item{x}{The text(s) or corpus to be tokenized}

\item{...}{additional arguments not used}

\item{what}{the unit for splitting the text, defaults to \code{"word"}.
Available alternatives are \code{c("character", "word", "line_break",
"sentence")}. See \link[stringi]{stringi-search-boundaries}.}

\item{removeNumbers}{remove tokens that consist only of numbers, but not
words that start with digits, e.g. \code{2day}}

\item{removePunct}{remove all punctuation}

\item{removeSeparators}{remove Separators and separator characters (spaces
and variations of spaces, plus tab, newlines, and anything else in the
Unicode "separator" category) when \code{removePunct=FALSE}.  Only
applicable for \code{what = "character"} (when you probably want it to be
\code{FALSE}) and for \code{what = "word"} (when you probably want it to be
\code{TRUE}).  Note that if \code{what = "word"} and you set
\code{removePunct = TRUE}, then \code{removeSeparators} has no effect.  Use
carefully.}

\item{removeTwitter}{remove Twitter characters \code{@} and \code{#}; set to
\code{FALSE} if you wish to eliminate these.}

\item{removeHyphens}{if \code{TRUE}, split words that are connected by
hyphenation and hyphenation-like characters in between words, e.g.
\code{"self-storage"} becomes \code{c("self", "storage")}.  Default is
\code{FALSE} to preserve such words as is, with the hyphens.  Only applies if
\code{what = "word"}.}

\item{ngrams}{integer vector of the \emph{n} for \emph{n}-grams, defaulting
to \code{1} (unigrams). For bigrams, for instance, use \code{2}; for
bigrams and unigrams, use \code{1:2}.  You can even include irregular
sequences such as \code{2:3} for bigrams and trigrams only.}

\item{window}{integer vector specifying the adjacency width for tokens
forming the \emph{n}-grams, default is 1 for only immediately neighbouring
words. Only applies if \code{ngrams} is different from the default of 1.}

\item{concatenator}{character to use in concatenating \emph{n}-grams, default
is "\code{_}", which is recommended since this is included in the regular
expression and Unicode definitions of "word" characters}

\item{simplify}{if \code{TRUE}, return a character vector of tokens rather
than a list of length \code{\link{ndoc}(texts)}, with each element of the
list containing a character vector of the tokens corresponding to that
text.}

\item{verbose}{if \code{TRUE}, print timing messages to the console; off by
default}
}
\value{
A list of length \code{\link{ndoc}(x)} of the tokens found in each text.

a \strong{tokenizedText} (S3) object, essentially a list of character
  vectors. If \code{simplify = TRUE} then return a single character vector.
}
\description{
Tokenize the texts from a character vector or from a corpus.

\code{is.tokenizedTexts} returns \code{TRUE} if the object is of class tokenizedTexts, \code{FALSE} otherwise.
}
\details{
The tokenizer is designed to be fast and flexible as well as to
  handle Unicode correctly. Most of the time, users will construct \link{dfm}
  objects from texts or a corpus, without calling \code{tokenize()} as an
  intermediate step.  Since \code{tokenize()} is most likely to be used by
  more technical users, we have set its options to default to minimal
  intervention. This means that punctuation is tokenized as well, and that
  nothing is removed from the
}
\note{
This replaces an older function named \code{clean()}, removed from
  \pkg{quanteda} in version 0.8.1.  "Cleaning" by removing certain parts of
  texts, such as punctuation or numbers, only only works on tokenized texts,
  although texts of any length can be converted to lower case using
  \code{\link{toLower}}.
}
\examples{
# same for character vectors and for lists
tokensFromChar <- tokenize(inaugTexts[1:3])
tokensFromCorp <- tokenize(subset(inaugCorpus, Year<1798))
identical(tokensFromChar, tokensFromCorp)
str(tokensFromChar)
# returned as a list
head(tokenize(inaugTexts[57])[[1]], 10)
# returned as a character vector using simplify=TRUE
head(tokenize(inaugTexts[57], simplify=TRUE), 10)

# removing punctuation marks and lowecasing texts
head(tokenize(toLower(inaugTexts[57]), simplify=TRUE, removePunct=TRUE), 30)
# keeping case and punctuation
head(tokenize(inaugTexts[57], simplify=TRUE), 30)
# keeping versus removing hyphens
tokenize("quanteda data objects are auto-loading.", removePunct = TRUE)
tokenize("quanteda data objects are auto-loading.", removePunct = TRUE, removeHyphens = TRUE)

## MORE COMPARISONS
txt <- "#textanalysis is MY <3 4U @myhandle gr8 #stuff :-)"
tokenize(txt, removePunct=TRUE)
tokenize(txt, removePunct=TRUE, removeTwitter=TRUE)
#tokenize("great website http://textasdata.com", removeURL=FALSE)
#tokenize("great website http://textasdata.com", removeURL=TRUE)

txt <- c(text1="This is $10 in 999 different ways,\\n up and down; left and right!",
         text2="@kenbenoit working: on #quanteda 2day\\t4ever, http://textasdata.com?page=123.")
tokenize(txt, verbose=TRUE)
tokenize(txt, removeNumbers=TRUE, removePunct=TRUE)
tokenize(txt, removeNumbers=FALSE, removePunct=TRUE)
tokenize(txt, removeNumbers=TRUE, removePunct=FALSE)
tokenize(txt, removeNumbers=FALSE, removePunct=FALSE)
tokenize(txt, removeNumbers=FALSE, removePunct=FALSE, removeSeparators=FALSE)

# character level
tokenize("Great website: http://textasdata.com?page=123.", what="character")
tokenize("Great website: http://textasdata.com?page=123.", what="character",
         removeSeparators=FALSE)

# sentence level
tokenize(c("Kurt Vongeut said; only assholes use semi-colons.",
           "Today is Thursday in Canberra:  It is yesterday in London.",
           "Today is Thursday in Canberra:  \\nIt is yesterday in London.",
           "To be?  Or\\not to be?"),
          what = "sentence")
tokenize(inaugTexts[c(2,40)], what = "sentence", simplify = TRUE)

# creating ngrams
txt <- toLower(c(mytext1 = "This is a short test sentence.",
                mytext2 = "Short.",
                mytext3 = "Short, shorter, and shortest."))
tokenize(txt, removePunct = TRUE)
removeFeatures(tokenize(txt, removePunct = TRUE), stopwords("english"))
tokenize(txt, removePunct = TRUE, ngrams = 2)
tokenize(txt, removePunct = TRUE, ngrams = 1:2)
tokenize(txt, removePunct = TRUE, ngrams = 2, window = 2, concatenator = " ")
removeFeatures(tokenize(txt, removePunct = TRUE, ngrams = 1:2), stopwords("english"))
}
\author{
Ken Benoit and Paul Nulty
}
\seealso{
\code{\link{ngrams}}
}


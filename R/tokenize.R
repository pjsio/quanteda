
# @rdname segment
# @return \code{segmentSentence} returns a character vector of sentences that
#   have been segmented
# @export
# @examples
# # segment sentences of the UK 2010 immigration sections of manifestos
# segmentSentence(ukimmigTexts[1])[1:5]   # 1st 5 sentences from first (BNP) text
# str(segmentSentence(ukimmigTexts[1]))   # a 132-element char vector
# str(segmentSentence(ukimmigTexts[1:2])) # a 144-element char vector (143+ 12)
# 
segmentSentence <- function(x, delimiter = NULL, perl = FALSE) {
    result <- unlist(tokenize(x, what = "sentence"), use.names = FALSE)
}

# @rdname segment
# @return \code{segmentParagraph} returns a character vector of paragraphs that
#   have been segmented
# @export
# @examples
# # segment paragraphs 
# segmentParagraph(ukimmigTexts[3])[1:2]   # 1st 2 Paragraphs from 3rd (Con) text
# str(segmentParagraph(ukimmigTexts[3]))   # a 12-element char vector
# 
# @export
segmentParagraph <- function(x, delimiter="\\n{2}", perl=FALSE) {
    tmp <- unlist(strsplit(x, delimiter, perl=perl))
    tmp[which(tmp != "")]
}

#' segment texts into component elements
#' 
#' Segment text(s) into tokens, sentences, paragraphs, or other sections. 
#' \code{segment} works on a character vector or corpus object, and allows the 
#' delimiters to be defined.  See details.
#' @param x text or corpus object to be segmented
#' @param ... provides additional passed to the regular expression, such as \code{perl=TRUE},
#' or arguments to be passed to \link{clean} if \code{what=tokens},
#' @return A list of segmented texts, with each element of the list correponding
#'   to one of the original texts.
#' @details Tokens are delimited by Separators.  For sentences, the delimiter 
#'   can be defined by the user.  The default for sentences includes \code{.}, 
#'   \code{!}, \code{?}, plus \code{;} and \code{:}.
#'   
#'   For paragraphs, the default is two carriage returns, although this could be
#'   changed to a single carriage return by changing the value of 
#'  \code{delimiter} to \code{"\\\n{1}"} which is the R version of the 
#'   \code{\link{regex}} for one newline character.  (You might 
#'   need this if the document was created in a word processor, for instance, 
#'   and the lines were wrapped in the window rather than being hard-wrapped 
#'   with a newline character.)
#' @export
segment <- function(x, ...) {
    # warning("segment() is deprecated, use tokenize() instead.")
    UseMethod("segment")
}

#' @rdname segment
#' @param what unit of segmentation.  Current options are tokens, sentences, 
#'   paragraphs, and other.  Segmenting on \code{other} allows segmentation of a
#'   text on any user-defined value, and must be accompanied by the 
#'   \code{delimiter} argument.
#' @param delimiter  delimiter defined as a \code{\link{regex}} for segmentation. Each 
#'   type has its own default, except \code{other}, which requires a value to be
#'   specified.
#' @param perl logical. Should Perl-compatible regular expressions be used?
#' @export
#' @examples
#' # same as tokenize()
#' identical(tokenize(ukimmigTexts, lower=FALSE), segment(ukimmigTexts, lower=FALSE))
#' 
#' # segment into paragraphs
#' segment(ukimmigTexts[3:4], "paragraphs")
#' 
#' # segment a text into sentences
#' segmentedChar <- segment(ukimmigTexts, "sentences")
#' segmentedChar[2]
segment.character <- function(x, what=c("tokens", "sentences", "paragraphs", "tags", "other"), 
                              delimiter = ifelse(what=="tokens", " ", 
                                                 ifelse(what=="sentences", "[.!?:;]", 
                                                        ifelse(what=="paragraphs", "\\n{2}", 
                                                               ifelse(what=="tags", "##\\w+\\b", 
                                                                      NULL)))),
                              perl=FALSE,
                              ...) {
    what <- match.arg(what)
    if (what=="tokens") {
        return(tokenize(x, sep=delimiter, ...)) 
    } else if (what=="sentences") {
        # warning("consider using tokenize(x, what = \"sentence\") instead.")
        return(lapply(x, segmentSentence, delimiter, perl=perl)) 
    } else if (what=="paragraphs") {
        return(lapply(x, segmentParagraph, delimiter, perl=perl)) 
    } else if (what=="tags") {
        return(lapply(x, segmentParagraph, delimiter, perl=perl))         
    } else if (what=="other") {
        if (is.null(delimiter))
            stop("For type other, you must supply a delimiter value.")
        return(lapply(x, segmentParagraph, delimiter, perl=perl))
    }
}

#' @rdname segment
#' @export
#' @note Does not currently record document segments if segmenting a multi-text corpus
#' into smaller units. For this, use \link{changeunits} instead.
#' @examples
#' testCorpus <- corpus("##INTRO This is the introduction. 
#'                       ##DOC1 This is the first document.  
#'                       Second sentence in Doc 1.  
#'                       ##DOC3 Third document starts here.  
#'                       End of third document.")
#' testCorpusSeg <- segment(testCorpus, "tags")
#' summary(testCorpusSeg)
#' texts(testCorpusSeg)
#' # segment a corpus into sentences
#' segmentedCorpus <- segment(corpus(ukimmigTexts), "sentences")
#' identical(ndoc(segmentedCorpus), length(unlist(segmentedChar)))
segment.corpus <- function(x, what = c("tokens", "sentences", "paragraphs", "tags", "other"), 
                           delimiter = ifelse(what=="tokens", " ", 
                                              ifelse(what=="sentences", "[.!?:;]", 
                                                     ifelse(what=="paragraphs", "\\n{2}", 
                                                            ifelse(what=="tags", "##\\w+\\b", 
                                                                   NULL)))),
                           perl=FALSE,
                           ...) {
    newCorpus <- corpus(unlist(segment(texts(x), what, delimiter, perl=perl, ...)),
                        source = metacorpus(x, "source"),
                        notes = paste0("segment.corpus(", match.call(), ")"))
    
    if (what == "tags") {
        tagIndex <- gregexpr(delimiter, texts(x), perl=perl)[[1]]
        tags <- character()
        length(tags) <- ndoc(newCorpus)
        for (i in 1:length(tagIndex))
            tags[i] <- substr(texts(x), start = tagIndex[i],
                              stop = tagIndex[i] + attr(tagIndex, "match.length")[i] - 1)
        docvars(newCorpus, "tag") <- tags
    }
    
    newCorpus
}

# segment(ukimmigTexts[1], removePunct=FALSE, simplify=TRUE)
# segment(ukimmigTexts[1], what="sentences")
# segment(ukimmigTexts[1], what="paragraphs")


########
########  These functions grab the settings and tokenise the corpus
########  and store the results in a list called tokens
########


#' tokenize a set of texts
#'
#' Tokenize the texts from a character vector or from a corpus.
#' @rdname tokenize
#' @aliases tokenise
#' @param x The text(s) or corpus to be tokenized
#' @param ... additional arguments not used
#' @return A list of length \code{\link{ndoc}(x)} of the tokens found in each text.
#' @author Ken Benoit and Paul Nulty
#' @export
#' @examples 
#' # same for character vectors and for lists
#' tokensFromChar <- tokenize(inaugTexts[1:3])
#' tokensFromCorp <- tokenize(subset(inaugCorpus, Year<1798))
#' identical(tokensFromChar, tokensFromCorp)
#' str(tokensFromChar)
#' @export
tokenize <- function(x, ...) {
    UseMethod("tokenize")
}

#' @rdname tokenize
#' @aliases clean
#' @param what the unit for splitting the text, defaults to \code{"word"}. 
#'   Available alternatives are \code{c("character", "word", "line_break", 
#'   "sentence")}. See \link[stringi]{stringi-search-boundaries}.
#' @param removeNumbers remove tokens that consist only of numbers, but not 
#'   words that start with digits, e.g. \code{2day}
#' @param removePunct remove all punctuation
#' @param removeTwitter remove Twitter characters \code{@@} and \code{#}; set to
#'   \code{FALSE} if you wish to eliminate these.
#' @param removeHyphens if \code{TRUE}, split words that are connected by 
#'   hyphenation and hyphenation-like characters in between words, e.g. 
#'   \code{"self-storage"} becomes \code{c("self", "storage")}.  Default is
#'   \code{FALSE} to preserve such words as is, with the hyphens.  Only applies if 
#'   \code{what = "word"}.
#' @param removeSeparators remove Separators and separator characters (spaces 
#'   and variations of spaces, plus tab, newlines, and anything else in the 
#'   Unicode "separator" category) when \code{removePunct=FALSE}.  Only 
#'   applicable for \code{what = "character"} (when you probably want it to be 
#'   \code{FALSE}) and for \code{what = "word"} (when you probably want it to be
#'   \code{TRUE}).  Note that if \code{what = "word"} and you set 
#'   \code{removePunct = TRUE}, then \code{removeSeparators} has no effect.  Use
#'   carefully.
#' @param ngrams integer vector of the \emph{n} for \emph{n}-grams, defaulting 
#'   to \code{1} (unigrams). For bigrams, for instance, use \code{2}; for 
#'   bigrams and unigrams, use \code{1:2}.  You can even include irregular 
#'   sequences such as \code{2:3} for bigrams and trigrams only.
#' @param window integer vector specifying the adjacency width for tokens 
#'   forming the \emph{n}-grams, default is 1 for only immediately neighbouring 
#'   words. Only applies if \code{ngrams} is different from the default of 1.
#' @param concatenator character to use in concatenating \emph{n}-grams, default
#'   is "\code{_}", which is recommended since this is included in the regular 
#'   expression and Unicode definitions of "word" characters
#' @param simplify if \code{TRUE}, return a character vector of tokens rather 
#'   than a list of length \code{\link{ndoc}(texts)}, with each element of the 
#'   list containing a character vector of the tokens corresponding to that 
#'   text.
#' @param verbose if \code{TRUE}, print timing messages to the console; off by 
#'   default
#' @import stringi
#' @details The tokenizer is designed to be fast and flexible as well as to 
#'   handle Unicode correctly. Most of the time, users will construct \link{dfm}
#'   objects from texts or a corpus, without calling \code{tokenize()} as an 
#'   intermediate step.  Since \code{tokenize()} is most likely to be used by 
#'   more technical users, we have set its options to default to minimal 
#'   intervention. This means that punctuation is tokenized as well, and that 
#'   nothing is removed from the
#' @return a \strong{tokenizedText} (S3) object, essentially a list of character
#'   vectors. If \code{simplify = TRUE} then return a single character vector.
#' @note This replaces an older function named \code{clean()}, removed from 
#'   \pkg{quanteda} in version 0.8.1.  "Cleaning" by removing certain parts of 
#'   texts, such as punctuation or numbers, only only works on tokenized texts, 
#'   although texts of any length can be converted to lower case using 
#'   \code{\link{toLower}}.
#' @export
#' @seealso \code{\link{ngrams}}
#' @examples 
#' # returned as a list
#' head(tokenize(inaugTexts[57])[[1]], 10)
#' # returned as a character vector using simplify=TRUE
#' head(tokenize(inaugTexts[57], simplify=TRUE), 10)
#' 
#' # removing punctuation marks and lowecasing texts
#' head(tokenize(toLower(inaugTexts[57]), simplify=TRUE, removePunct=TRUE), 30)
#' # keeping case and punctuation
#' head(tokenize(inaugTexts[57], simplify=TRUE), 30)
#' # keeping versus removing hyphens
#' tokenize("quanteda data objects are auto-loading.", removePunct = TRUE)
#' tokenize("quanteda data objects are auto-loading.", removePunct = TRUE, removeHyphens = TRUE)
#' 
#' ## MORE COMPARISONS
#' txt <- "#textanalysis is MY <3 4U @@myhandle gr8 #stuff :-)"
#' tokenize(txt, removePunct=TRUE)
#' tokenize(txt, removePunct=TRUE, removeTwitter=TRUE)
#' #tokenize("great website http://textasdata.com", removeURL=FALSE)
#' #tokenize("great website http://textasdata.com", removeURL=TRUE)
#' 
#' txt <- c(text1="This is $10 in 999 different ways,\n up and down; left and right!", 
#'          text2="@@kenbenoit working: on #quanteda 2day\t4ever, http://textasdata.com?page=123.")
#' tokenize(txt, verbose=TRUE)
#' tokenize(txt, removeNumbers=TRUE, removePunct=TRUE)
#' tokenize(txt, removeNumbers=FALSE, removePunct=TRUE)
#' tokenize(txt, removeNumbers=TRUE, removePunct=FALSE)
#' tokenize(txt, removeNumbers=FALSE, removePunct=FALSE)
#' tokenize(txt, removeNumbers=FALSE, removePunct=FALSE, removeSeparators=FALSE)
#' 
#' # character level
#' tokenize("Great website: http://textasdata.com?page=123.", what="character")
#' tokenize("Great website: http://textasdata.com?page=123.", what="character", 
#'          removeSeparators=FALSE)
#' 
#' # sentence level         
#' tokenize(c("Kurt Vongeut said; only assholes use semi-colons.", 
#'            "Today is Thursday in Canberra:  It is yesterday in London.", 
#'            "Today is Thursday in Canberra:  \nIt is yesterday in London.",
#'            "To be?  Or\not to be?"), 
#'           what = "sentence")
#' tokenize(inaugTexts[c(2,40)], what = "sentence", simplify = TRUE)
#' 
#' # creating ngrams
#' txt <- toLower(c(mytext1 = "This is a short test sentence.",
#'                 mytext2 = "Short.",
#'                 mytext3 = "Short, shorter, and shortest."))
#' tokenize(txt, removePunct = TRUE)
#' removeFeatures(tokenize(txt, removePunct = TRUE), stopwords("english"))
#' tokenize(txt, removePunct = TRUE, ngrams = 2)
#' tokenize(txt, removePunct = TRUE, ngrams = 1:2)
#' tokenize(txt, removePunct = TRUE, ngrams = 2, window = 2, concatenator = " ")
#' removeFeatures(tokenize(txt, removePunct = TRUE, ngrams = 1:2), stopwords("english"))
tokenize.character <- function(x, what=c("word", "sentence", "character", "fastestword", "fasterword"),
                               removeNumbers = FALSE, 
                               removePunct = FALSE,
                               removeSeparators = TRUE,
                               removeTwitter = FALSE,
                               removeHyphens = FALSE,
                               # removeURL = TRUE,
                               ngrams = 1L,
                               window = 1L,
                               concatenator = "_",
                               simplify = FALSE,
                               verbose = FALSE,  ## FOR TESTING
                               ...) {
    
    what <- match.arg(what)

    if (!is.integer(ngrams)) ngrams <- as.integer(ngrams)
    
    if (verbose) cat("Starting tokenization...\n")
    result <- x
    
    if (removeTwitter == FALSE & !(what %in% c("fastword", "fastestword"))) {
        if (verbose) cat("  ...preserving Twitter characters (#, @)")
        startTimeClean <- proc.time()
        result <- stringi::stri_replace_all_fixed(result, c("#", "@"), c("_ht_", "_as_"), vectorize_all = FALSE)
        if (verbose) cat("...total elapsed:", (proc.time() - startTimeClean)[3], "seconds.\n")
    }
    
    if (verbose) cat("  ...tokenizing texts")
    startTimeTok <- proc.time()
    
    if (what == "fasterword" | what == "fastestword") {
        
        if (verbose & removeNumbers==TRUE) cat(", removing numbers")
        if (verbose & removePunct==TRUE) cat(", removing punctuation")
        regexToEliminate <- paste0(ifelse(removeNumbers, "\\b\\d+\\b|", ""),
                                   ifelse(removePunct, paste0("(?![", ifelse(removeTwitter, "_", "@#_"), "])[[:punct:]]"), "|"))
        if (regexToEliminate != "|")
            result <- stri_replace_all_regex(result, regexToEliminate, "")
        
        if (verbose & removePunct==TRUE) cat(", ", what, "tokenizing", sep="")
        if (what=="fastestword")
            result <- stringi::stri_split_fixed(result, " ")
        else if (what=="fasterword")
            result <- stringi::stri_split_regex(result, "\\s")
        result <- lapply(result, function(x) x <- x[which(x != "")])
        
    } else if (what == "character") {
        
        # note: does not implement removeNumbers
        result <- stringi::stri_split_boundaries(result, type = "character")
        if (removePunct) {
            if (verbose) cat("   ...removing punctuation.\n")
            result <- lapply(result, stringi::stri_replace_all_charclass, "[\\p{P}\\p{S}]", "")
            result <- lapply(result, function(x) x <- x[which(x != "")])
        } 
        if (removeSeparators) {
            if (verbose) cat("   ...removing separators.\n")
            result <- lapply(result, function(x) x[!stringi::stri_detect_regex(x, "^\\s$")])
        }
        
        
    } else if (what == "word") {
        
        # to preserve intra-word hyphens, replace with _hy_
        if (!removeHyphens & removePunct)
            result <- stri_replace_all_regex(result, "(\\w)[\\p{Pd}](\\w)", "$1_hy_$2")
        else if (removeHyphens)
            result <- stri_replace_all_regex(result, "(\\w)[\\p{Pd}](\\w)", "$1 $2")
            
        result <- stringi::stri_split_boundaries(result, 
                                                 type = "word", 
                                                 skip_word_none = removePunct, # this is what obliterates currency symbols, Twitter tags, and URLs
                                                 skip_word_number = removeNumbers) # but does not remove 4u, 2day, etc.
        # put hyphens back the fast way
        if (!removeHyphens & removePunct)
            result <- lapply(result, stri_replace_all_fixed, "_hy_", "-")
        # remove separators if option is TRUE
        if (removeSeparators & !removePunct) {
            if (verbose) cat("\n   ...removing separators.")
            result <- lapply(result, function(x) x[!stri_detect_regex(x, "^\\s$")])
        }

    } else if (what == "sentence") {
        if (verbose) cat("\n   ...separating into sentences.")
        
        # replace . delimiter from common title abbreviations, with _pd_
        exceptions <- c("Mr", "Mrs", "Ms", "Dr", "Jr", "Prof", "Ph.D", "M", "MM")
        findregex <- paste0("\\b(", exceptions, ")\\.")
        result <- stri_replace_all_regex(result, findregex, "$1_pd_", vectorize_all = FALSE)

        result <- stringi::stri_split_boundaries(result, type = "sentence")
        ## remove newline chars and trailing spaces for sentence tokenization
        result <- lapply(result, stringi::stri_replace_all_fixed, "\n", "")
        result <- lapply(result, stringi::stri_trim_right)
        # remove any "sentences" that were completely blanked out
        result <- lapply(result, function(x) x <- x[which(x != "")])
        
        # replace the non-full-stop "." characters
        result <- lapply(result, stri_replace_all_fixed, "_pd_", ".")

    } else {
        stop(what, " not implemented in tokenize().")
    }

    if (verbose) cat("...total elapsed: ", (proc.time() - startTimeTok)[3], "seconds.\n")
    
    if (removeTwitter == FALSE & !(what %in% c("fastword", "fastestword"))) {
        if (verbose) cat("  ...replacing Twitter characters (#, @)")
        startTimeClean <- proc.time()
        result <- lapply(result, stringi::stri_replace_all_fixed, c("_ht_", "_as_"), c("#", "@"), vectorize_all = FALSE)
        if (verbose) cat("...total elapsed:", (proc.time() - startTimeClean)[3], "seconds.\n")
    }
    
    # make this an S3 class item, if a list
    #if (simplify == FALSE) {
        class(result) <- c("tokenizedTexts", class(result))
    #}

    if (!identical(ngrams, 1L)) {
        if (verbose) {
            cat("  ...creating ngrams")
            startTimeClean <- proc.time()
        }
        result <- ngrams(result, n = ngrams, window = window, concatenator = concatenator)
        # is the ngram set serial starting with 1? use single call if so (most efficient)
        # if (sum(1:length(ngrams)) == sum(ngrams)) {
        #     result <- lapply(result, ngram, n = length(ngrams), concatenator = concatenator, include.all = TRUE)
        # } else {
#             result <- lapply(result, function(x) {
#                 xnew <- c()
#                 for (n in ngrams) 
#                     xnew <- c(xnew, ngram(x, n, concatenator = concatenator, include.all = FALSE))
#                 xnew
#             })
        # }
        if (verbose) cat("...total elapsed:", (proc.time() - startTimeClean)[3], "seconds.\n")
    }

    if (simplify == FALSE) {
        # stri_* destroys names, so put them back
        startTimeClean <- proc.time()
        if (verbose) cat("  ...replacing names")
        names(result) <- names(x)
        if (verbose) cat("...total elapsed: ", (proc.time() - startTimeClean)[3], "seconds.\n")
    } else {
        # or just return the tokens as a single character vector
        if (verbose) cat("  ...unlisting results.\n")
        result <- unlist(result)
    }
    
    if (verbose) 
        cat("Finished tokenizing and cleaning", format(length(result), big.mark=","), "texts.\n") 
    #, with a total of", format(length(unlist(result)), big.mark=","), "tokens.\n")

    # make this an S3 class item, if a list
    if (simplify == FALSE & !is.tokenizedTexts(result)) {
        class(result) <- c("tokenizedTexts", class(result))
    }
    
    # add settings for ngrams and concatenator
    attr(result, "ngrams") <- ngrams
    attr(result, "concatenator") <- ifelse(all.equal(ngrams, 1L)==TRUE, "", concatenator)

    result
}

#' @rdname tokenize
#' @export
tokenize.corpus <- function(x, ...) {
    # get the settings for clean from the corpus and use those, 
    # unless more specific arguments are passed -- ADD THE ABILITY TO PASS THESE
    # need to include sep in this list too 
    tokenize(texts(x), ...)
}


#' @export
#' @description \code{is.tokenizedTexts} returns \code{TRUE} if the object is of class tokenizedTexts, \code{FALSE} otherwise.
#' @rdname tokenize
is.tokenizedTexts <- function(x) {
    ifelse("tokenizedTexts" %in% class(x), TRUE, FALSE)
}

#' print a tokenizedTexts objects
#' 
#' print method for a \link{tokenize}dText object
#' @param x a tokenizedText object created by \link{tokenize}
#' @param ... further arguments passed to base print method
#' @export
#' @method print tokenizedTexts
print.tokenizedTexts <- function(x, ...) {
    ndocuments <- ifelse(is.list(x), length(x), 1)
    cat("tokenizedText object from ", ndocuments, " document", 
        ifelse(ndocuments > 1, "s", ""), ".\n", sep = "")
    if (is.list(x)) { 
        class(x) <- "listof"
        print(x, ...)
    } else {
        x <- as.character(x)
        print(x, ...)
    }
}

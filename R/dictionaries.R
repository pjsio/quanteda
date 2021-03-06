# @rdname dictionary
# @export 
# NEED TO ADD A VALIDATOR
setClass("dictionary", contains = "list")

#' print a dictionary object
#' 
#' Print/show method for dictionary objects.
#' @param object the dictionary to be printed
#' @export
setMethod("show", "dictionary", 
          function(object) {
              cat("Dictionary object with", length(object), "key entries.\n")
              keys <- names(object)
              lapply(seq_along(object), 
                     function(i, object, keys)
                         cat(" - ", keys[i], ": ", paste(object[[i]], collapse = ", "), "\n", sep = ""),
                     object = object, keys = names(object))
              
              # print(setClass("list", object))
          })

#' create a dictionary
#' 
#' Create a quanteda dictionary, either from a list or by importing from a 
#' foreign format.  Currently supported formats are the Wordstat and LIWC 
#' formats.
#' @param x a list of character vector dictionary entries, including regular 
#'   expressions (see examples)
#' @param file file identifier for a foreign dictionary
#' @param format character identifier for the format of the foreign dictionary. 
#'   Available options are: \describe{ \item{\code{"wordstat"}}{format used by
#'   Provalis Research's Wordstat software} \item{\code{"LIWC"}}{format used by
#'   the Linguistic Inquiry and Word Count software} }
#' @param enc optional encoding value for reading in imported dictionaries. 
#'   This uses the \link{iconv} labels for encoding.  See the "Encoding" section
#'   of the help for \link{file}.
#' @param tolower if \code{TRUE}, convert all dictionary functions to lower
#' @param maxcats optional maximum categories to which a word could belong in a 
#'   LIWC dictionary file, defaults to 10 (which is more than the actual LIWC 
#'   2007 dictionary uses).  The default value of 10 is likely to be more than 
#'   enough.
#' @return A dictionary class object, essentially a specially classed named list
#'   of characters.
#' @note We will eventually change this to an S4 class with validators and
#'   additional methods.
#' @references Wordstat dictionaries page, from Provalis Research 
#' \url{http://provalisresearch.com/products/content-analysis-software/wordstat-dictionary/}.
#' 
#' Pennebaker, J.W., Chung, C.K., Ireland, M., Gonzales, A., & Booth, R.J. 
#' (2007). The development and psychometric properties of LIWC2007. [Software 
#' manual]. Austin, TX (\url{www.liwc.net}).
#' @seealso \link{dfm}
#' @examples
#' mycorpus <- subset(inaugCorpus, Year>1900)
#' mydict <- 
#'     dictionary(list(christmas=c("Christmas", "Santa", "holiday"),
#'                     opposition=c("Opposition", "reject", "notincorpus"),
#'                     taxing="taxing",
#'                     taxation="taxation",
#'                     taxregex="tax*",
#'                     country="united states"))
#' dfm(mycorpus, dictionary=mydict)                     
#' \dontrun{
#' # import the Laver-Garry dictionary from http://bit.ly/1FH2nvf
#' lgdict <- dictionary(file="http://www.kenbenoit.net/courses/essex2014qta/LaverGarry.cat",
#'                      format="wordstat")
#' dfm(inaugTexts, dictionary=lgdict)
#' 
#' # import a LIWC formatted dictionary
#' liwcdict <- dictionary(file = "http://www.kenbenoit.net/files/LIWC2001_English.dic",
#'                        format = "LIWC")
#' dfm(inaugTexts, dictionary=liwcdict)
#' }
#' @export
dictionary <- function(x=NULL, file=NULL, format=NULL, enc="", tolower=TRUE, maxcats=25) {
    if (!is.null(x) & !is.list(x))
        stop("Dictionaries must be named lists.")
    x <- flatten.dictionary(x)
    if (!is.null(x) & !is.list(x))
        stop("Dictionaries must be named lists or lists of named lists.")
    
    if (!is.null(file)) {
        if (is.null(format))
            stop("You must specify a format for file", file)
        format <- match.arg(format, c("wordstat", "LIWC"))
        if (format=="wordstat") 
            x <- readWStatDict(file, enc = enc, lower = tolower)
        else if (format=="LIWC") 
            x <- readLIWCdict(file, maxcats = maxcats, enc = enc)
    }
    
    new("dictionary", x)
}


# Import a Wordstat dictionary
# 
# Make a flattened list from a hierarchical wordstat dictionary
# 
# @param path full pathname of the wordstat dictionary file (usually ending in .cat)
# @param enc a valid input encoding for the file to be read, see \link{iconvlist}
# @param lower if \code{TRUE} (default), convert the dictionary entries to lower case
# @return a named list, where each the name of element is a bottom level
#   category in the hierarchical wordstat dictionary. Each element is a list of
#   the dictionary terms corresponding to that level.
# @author Kohei Watanabe, Kenneth Benoit
# @export
# @examples
# \dontrun{
# path <- '~/Dropbox/QUANTESS/corpora/LaverGarry.cat'
# lgdict <- readWStatDict(path)
# }
readWStatDict <- function(path, enc="", lower=TRUE) {
    d <- utils::read.delim(path, header=FALSE, fileEncoding=enc)
    d <- data.frame(lapply(d, as.character), stringsAsFactors=FALSE)
    thismajorcat <- d[1,1]
    # this loop fills in blank cells in the category|term dataframe
    for (i in 1:nrow(d)) {
        if (d[i,1] == "") {
            d[i,1] <- thismajorcat
        } else {
            thismajorcat <- d[i,1]
        }
        for (j in 1:(ncol(d)-1)) {
            if(d[i,j] == "" & length(d[i-1,j])!=0) {
                d[i,j] <- d[i-1,j] 
            }
        }
        if (nchar(d[i,ncol(d)-1]) > 0) {
            pat <- c("\\(")
            if (!length(grep(pat, d[i,ncol(d)-1]))==0) {
                d[i, ncol(d)] <- d[i, ncol(d)-1]
                d[i, ncol(d)-1] <- "_"
            }
        }
    }
    flatDict <- list()
    categ <- list()

    # this loop collapses the category cells together and
    # makes the list of named lists compatible with dfm
    for (i in 1:nrow(d)){
        if (d[i,ncol(d)]=='') next
        categ <- unlist(paste(d[i,(1:(ncol(d)-1))], collapse="."))
        w <- d[i, ncol(d)]
        w <- unlist(strsplit(w, '\\('))[[1]]
        if (lower) w <- tolower(w)
        # w <- gsub(" ", "", w)
        flatDict[[categ]] <- append(flatDict[[categ]], c(w))
    }
    # remove any left-over whitespace
    flatDict <- lapply(flatDict, function(x) gsub("\\s", "", x, perl=TRUE))
    return(flatDict)
}




# old code:
# makes a list of lists from a two-level wordstat dictionary
readWStatDictNested <- function(path) {
    lines <- readLines(path)
    allDicts <- list()
    curDict <- list()
    n <- list()
    for (i in 1:length(lines)) {
        word <- unlist(strsplit(lines[i], '\\('))[[1]]
        #if it doesn't start with a tab, it's a category
        if (substr(word,1,1) != "\t") {
            n <- c(n,word)
            if(length(curDict) >0) allDicts = c(allDicts, list(word=c(curDict)))
            curDict = list()
        } else {
            word <- gsub(' ','', word)
            curDict = c(curDict, gsub('\t','',(word)))
        } 
    }
    # add the last dicationary
    allDicts = c(allDicts, list(word=c(curDict)))
    names(allDicts) <- n
    return(allDicts)
}

# Import a LIWC-formatted dictionary
# 
# Make a flattened dictionary list object from a LIWC dictionary file.
# @param path full pathname of the LIWC-formatted dictionary file (usually a
#   file ending in .dic)
# @param enc a valid input encoding for the file to be read, see 
#   \link{iconvlist}
# @param maxcats the maximum number of categories to read in, set by the 
#   maximum number of dictionary categories that a term could belong to.  For 
#   non-exclusive schemes such as the LIWC, this can be up to 7.  Set to 10 by 
#   default, which ought to be more than enough.
# @return a dictionary class named list, where each the name of element is a
#   bottom level category in the hierarchical wordstat dictionary. Each element
#   is a list of the dictionary terms corresponding to that level.
# @author Kenneth Benoit
# @export
# @examples \dontrun{ 
# LIWCdict <- readLIWCdict("~/Dropbox/QUANTESS/corpora/LIWC/LIWC2001_English.dic") }
readLIWCdict <- function(path, maxcats=25, enc="") {
    # read in the dictionary as a (big, uneven) table
    d <- utils::read.table(path, header=FALSE, fileEncoding=enc,
                           col.names=c("category", paste("catno", 1:maxcats)),
                           fill=TRUE, stringsAsFactors=FALSE)
    # get the row number that signals the end of the category guide
    guideRowEnd <- max(which(d$category=="%"))
    if(guideRowEnd < 1){
        stop('Expected a guide (a category legend) delimited by percentage symbols at start of file, none found')
    }
    # extract the category guide
    guide <- d[2:(guideRowEnd-1), 1:2]
    colnames(guide) <- c('catNum', 'catName' )
    guide$catNum <- as.numeric(guide$catNum)
    # initialize the dictionary as list of NAs
    dictionary <- list()
    length(dictionary) <- nrow(guide)
    # assign category labels as list element names
    names(dictionary) <- guide[,2]
    
    # make a list of terms with their category numbers
    catlist <- d[(guideRowEnd+1):nrow(d), ]
    
    mergeNums <- function(x, y) {
        # helper function    
        result <- sort(unique(c(as.numeric(x), as.numeric(y))))
        if (length(result) > length(x))
            stop("too long: try increasing maxcats")
        if (length(result) < length(x))
            result <- c(result, rep(NA, length(x) - length(result)))
        result
    }
    
    consolidateCatlist <- function(catlist) {
        dups <- which(duplicated(catlist[, 1]))
        # cat("Found duplicates at rows:", dups, "\n\n")
        while (length(dups)) {
            # cat("Duplicates = ", length(dups), "\n\n")
            i <- dups[1]
            # cat("merging row [", i-1, "]", catlist[i-1, 1], as.numeric(catlist[i-1, 2:ncol(catlist)]), "\n")
            # cat("   with row [", i, "]", catlist[i, 1], as.numeric(catlist[i, 2:ncol(catlist)]), "\n")
            catlist[i-1, 2:ncol(catlist)] <- mergeNums(catlist[i-1, 2:ncol(catlist)], catlist[i, 2:ncol(catlist)])
            catlist <- catlist[-i, ]
            # cat("   NEW row [", i-1, "]", catlist[i-1, 1], as.numeric(catlist[i-1, 2:ncol(catlist)]), "\n\n")
            dups <- dups[-1] - 1 
        }
        catlist
    }
    
    # save(catlist, file = "~/Desktop/catlist.Rdata")
    
    catlist <- catlist[order(catlist[,1]), ]
    # merge key categories of duplicate terms - this makes the function work with some LIWC-supplied
    # dictionaries that repeat term entries across different lines
    dups <- which(duplicated(catlist[, 1]))
    if (length(dups)) {
        cat("Found", length(dups), "duplicated entries, and merged them.\n")
        catlist <- consolidateCatlist(catlist)
    }

    # path <- "~/Dropbox/Papers/EUP_Kansas/analysis/Dictionaries/LIWC2007_French_UTF8.dic"; maxcats=15; enc=""
    # path <- "~/Dropbox/Papers/EUP_Kansas/analysis/Dictionaries/TESTDIC.dic"; maxcats=15; enc=""
    
    rownames(catlist) <- catlist[,1]
    catlist <- catlist[, -1]
    suppressWarnings(catlist <- apply(catlist, c(1,2), as.numeric))
    # now put this into a (ragged) list 
    terms <- as.list(rep(NA, nrow(catlist)))
    names(terms) <- rownames(catlist)
    for (i in 1:nrow(catlist)) {
        terms[[i]] <- as.numeric(catlist[i, !is.na(catlist[i,])])
    }

    for(ind in 1:length(terms)){
        for(num in as.numeric(terms[[ind]])){
            thisCat <- guide$catName[which(guide$catNum==num)]
            thisTerm <- names(terms[ind])
            dictionary[[thisCat]] <- append(dictionary[[thisCat]], thisTerm)
        }
    }
    return(dictionary)
}

#readLIWCdict("~/Dropbox/QUANTESS/corpora/LIWC/LIWC2001_English.dic")


flatten.dictionary <- function(elms, parent = '', dict = list()) {
    for (self in names(elms)) {
        elm <- elms[[self]]
        if (parent != '') {
            self <- paste(parent, self, sep='.')
        }
        # print("-------------------")
        # print (paste("Name", self))
        if (is.list(elm)) {
            # print("List:")
            # print(names(elm))
            dict <- flatten.dictionary(elm, self, dict)
        } else {
            # print("Words:")
            dict[[self]] <- elm
            # print(dict)
        }
    }
    return(dict)
}

#' apply a dictionary or thesarus to an object
#' 
#' Convert features into equivalence classes defined by values of a dictionary
#' object.  
#' @note Selecting only features defined in a "dictionary" is traditionally
#' known in text analysis as a dictionary method, even though technically this is more like a thesarus.
#' If a more truly thesaurus-like application is desired, set \code{keeponly = FALSE} to convert features 
#' defined as values in a dictionary into their keys, while keeping all other features.
#' @return an object of the type passed with the value-matching features replaced by dictionary keys
#' @param x object to which dictionary or thesaurus will be supplied
#' @param dictionary the \link{dictionary}-class object that will be applied to \code{x}
#' @export
applyDictionary <- function(x, dictionary, ...) {
    UseMethod("applyDictionary")
}

#' @rdname applyDictionary
#' @param exclusive if \code{TRUE}, remove all features not in dictionary, 
#'   otherwise, replace values in dictionary keys with keys while leaving other 
#'   features unaffected
#' @param valuetype how to interpret dictionary values: \code{"glob"} for 
#'   "glob"-style wildcard expressions (the format used in Wordstat and LIWC
#'   formatted dictionary values); \code{"regex"} for regular expressions; or
#'   \code{"fixed"} for exact matching (entire words, for instance)
#' @param case_insensitive ignore the case of dictionary values if \code{TRUE}
#' @param capkeys if \code{TRUE}, convert dictionary or thesaurus keys to 
#'   uppercase to distinguish them from other features
#' @param verbose print status messages if \code{TRUE}
#' @param ... not used
#' @export
#' @examples
#' myDict <- dictionary(list(christmas = c("Christmas", "Santa", "holiday"),
#'                           opposition = c("Opposition", "reject", "notincorpus"),
#'                           taxglob = "tax*",
#'                           taxregex = "tax.+$",
#'                           country = c("United_States", "Sweden")))
#' myDfm <- dfm(c("My Christmas was ruined by your opposition tax plan.", 
#'                "Does the United_States or Sweden have more progressive taxation?"),
#'              ignoredFeatures = stopwords("english"), verbose = FALSE)
#' myDfm
#' 
#' # glob format
#' applyDictionary(myDfm, myDict, valuetype = "glob")
#' applyDictionary(myDfm, myDict, valuetype = "glob", case_insensitive = FALSE)
#'
#' # regex v. glob format: note that "united_states" is a regex match for "tax*"
#' applyDictionary(myDfm, myDict, valuetype = "glob")
#' applyDictionary(myDfm, myDict, valuetype = "regex", case_insensitive = TRUE)
#' 
#' # fixed format: no pattern matching
#' applyDictionary(myDfm, myDict, valuetype = "fixed")
#' applyDictionary(myDfm, myDict, valuetype = "fixed", case_insensitive = FALSE)
applyDictionary.dfm <- function(x, dictionary, exclusive = TRUE, valuetype = c("glob", "regex", "fixed"), 
                                case_insensitive = TRUE,
                                capkeys = !exclusive,
                                verbose = TRUE, ...) {
    valuetype <- match.arg(valuetype)
    dictionary <- flatten.dictionary(dictionary)
    
    if (verbose) cat("applying a dictionary consisting of ", length(dictionary), " key", 
                     ifelse(length(dictionary) > 1, "s", ""), "\n", sep="")
    
    # convert wildcards to regular expressions (if needed)
    if (valuetype == "glob") {
        dictionary <- lapply(dictionary, utils::glob2rx)
    } # else if (valuetype == "fixed")
    # dictionary <- lapply(dictionary, function(x) paste0("^", x, "$"))
    
    newDocIndex <- rep(1:nrow(x), length(dictionary))
    newFeatures <- names(dictionary)
    uniqueFeatures <- features(x)
    newFeatureIndexList <- lapply(dictionary, function(x) {
        # ind <- grep(paste(x, collapse = "|"), uniqueFeatures, ignore.case = case_insensitive)
        if (valuetype == "fixed") {
            if (case_insensitive)  
                ind <- which(toLower(uniqueFeatures) %in% (toLower(x)))
            else ind <- which(uniqueFeatures %in% x)
        }
        else ind <- which(stringi::stri_detect_regex(uniqueFeatures, paste(x, collapse = "|"), case_insensitive = case_insensitive))
        if (length(ind) == 0)
            return(NULL)
        else 
            return(ind)
    })
    if (capkeys) newFeatures <- stringi::stri_trans_toupper(newFeatures)
    newFeatureCountsList <- lapply(newFeatureIndexList,
                                   function(i) {
                                       if (!is.null(i)) 
                                           rowSums(x[, i])
                                       else 
                                           rep(0, nrow(x))
                                   })
    dfmresult2 <- sparseMatrix(i = newDocIndex,
                               j = rep(1:length(dictionary), each = ndoc(x)),
                               x = unlist(newFeatureCountsList),
                               dimnames=list(docs = docnames(x), 
                                             features = newFeatures))
    if (!exclusive) {
        keyIndex <- unlist(newFeatureIndexList, use.names = FALSE)
        dfmresult2 <- cbind(x[, -keyIndex], dfmresult2)
    }
    
    new("dfmSparse", dfmresult2)
}


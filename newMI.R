library(RWeka); library(tm); library(data.table)
newMI <- function(direc, n = 6, delimiters = "\\W+", encoding = "UTF-8", cutoff.freq = 2, cutoff.mi = 3, ...) {
  # create a corpus
  corpus <- Corpus(DirSource(direc, recursive = TRUE, encoding = encoding, ...))

  # compute occurrence probabilities of each 1- to n-gram
  table.p <- list()
  op <- options()
  options(mc.cores = 1)
  for (i in seq(n)) {
    tokenizer <- function(x) NGramTokenizer(x, Weka_control(min = i, max = i, delimiters = delimiters))
    tdm <- TermDocumentMatrix(corpus, control = list(tokenize = tokenizer, wordLengths = c(1, Inf)))
    dt <- data.table(freq = tdm$v, ngram = tdm$i, key = "ngram")
    freq <- dt[ , sum(freq), by = ngram]$V1
    table.p[[i]] <- data.table(ngram = rownames(tdm), freq = freq, prob = prop.table(freq), key = "ngram")
  }
  options(op)

  # calculate new MI scores
  token.dt <- list()
  # Repeat for each n-gram	
  for (g in 2:n) {
    d <- g - 1 # number of dispersions
    words.dt <- data.table(matrix(unlist(strsplit(table.p[[g]]$ngram, " ")), byrow = TRUE, ncol = g))
    nrow <- nrow(words.dt)
    E <- former <- latter <- matrix(NA, ncol = d, nrow = nrow)

    for (i in seq(d)) {
      if (i == 1) {
        forward <- words.dt[[1]]
        backward <- words.dt[[g]]
      } else {
        forward <- paste(forward, words.dt[[i]])
        backward <- paste(words.dt[[g - i + 1]] , backward)
      }  
      former[ , i] <- table.p[[i]]$prob[match(forward, table.p[[i]][ , ngram])]
      latter[ , g - i] <- table.p[[i]]$prob[match(backward, table.p[[i]][ , ngram])]
    }

    E <- former * latter
    WAPs <- rowSums(prop.table(E, margin = 1) * E)
    words.dt[ , paste0("mi", g) := log2(table.p[[g]]$prob / WAPs)]
    token.dt[[g]] <- copy(words.dt)
  }

  # delete the partially overlapping sequences with smaller MI scores
  for (i in 2:n) setkeyv(token.dt[[i]], paste0("V", 1:i))
  retain <- list()
  for (i in 2:n) {
    if (i == 2) {
      retain.dt <- token.dt[[3]][token.dt[[2]], list(k = all(mi2 > mi3), mi2), allow.cartesian = TRUE][(k)]
    } else if (i == n) {
      q <- parse(text = paste0("list(k = all(mi", i, " > mi", i - 1, "), mi", i, ")"))
      tmp <- token.dt[[i]][token.dt[[i - 1]], allow.cartesian = TRUE]
      retain.dt <- tmp[ , eval(q), by = c(paste0("V", 1:i))][(k)]
    } else {
      q <- parse(text = paste0("list(k = all(mi", i, " > max(mi", i - 1, ", mi", i + 1, ")), mi", i, ")"))
      retain.dt <- token.dt[[i + 1]][token.dt[[i]][token.dt[[i - 1]], allow.cartesian = TRUE], eval(q), allow.cartesian = TRUE][(k)]
    }
    
    retain.df <- data.frame(retain.dt)
    fc <- sapply(retain.df, is.factor)
    retain.df[fc] <- lapply(retain.df[fc], as.character)
    ngrams <- apply(retain.df[ , 1:i], 1, paste, collapse = " ")
    ngrams.freq <- table.p[[i]]$freq[match(ngrams, table.p[[i]]$ngram)]
    retain[[i]] <- data.frame(Ngram = ngrams, N = i, Frequency = ngrams.freq, MI = retain.df[ , ncol(retain.df)], stringsAsFactors = FALSE)
  }

  mi.df <- rbindlist(retain)
  mi.df <- mi.df[mi.df$MI >= cutoff.mi & mi.df$Frequency >= cutoff.freq, ]
  return(data.frame(mi.df))
}



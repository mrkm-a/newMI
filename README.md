newMI()
=====

### Description ###
This is an R implementation of the algorithm proposed in Wei &amp; Li (2013) published on *International Journal of Corpus Linguistics* ([Link to the paper](http://www.ingentaconnect.com/content/jbp/ijcl/2013/00000018/00000004/art00003)). The algorithm is an extention of MI score to 3- and higher *n*-grams and retrieves semantically meaningful phraseological sequences. You need to have installed the following packages for the function to work; *RWeka*, *tm*, and *data.table*. The function *newMI()* returns a data frame with the phraseological sequences identified through the algorithm, the *n* in *n*-grams, their absolute frequency, and their corresponding MI scores. Please see the original paper for the details of the algorithm.

### Arguments ###
The arguments the function takes are the following:
* direc 
  - the directory with the text files. This argument is obligatory.
* n
  - the maximum *n* in *n*-grams that are targetted.
  - It defauls to 6, which means the function returns the 2- to 6-grams that characterise the corpus.
* delimiters
  - the boundary to tokenize.
  - It defaults to "\\W+", which means a word is defined as any sequence of [0-9a-zA-Z_].
* encoding
  - encoding of the text files.
  - It defauls to UTF-8.
* cutoff.freq
  - the minimum absolute frequency of the *n*-grams to be returned.
  - It defauls to 2.
* cutoff.mi
  - the minimum MI score of the *n*-grams to be returned.
  - It defauls to 3.
* ...
  - other arguments passed to the *DirSource* function in the tm package.

### Example ###
direc <- "(path to a directory with text files)"  
ps <- newMI(direc, cutoff.freq = 5, pattern = ".txt")  

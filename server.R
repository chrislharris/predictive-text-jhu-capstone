#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
load("nGram_med.rData")

### Load stop word list
stop_words <- t(read.csv("stop_words.txt", header=FALSE))

#nGramsIntialized <<- FALSE
fourGramsIntialized <<- FALSE
ht0 <<- NULL

### Replaces 0-length results with 0
formatIfNoResults <- function(x){
  if(identical(x,integer(0)) | identical(x,numeric(0))) 0
  else x
}

### Filter stop words. Given a data frame, returns new data frame with all rows that contain
# a stop word in the first column removed.
filterStopWords <- function(df) df[! df$X1 %in% stop_words,]

## Takes 1-gram x and 1-gram y and computes Pr(y|x)
checknGrams <- function(word,table) {
  results <- formatIfNoResults(as.integer(as.character(table[table[,1]==word,2])))
  if(is.na(word))  0
  else{
     sum <- formatIfNoResults(sum(as.integer(as.character(table$X2))))
     if(sum == 0) 0
     else results/sum
  }   
}

## Performs computation for stupid backoff model
## Given 2-gram x1_x2, returns
## Pr(y|x1_x2) if this value is nonzero
## 0.4*Pr(y|x2) otherwise
compute2Score <- function(twoGram,word,table1,table2) {
  twoGramScore <- checknGrams(word,table2)
  second <- strsplit(twoGram,"_")[[1]][2]

  if(twoGramScore == 0) 0.4*checknGrams(word,table1)
  else twoGramScore
}

compute3Score <- function(threeGram,word,table1,table2,table3) {
  threeGramScore <- checknGrams(word,table3)
  final_two <- strsplit(threeGram,"_")[[1]][2:3]
  final_twoGram <- paste(final_two[1],final_two[2],sep="_")
  if(threeGramScore == 0) 0.4*compute2Score(final_twoGram,word,table1,table2)
  else threeGramScore
}

formatText <- function(word) gsub("[[:punct:]]", "", tolower(word))

# Define server logic 
shinyServer(function(input, output) {
 
  print("App loaded")
  
  output$placeholder <- renderText({ 
    if(is.null(input$data_sets)) return("Choose a data source.")
    
    ## format text from input box
    input_vector0 <- strsplit(formatText(input$txt)," ")[[1]]
    n <- length(input_vector0)

    scoring_function <- NULL
    top3Grams <- NULL
    top2Grams <- NULL
    data_3Grams <- NULL
    data_2Grams <- NULL
    data_1Grams <- NULL
    computeLeader <- NULL

    if(n > 2 && input$fourGs){
      if(!fourGramsIntialized){
          fourGramsIntialized <<- TRUE
          print("Loading file.")
          withProgress(message = 'Loading 4-grams', value = 0, {
             load("fourGram_light.rData")
          }) 
      }
        input_vector <- input_vector0[(n-2):n]
        three_gram <- paste(input_vector[1],input_vector[2],input_vector[3],sep="_")
        data_3Grams <- ht0[[three_gram]]
        data_3Grams[,2] <-  sapply(data_3Grams$X2, function(x) as.numeric(as.character(x)))
        
        computeLeader <- function(u) sapply(u,compute3Score, threeGram=three_gram, table1=data_1Grams, table2=data_2Grams,table3=data_3Grams)
    }
   if(n > 1){
      input_vector <- input_vector0[(n-1):n]
      two_gram <- paste(input_vector[1],input_vector[2],sep="_")
      
      if("news" %in% input$data_sets){
        data_2Grams <- rbind(data_2Grams, ht1[[two_gram]])
      }
      if("blogs" %in% input$data_sets){
        data_2Grams <- rbind(data_2Grams, ht1_blogs[[two_gram]])
      }
      if("twitter" %in% input$data_sets){
        data_2Grams <- rbind(data_2Grams, ht1_twitter[[two_gram]])
      }
    
      ## xxxx Possible errors here when nulls
      data_2Grams[,2] <-  sapply(data_2Grams$X2, function(x) as.numeric(as.character(x)))
      if(!is.null(data_2Grams)) data_2Grams <- aggregate(data_2Grams$X2, by=list(Category=data_2Grams$X1), FUN=sum)
      
      if(is.null(computeLeader)) computeLeader <- function(u) sapply(u,compute2Score, twoGram=two_gram, table1=data_1Grams, table2=data_2Grams)
    }
    if(n > 0){
      one_gram <- input_vector0[n]
      if("news" %in% input$data_sets){
        data_1Grams <- rbind(data_1Grams, ht2[[one_gram]])
      }
      if("blogs" %in% input$data_sets){
        data_1Grams <- rbind(data_1Grams, ht2_blogs[[one_gram]])
      }
      if("twitter" %in% input$data_sets){
        data_1Grams <- rbind(data_1Grams, ht2_twitter[[one_gram]])
      }

      data_1Grams[,2] <-  sapply(data_1Grams$X2, function(x) as.numeric(as.character(x)))
      if(!is.null(data_1Grams)) data_1Grams <- aggregate(data_1Grams$X2, by=list(Category=data_1Grams$X1), FUN=sum)
      if(is.null(computeLeader)) computeLeader <- function(u) sapply(u,checknGrams, table=data_1Grams)
    }
    
    if(is.null(one_gram) | one_gram == "") return("Enter some text.")
 
  
    if(input$stopWords){
      d3Gind <- data_3Grams[,1] %in% stop_words
      data_3Grams <- data_3Grams[!d3Gind,]
      d2Gind <- data_2Grams[,1] %in% stop_words
      data_2Grams <- data_2Grams[!d2Gind,]
      d1Gind <- data_1Grams[,1] %in% stop_words
      data_1Grams <- data_1Grams[!d1Gind,]
    }
    if(input$removeNumbers){
      ## Don't think there are any numbers in the 4-grams to worry about
      d2Gind <- is.na(as.numeric(as.character(data_2Grams[,1])))
      data_2Grams <- data_2Grams[d2Gind,]
      d1Gind <-  is.na(as.numeric(as.character(data_1Grams[,1])))
      data_1Grams <- data_1Grams[d1Gind,]
    }
    
    #Get top 20 3-grams most likely to follow that 3-grams
    top3Grams <- data_3Grams[1:20,1]
    #Get top 20 1-grams most likely to follow that 2-grams
    top2Grams <- data_2Grams[1:20,1]
    #Get top 20 1-grams most likely to follow the preceding 1-gram
    top1Grams <- data_1Grams[1:20,1]

    #Compute top score for all of these candidates 
    u <- union(union(top1Grams,top2Grams),top3Grams)
    if(is.null(u)) "No results."
    else{
      ft <- computeLeader(u)
      names(sort(ft,decreasing = TRUE))[1:5]
    }
  })
})

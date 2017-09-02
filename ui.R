#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
  # Application title
  titlePanel("Text Predictor 3000"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput("data_sets", "Data Sets:",
                         c("news" = "news",
                           "twitter" = "twitter",
                           "blogs" = "blogs")),
      checkboxInput("stopWords", "Remove Stop Words", FALSE),
      checkboxInput("removeNumbers", "Remove Numbers", TRUE),
      checkboxInput("fourGs", "Enhance with 4grams", FALSE)),
    
    mainPanel(
   #   textInput("txt", "Input Text", ""),
  #    verbatimTextOutput("placeholder", placeholder = TRUE)
      textInput("txt", label = "Input Text", value = NULL),
      submitButton("Submit", icon("refresh")),
      helpText("Top 5 most likely words (descending order):"),
      verbatimTextOutput("placeholder", placeholder = TRUE)
    )
  
)))

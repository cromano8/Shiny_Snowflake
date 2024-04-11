library(shiny)
library(tidytext)
library(wordcloud)
library(tidyverse)
library(RColorBrewer)
library(shinythemes)
library(shiny)
library(shinyFiles)

options(shiny.host = "0.0.0.0")
options(shiny.port = 8787)

# The list of valid books
books <- list("A Mid Summer Night's Dream" = "summer",
              "The Merchant of Venice" = "merchant",
              "Romeo and Juliet" = "romeo")

getFreq <- function(book, stopwords = TRUE) {
  # check that only one of three books is selected
  if (!(book %in% books))
    stop("Unknown book")
  
  text <-  tibble(text = readLines(sprintf("./data/%s.txt", book), encoding="UTF-8"))
  
  text <- text %>%
    unnest_tokens(word, text) %>%
    count(word, sort = TRUE) 
  
  if(stopwords){
    text <- text %>%
      anti_join(stop_words)
  }
  
  return(text)
}

ui <- fluidPage(
  theme = shinytheme("cerulean"),
  titlePanel("Shakespeare's Plays Word Frequencies"), # Application title
  
  sidebarLayout(
    # Sidebar with a slider and selection inputs
    sidebarPanel(
      selectInput("selection", "Choose a book:",
                  choices = books),
      checkboxInput("stopwords", "Stop words:", value = TRUE),
      hr(),
      h3("Word Cloud Settings"),
      sliderInput("maxwords", "Max # of Words:",
                  min = 10,  max = 200, value = 100, step = 10),
      sliderInput("big", "Size of largest words:",
                  min = 1, max = 8, value = 4),
      sliderInput("small", "Size of smallest words:",
                  min = 0.1, max = 4, value = 0.5),
      hr(), # add in a line
      h3("Word Count Settings"),
      sliderInput("barcutoff", "Minimum words for Counts Chart:",
                  min = 10, max = 100, value = 25),
      sliderInput("fontsize", "Font size for Counts Chart:",
                  min = 8, max = 30, value = 14)
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Word Cloud", plotOutput("cloud", height = "600px")), # show word cloud
        tabPanel("Word Counts", plotOutput("freq", height = "600px")) # show frequency plot
      )
    )
  )
)

server <- function(input, output) {
  # Define a reactive expression for the document term matrix
  freq <- reactive({
    withProgress({
      setProgress(message = "Processing corpus...")
      getFreq(input$selection, input$stopwords)
    })
  })
  
  output$cloud <- renderPlot({
    v <- freq()
    pal <- brewer.pal(8,"Dark2")
    
    v %>% 
      with(
        wordcloud(word, n, 
                  scale = c(input$big, input$small),
                  random.order = FALSE, 
                  max.words = input$maxwords, 
                  colors=pal))
  })
  
  output$freq <- renderPlot({
    v <- freq()
    
    v %>%
      filter(n > input$barcutoff) %>%
      ggplot(aes(x = reorder(word, n), y = n)) +
      geom_col() +
      coord_flip() +
      theme(text = element_text(size=input$fontsize)) +
      labs(x = "", y = "", title = " ")
  })
}

shinyApp(ui = ui, server = server)

library(shiny)
library(rentrez)
library(tidyverse)
library(DT)
library(future)
library(promises)
library(shinythemes)
library(tm)
library(SnowballC)
library(wordcloud)
plan(multisession) # Setup for parallel processing


source("helpers.R")


ui <- fluidPage(
  theme = shinytheme("sandstone"), # Using a shinythemes theme for a modern look
  titlePanel("PubMed Search and Abstract Viewer", windowTitle = "PubMed Data Explorer"),
  # App Description
  titlePanel(
    tags$h4("This application allows users to search PubMed articles based on specific search terms and a date range. It displays a data table with article details, a line chart visualization of publications per year, and a word cloud generated from the abstracts of the articles.")
  ),
  br(),
  sidebarLayout(
    sidebarPanel(
      textAreaInput("searchTerms", "Search Terms",
        placeholder = "Enter terms separated by commas",
        rows = 4
      ),
      numericInput("fromYear", "From Year",
        min = 1900,
        max = format(Sys.Date(), "%Y"),
        value = 2015
      ),
      numericInput("toYear", "To Year",
        min = 1900,
        max = format(Sys.Date(), "%Y"),
        value = format(Sys.Date(), "%Y")
      ),
      actionButton("search", "Search", class = "btn-primary"),
      br(),
      br(),
      downloadButton("downloadData", "Download Data"),
      width = 2
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Data Table", DTOutput("table")),
        tabPanel(
          "# of Publications by Year",
          plotOutput("yearlyPublications")
        ),
        tabPanel("Wordcloud",
                 plotOutput("wordCloud"))
      )
    )
  )
)


server <- function(input, output, session) {
  data <- eventReactive(input$search, {
    req(input$searchTerms) # Ensure there is input before proceeding

    pubmed_ids <- fetch_pubmed_ids(input$searchTerms, input$fromYear, input$toYear)

    # Initialize progress
    total_ids <- length(pubmed_ids)
    progress <- Progress$new(session, min = 1, max = total_ids)
    progress$set(message = "Fetching data...", value = 0)
    progress$set(message = paste(total_ids, "Total IDs"))
    Sys.sleep(3)

    results <- lapply(pubmed_ids, function(id) {
      # Fetch abstract and update progress
      result <- fetch_abstracts(id)
      progress$inc(1)
      progress$set(message = paste("Processing ID:", id))

      # Update result with a message if abstract is not found
      if (is.na(result$Abstract)) {
        result$Abstract <- "No abstract found."
      }

      result
    })

    # Close the progress bar
    progress$close()

    # Combine results into one dataframe
    do.call(rbind, results)
  })

  output$table <- renderDT({
    datatable(data(), options = list(
      pageLength = 30,
      autoWidth = TRUE,
      columnDefs = list(
        list(
          targets = 6, # Assuming the 'Link' column is the 7th column
          render = JS(
            "function(data, type, row, meta) {",
            "  return type === 'display' && data !== null && data !== '' ?",
            "    '<a href=\"' + data + '\" target=\"_blank\">' + data + '</a>' : data;",
            "}"
          )
        )
      )
    ), escape = FALSE, rownames = FALSE)
  })

  # Function to download data
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("PubMed-Data-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      data <- data() # Fetch the current data
      write.csv(data, file, row.names = FALSE)
    }
  )

  # Visualization: Line chart with connected lines showing the number of publications per year
  output$yearlyPublications <- renderPlot({
    req(data())  # Ensure that data is available
    
    # Count and sort the number of publications per year
    yearly_counts <- data() %>%
      group_by(Year) %>%
      summarise(Count = n()) %>%
      arrange(Year)  # Sort data by year
    
    # Create a ggplot line chart
    ggplot(yearly_counts, aes(x = Year, y = Count)) +
      theme_minimal() +
      geom_line(aes(group=1), color = "lightblue1", linewidth = 2) +  # Connect points with lines
      geom_point(color = "navyblue", size = 6) +  # Display points
      labs(title = "Number of Publications per Year",
           x = "Year",
           y = "Number of Publications")
  })
  

  # Word Cloud: Create a word cloud from all abstract text
  output$wordCloud <- renderPlot({
    req(data())
    # abstracts <- Corpus(VectorSource(data()$Abstract))
    # # Strip unnecessary whitespace
    # #abstracts <- tm_map(abstracts, stripWhitespace)
    # # Convert to lowercase
    # abstracts <- tm_map(abstracts, tolower)
    # # Remove conjunctions etc.
    # abstracts <- tm_map(abstracts, removeWords, stopwords("english"))
    # # Remove suffixes to the common 'stem'
    # abstracts <- tm_map(abstracts, stemDocument)
    # # Remove commas etc.
    # abstracts <- tm_map(abstracts, removePunctuation)
    
    abstracts <- as.character(data()$Abstract)
    abstracts <- paste(abstracts, sep="", collapse="") 
    
    wordcloud(abstracts, 
              scale = c(3, 1),
              min.freq=10, 
              max.words=70, colors=brewer.pal(7,"Dark2"))
  })
}



# Run the application
shinyApp(ui = ui, server = server)

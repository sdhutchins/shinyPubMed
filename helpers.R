library(shiny)
library(rentrez)
library(dplyr)
library(DT)
library(XML)

# Function to fetch PubMed IDs based on formatted search terms
fetch_pubmed_ids <- function(search_terms_input, from_year, to_year) {
  # Split terms by comma and trim spaces
  terms <- strsplit(search_terms_input, ",")[[1]]
  terms <- sapply(terms, trimws)
  
  # Format terms into "(term1) OR (term2) OR ..." structure
  formatted_terms <- paste0("(", paste(terms, collapse = ") AND ("), ")")
  
  # Add year range to the query
  date_range_query <- paste0(formatted_terms, " AND (", from_year, ":", to_year, "[PDAT])")
  
  entrez_ids <- entrez_search(db = "pubmed", term = date_range_query, retmax=10000)
  return(entrez_ids$ids)
}


# Function to fetch abstracts based on PubMed IDs
fetch_abstracts <- function(id) {
  article <- tryCatch({
    entrez_fetch(db = "pubmed", id = id, rettype = "xml", parsed = TRUE)
  }, error = function(e) {
    cat("Error fetching article with ID:", id, "\n")
    return(NULL)
  })
  
  if (is.null(article)) {
    cat("Article is NULL for ID:", id, "\n")
    return(data.frame(PubMedID = id, Title = NA, Year = NA, Abstract = NA, Citations = NA, FirstAuthor = NA, Journal = NA, Link = NA, stringsAsFactors = FALSE))
  }
  
  abstract_text <- xpathSApply(article, "//AbstractText", xmlValue)
  title <- xpathSApply(article, "//ArticleTitle", xmlValue)
  year <- xpathSApply(article, "//PubDate/Year", xmlValue)
  first_author <- xpathSApply(article, "//AuthorList/Author[1]/LastName", xmlValue)
  journal <- xpathSApply(article, "//Journal/Title", xmlValue)
  link <- paste0("https://pubmed.ncbi.nlm.nih.gov/", id)
  
  # Creating a data frame with the fetched information
  return(data.frame(
    PubMedID = id, 
    Title = ifelse(length(title) > 0, title[[1]], NA),
    Year = ifelse(length(year) > 0, year[[1]], NA),
    Abstract = ifelse(length(abstract_text) > 0, 
                      {
                        sentences <- unlist(strsplit(abstract_text[[1]], "(?<=[.!?])\\s+", perl=TRUE))
                        first_two <- head(sentences, 2)
                        last_two <- tail(sentences, 2)
                        combined <- c(first_two, last_two)
                        paste(combined, collapse=" ")
                      }, 
                      NA),
    FirstAuthor = ifelse(length(first_author) > 0, first_author[[1]], NA),
    Journal = ifelse(length(journal) > 0, journal[[1]], NA),
    Link = link,
    stringsAsFactors = FALSE
  ))
}

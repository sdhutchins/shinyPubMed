# shinyPubMed

<!-- ![banner]() -->
<!-- ![badge]() -->
<!-- ![badge]() -->
shinyPubMed allows users to search and visualize PubMed articles based on specific search terms and a date range. It displays article details, a line chart of publications per year, and a word cloud generated from the abstracts.

## Table of Contents

-   [App Background](#app-background)
-   [Install & Setup](#install-setup)
-   [Usage](#usage)
-   [Authors](#authors)
-   [License](#license)

## App Background

This Shiny app is designed to provide an interactive interface for searching and analyzing PubMed articles. Users can enter specific search terms and select a date range to retrieve relevant articles. The app presents this data in a tabular format, along with visualizations like a yearly publication trend line chart and a word cloud representing the most frequent terms in the abstracts. This tool is particularly useful for researchers and academics in the field of biomedical sciences.

## Install & Setup

To run this Shiny application, you will need __R v4.3.2__ installed on your system with the following R packages: `shiny`, `rentrez`, `dplyr`, `DT`, `XML`, `ggplot2`, and `wordcloud2`. You can install these packages using the R command `install.packages("package_name")`.

```r
install.packages(c("shiny", "rentrez", "tidyverse", "DT", "XML", "wordcloud"))
```

## Usage

1. **Launch the App**: Run the Shiny app script in RStudio or in an R environment.
2. **Enter Search Terms**: Input your desired search terms in the provided field, separated by commas.
3. **Set Date Range**: Choose the start and end years for your article search.
4. **Search and Visualize**: Click the 'Search' button to fetch the articles. The results will be displayed in a data table, and the visualizations will be available under the 'Visualization' tab.
5. **Download Data**: You can download the fetched data as a CSV file using the 'Download Data' button.

### Run App from GitHub

To run the app from GitHub, use the below code:

```r
# Load the shiny package
if (!requireNamespace("shiny", quietly = TRUE)) {
    install.packages("shiny")
}
library(shiny)

# Run the app from a GitHub repository
runGitHub("shinyPubMed", "sdhutchins")
```

## Authors

* [Shaurita D. Hutchins](mailto:shaurita.d.hutchins@gmail.com)

## License

[MIT License](LICENSE)

# Base R Shiny image
FROM rocker/shiny

# Make a directory in the container
RUN mkdir /home/shiny-app

# Install R dependencies
RUN R -e "install.packages(c('dplyr', 'ggplot2', 'gapminder', 'tidytext', 'wordcloud', 'tidyverse', 'RColorBrewer', 'shinythemes', 'shinyFiles'))"

# Copy the Shiny app code
COPY app.R app.R
COPY data data
#COPY data /home/shiny-app/data

# Expose the application port
EXPOSE 8787

# Run the R Shiny app
CMD Rscript app.R
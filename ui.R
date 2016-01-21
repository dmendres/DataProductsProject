library(shiny)
library(ggplot2)
shinyUI(
  pageWithSidebar(
    headerPanel("PowderFinder: Finding Smokeless Powders for a given bullet"),
    
    sidebarPanel(
      h1('Application Description'),
      p('Handloading metallic (rifle or pistol) cartridges is a common hobby in the US. \
        To avoid injury or damage, it is critical to use good data for the bullet, cartridge, and powder combination. \
        However, often certain powders or bullets are not available and substitutes must be made -- WITH GREAT CARE.\
        This application suggests alternate powders within the same range of burn rates as those for which documented loads are available.'),
      p('Given a cartridge selection and using a provided set of load data tables (powder type and starting charge), \
      this application locates other powders with similar burn rates and suggests a starting load for those powders.'),
      h3('Cartridge and Bullet Selection'),
      #TODO: The cartridge tags below are enumerated in server.R, find a way to avoid copying that list!
      selectInput("cartridge", "Choose Cartridge:",
                  list("300 AAC Blackout" = "300Blk", 
                       "308 Winchester (7.62 X 51 NATO)" = "308Win", 
                       "300 Winchester Magnum" = "300WinMag")),
      uiOutput("bulletControls")
    ),

    mainPanel(
      h1('DISCLAIMER'),
      p('DISCLAIMER: This application is a prototype developed for Coursera Data Products course and represents a concept for demonstration purposes. \
      RESULTS MUST NOT BE USED for actual cartridge loads.'),
      p('DISCLAIMER: The current starting charge model implementation uses a simple linear \
      model over a range of powders with similar burn rates.\
      Since the smokeless powder burn tables are only an unscaled, ordered ranking from fastest to slowest,\ 
      linear interpolation is not suited to computing actual loads.\
      The final product will use models fitted to the known load data using a better set of predictors.'),
      h2('Concept of Operation'),
      p('Selectors for cartridge and bullet (manufacturer, bullet mass and type) are provided. \
      The load table is queried for suitable powders and charges. \
      The range of burn-rate ranked powders is queried for powders within \
      the bounds of the minimum and maximum rank of powders for which load data is available.\
      The results are presented with modeled starting loads.'),
      h2('Results:'),
      h3('Plot showing interpolated starting charges'),
      p("The plot of starting charge shows clearly where we have fit \
        the charges to the linear model and where the actual published charges differ."),
      plotOutput("resultsPlot"),
      h3('Data Table of starting charges for selected cartridge and bullet'),
      dataTableOutput("resultsTable")
    )
  )
)
  

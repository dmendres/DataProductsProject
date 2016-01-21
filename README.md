# DataProductsProject
This repository holds the data and code for the DataProducts Shiny app.
## Application Description

Handloading metallic (rifle or pistol) cartridges is a common hobby in the US. 
To avoid injury or damage, it is critical to use good data for the bullet, cartridge, powder combination.
However, often certain powders or bullets are not available and substitutes must be made -- WITH GREAT CARE.
This application suggests alternate powders within the same range of burn rates as those for which documented loads are available.

## Application Operation

Given a cartridge selection and using a provided set of load data tables (powder type and starting charge), 
this application locates other powders with similar burn rates and suggests a starting load for those powders.
      
## __DISCLAIMER__

*DISCLAIMER:* This application is a prototype developed for Coursera Data Products course and represents a concept for demonstration purposes. RESULTS MUST NOT BE USED for actual cartridge loads.
*DISCLAIMER:* The current starting charge model implementation uses a simple linear
model over a range of powders with similar burn rates.
Since the smokeless powder burn tables are only an unscaled, ordered ranking from fastest to slowest,
linear interpolation is not suited to computing actual loads.
The final product will use models fitted to the known load data using a better set of predictors.

## Concept of Operation
1. Selectors for cartridge, and bullet (manufacturer, bullet mass and type) are provided.
1. Given a cartridge and bullet selection, the load table is queried for suitable powders and charges.
1. The range of burn-rate ranked powders is queried for powders within
the bounds of the minimum and maximum rank of powders for which load data is available.
1. The results are presented with modeled starting charges in plotted and tabulated formats.

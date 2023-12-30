library(tidygeocoder)
library(leaflet)
library(leaflet.extras)
library(htmltools)
library(plotly)
library(shiny)
library(shinydashboard)
library(rpivotTable)
library(rgdal)
library(rgeos)
library(haven)
library(sjlabelled)
library(dplyr)
library(tidyverse)
library(maptools)
library(classInt)
library(scales)


#load shipefiles
shapefile_path <- "W:/07_Forschung/07_MACH Consumer/28_Consumer 2025/Organisation/Alternativ zu Tableau/Gemeinden.shp"
layers <- ogrListLayers(dsn = shapefile_path)
all_layers <- list()
for (layer_name in layers) {
  layer_data <- readOGR(dsn = shapefile_path, layer = layer_name)
  all_layers[[layer_name]] <- layer_data
}
newdf <- merge(all_layers[[1]], all_layers[[2]], by = "BFS_NUMMER")
for (i in 3:length(all_layers)) {
  newdf <- merge(newdf, all_layers[[i]], by = "BFS_NUMMER")
}
newdf <- newdf[newdf$OBJEKTART == "Gemeindegebiet", ]
newdf <- spTransform(newdf, CRS("+init=epsg:4326"))

# Import data
faux <- read.csv(...)

#Import Bfs-Number and Zip-Code
bfs <- read.csv("W:/07_Forschung/07_MACH Consumer/28_Consumer 2025/Organisation/Alternativ zu Tableau/Datensaetze/bfsnummern.csv")

# Merge data
merged <- merge(faux, bfs, by.x = "zip", by.y = "PLZ", all.x = TRUE)
merged <- merged[!duplicated(merged$id), ]
merged2 <- merged %>% group_by(WOBFS) %>% summarize(counts = n())
merged_map <- merge(newdf, merged2, by.x = "BFS_NUMMER", by.y = "WOBFS", all.x = TRUE)
merged_map@data$counts[is.na(merged_map@data$counts)] <- 0

# Create color palette
bins <- c(0, 1, 2, 5, 10, Inf)
pal <- colorBin("plasma", domain = merged_map@data[["counts"]], bins = bins)

# Create leaflet map
swiss2 <- leaflet(merged_map) %>%
  addTiles() %>%
  addPolygons(
    fillColor = ~pal(merged_map@data[["counts"]]),
    weight = 2,
    opacity = 1,
    color = "white",
    dashArray = "1",
    fillOpacity = 1,
    popup = paste("Gemeinde: ", merged_map@data[["NAME"]], "<br>",
                  "Anzahl Interviews: ", merged_map@data[["counts"]])
  ) %>%
  addLegend(pal = pal, values = merged_map@data[["counts"]], labels = merged_map@data[["counts"]], title = "Counts", position = "bottomright")


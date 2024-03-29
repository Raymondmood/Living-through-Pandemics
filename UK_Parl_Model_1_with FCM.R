
# This program is created by Raymond Moodley (raymond.moodley@dmu.ac.uk). It is not to be used for financial gain without the express consent of the author.
# This program creates a SOM for GB based on input data, and maps it to GB parliamentary constituencies
# This program has 4 ouputs - 2 SOM plots, 1 GB Map plot and 1 CSV File with the data and SOM mapping


#______________________________________________________________________________
# This program is built on the kohonen and parlitools packages. 
# Kohonen: maintainer and co-author: Ron Wehrens <ron.wehrens@gmail.com>
# Parlitools: maintainer and auther: 	Evan Odell <evanodell91 at gmail.com>
#______________________________________________________________________________

#clear workspace
rm(list=ls())

# loading all the libraries and packages
require(kohonen)
require(parlitools)
library(leaflet)
library(sf)
library(htmlwidgets)
library(dplyr)
library(parlitools)
library(cartogram)
library(kohonen)


########### User inputs#######################################
#####Loading Data

party_colour= read.csv("party_colour.csv", 
                       sep = ",", header = T, check.names = FALSE)

######read data set
Covid_data = read.csv("Dataset_1.csv", 
                      sep = ",", header = T, check.names = FALSE)


#defining the SOM
x = 6
y = 6
k = x*y

################# end of user inputs #######################################################


#setting up map from parlitools - no need to adjust
west_hex_map <- parlitools::west_hex_map
party_colour$party_id = as.numeric(rownames(party_colour))
p = heat.colors(k)
p = substr(p, 1, 7)
p = as.data.frame(p)
p$party_id = as.numeric(rownames(p))
party_colour = as.data.frame(party_colour)
party_colour = merge(party_colour, p, by = "party_id") 
colnames(party_colour)[4] <- "party_colour"
party_colour = party_colour[,c(1,2,4)]
elect2017 <- parlitools::bes_2017

rm(p)


#Dataset Processing 

#selecting the key measures
Covid_data.measures1 = c("Vulnerability", "Commuter", "School Mobility", "Population Density", "People per House", "Economic Output")

#### KEY SOM STEP - scaling the dataset and applying the SOM
Covid_data.SOM1 <- som(scale(Covid_data[Covid_data.measures1]), grid = somgrid(x, y, "rectangular"))


# generaliser - applying dataset to som_model for plotting ########################
som_model = Covid_data.SOM1

Location = unlist(som_model$unit.classif)
Location = as.data.frame(Location)
Covid_data_up = cbind(Location, Covid_data)

#name changes to match back to parlitools
names(Covid_data_up)[1] <- "party_id"
names(Covid_data_up)[4] <- "gss_code"




#Join SOM to parlitools functionality
elect2017_win_colours <- left_join(elect2017, Covid_data_up, by = c("ons_const_id"= "gss_code"))
elect2017_win_colours = as.data.frame(elect2017_win_colours)
elect2017_win_colours$winner_17 = elect2017_win_colours$party_id
elect2017_win_colours <- left_join(elect2017_win_colours, party_colour, by = c("winner_17"= "party_id"))

#Join colours to hexagon map
gb_hex_map <- right_join(west_hex_map, elect2017_win_colours,
                         by = c("gss_code"="ons_const_id"))


# Map plotting metrics from Parlitools - leave alone 
gb_hex_map = as.data.frame(gb_hex_map)
df_temp <- subset(Covid_data_up, select = c(1,2,3,4,5))
df_temp = left_join(df_temp, gb_hex_map, by = "gss_code") 
names(df_temp)[1] = "party_id"
df_temp$party_colour = party_colour$party_colour[match(df_temp$party_id,party_colour$party_id)]
gb_hex_map= df_temp


#GB map generator metrics ##### leave alone
gb_hex_map = st_as_sf(gb_hex_map)
gb_hex_map$majority_17 <- round(gb_hex_map$majority_17, 2)
gb_hex_map$turnout_17 <- round(gb_hex_map$turnout_17, 2)
gb_hex_map$marginality <- (100-gb_hex_map$majority_17)^3
gb_hex_map <- st_transform(gb_hex_map, "+init=epsg:3395")
gp_hex_scaled <- cartogram_cont(gb_hex_map, 'marginality', itermax = 5)
gp_hex_scaled <- st_transform(gp_hex_scaled, "+init=epsg:4326")


# Creating map labels - can change labels if needed
labels <- paste0(
  "Constituency: ", gp_hex_scaled$constituency_name.y, "</br>",
  "Cluster: ", Covid_data_up$party_id, "</br>",
  "SOM Group: ", Covid_data_up$Location,"</br>",
  "ACR: ", Covid_data$ACRat, "%"
) %>% lapply(htmltools::HTML)

# Creating the map itself - no need to adjust
leaflet(options=leafletOptions(
  dragging = FALSE, zoomControl = FALSE, tap = FALSE,
  minZoom = 6, maxZoom = 6, maxBounds = list(list(2.5,-7.75),list(58.25,50.0)),
  attributionControl = FALSE),
  gp_hex_scaled) %>%
  addPolygons(
    color = "grey",
    weight=0.75,
    opacity = 0.5,
    fillOpacity = 1,
    fillColor = ~party_colour,
    label=labels) %>%
  htmlwidgets::onRender(
    "function(x, y) {
    var myMap = this;
    myMap._container.style['background'] = '#fff';
    }")%>%
  mapOptions(zoomToLimits = "first")


######################OUTPUTS#############################################

# writing the ouput file
write.csv(Covid_data_up, "Processed_File.csv", 
          row.names = FALSE)


#SOM Plots
plot(Covid_data.SOM1, type = "mapping", pchs = 19, main = "Mapping Type SOM")
plot(Covid_data.SOM1, type = "codes", palette.name = heat.colors, bgcol = topo.colors(k))






##################################FCM########################################################
Covid_data_fcm =  subset(Covid_data, select = c("Constituency", "Vulnerability", "Commuter", "School Mobility", "Population Density", "People per House", "Economic Output"))
#Covid_data_fcm_scale = scale(Covid_data_fcm[,2:7],center=TRUE,scale=TRUE)
Covid_data_fcm_scale = apply(Covid_data_fcm[,2:7], MARGIN = 2, FUN = function(X) (X - min(X))/diff(range(X)))
library(e1071)
cm = cmeans(Covid_data_fcm_scale,36)
loc_fcm = as.data.frame(cm$cluster)



###########################map#########################

Covid_data_up = cbind(loc_fcm, Covid_data)

#name changes to match back to parlitools
names(Covid_data_up)[1] <- "party_id"
names(Covid_data_up)[4] <- "gss_code"




#Join SOM to parlitools functionality
elect2017_win_colours <- left_join(elect2017, Covid_data_up, by = c("ons_const_id"= "gss_code"))
elect2017_win_colours = as.data.frame(elect2017_win_colours)
elect2017_win_colours$winner_17 = elect2017_win_colours$party_id
elect2017_win_colours <- left_join(elect2017_win_colours, party_colour, by = c("winner_17"= "party_id"))

#Join colours to hexagon map
gb_hex_map <- right_join(west_hex_map, elect2017_win_colours,
                         by = c("gss_code"="ons_const_id"))


# Map plotting metrics from Parlitools - leave alone 
gb_hex_map = as.data.frame(gb_hex_map)
df_temp <- subset(Covid_data_up, select = c(1,2,3,4,5))
df_temp = left_join(df_temp, gb_hex_map, by = "gss_code") 
names(df_temp)[1] = "party_id"
df_temp$party_colour = party_colour$party_colour[match(df_temp$party_id,party_colour$party_id)]
gb_hex_map= df_temp


#GB map generator metrics ##### leave alone
gb_hex_map = st_as_sf(gb_hex_map)
gb_hex_map$majority_17 <- round(gb_hex_map$majority_17, 2)
gb_hex_map$turnout_17 <- round(gb_hex_map$turnout_17, 2)
gb_hex_map$marginality <- (100-gb_hex_map$majority_17)^3
gb_hex_map <- st_transform(gb_hex_map, "+init=epsg:3395")
gp_hex_scaled <- cartogram_cont(gb_hex_map, 'marginality', itermax = 5)
gp_hex_scaled <- st_transform(gp_hex_scaled, "+init=epsg:4326")


# Creating map labels - can change labels if needed
labels <- paste0(
  "Constituency: ", gp_hex_scaled$constituency_name.y, "</br>",
  "Cluster: ", Covid_data_up$party_id, "</br>",
  "SOM Group: ", Covid_data_up$Location,"</br>",
  "ACR: ", Covid_data$ACRat, "%"
) %>% lapply(htmltools::HTML)

# Creating the map itself - no need to adjust
leaflet(options=leafletOptions(
  dragging = FALSE, zoomControl = FALSE, tap = FALSE,
  minZoom = 6, maxZoom = 6, maxBounds = list(list(2.5,-7.75),list(58.25,50.0)),
  attributionControl = FALSE),
  gp_hex_scaled) %>%
  addPolygons(
    color = "grey",
    weight=0.75,
    opacity = 0.5,
    fillOpacity = 1,
    fillColor = ~party_colour,
    label=labels) %>%
  htmlwidgets::onRender(
    "function(x, y) {
    var myMap = this;
    myMap._container.style['background'] = '#fff';
    }")%>%
  mapOptions(zoomToLimits = "first")

# writing the ouput file
write.csv(Covid_data_up, "Processed_File_fcm.csv", 
          row.names = FALSE)



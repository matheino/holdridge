
rm(list = ls())

library(zoo)
library(tidyverse)
library(dplyr)
library(raster)
library(fasterize)
library(sf)
library(ggplot2)
library(DescTools)

setwd("C:/Users/heinom2/holdridge/spam_2010")

# Import country shape file
cntry_shape <- read_sf('ne_50m_adm0_all_ids/ne_50m_adm0_all_ids/adm0_NatEarth_all_ids.shp')
cntry_shape_meta <- cntry_shape
st_geometry(cntry_shape_meta) <- NULL

# Import 9/2/2018 release of FAOSTAT Food Balance Sheets; used in Kummu et al. 2020
load("script&files/FBS.Rdata")
load("script&files/countryList.Rdata")

elementList <- c(5142, 5611, 5511, 5911, 5072, 645, 664, 674, 684) #Necessary FBS elements

# Import Excel sheet, that combines fao information to SPAM2010
fao2spam <- readxl::read_xlsx("fao2spam.xlsx") %>%
  dplyr::select(c(1,2,3,4)) %>%
  drop_na()

itemListShort = as.data.frame(unique(fao2spam["Item.Code"]))

# Subset FBS to include only the necessary data
foodBalanceSheets <- subset(foodBalanceSheets, Year==2010 & 
                              Area.Code %in% countryList[,1] & 
                              Item.Code %in% itemListShort[,1] & 
                              Element.Code %in% elementList)

foodBalanceSheets <- subset(foodBalanceSheets, select = -c(Element.Code, Unit))

# Reshape to wide format
foodBalance.wide <- reshape2::dcast(foodBalanceSheets, Area.Code+Area+Item.Code+Item+Year ~ Element, value.var="Value")
colnames(foodBalance.wide)[6:14] <- c("exp", "fat.gCapD", "food", "supply.KcalCapD", "supply.KgCapYr", "imp", "prod", "prot.gCapD", "stock")

# Calculate kg to kcal conversion factor
foodBalance.wide$kcalPerKg <- (foodBalance.wide$supply.KcalCapD*365)/foodBalance.wide$supply.KgCapYr
foodBalance.wide[is.na(foodBalance.wide) | foodBalance.wide == 0] <- NA # Assume Na=0

# Filter the table and extract only those information that are needed
kcalPerKg <- as_tibble(foodBalance.wide) %>%
  dplyr::select(c('Area.Code','Area','Item','Item.Code','Year', 'kcalPerKg')) %>%
  filter(Year == 2010)

# Merge date FAO table with the corresponding crops in SPAM
kcalPerKg <- kcalPerKg %>%
  left_join(fao2spam, by = 'Item.Code') %>%
  mutate(kcalPerKg = ifelse(kcalPerKg == 0, NA, kcalPerKg))

# set 2010 FAO id to sudan and south sudan
temp_raster <- raster('dataverse_files/spam2010v2r0_global_prod.geotiff/spam2010V2r0_global_P_WHEA_A.tif')
cntry_raster <- fasterize::fasterize(cntry_shape, raster = temp_raster, field = 'fao_id')
cntry_raster[cntry_raster == 276] <- 206
cntry_raster[cntry_raster == 277] <- 206

cntry_shape_meta_sudan = cntry_shape_meta[cntry_shape_meta['admin'] == 'Sudan',]
cntry_shape_meta_sudan['fao_id'] = 206
cntry_shape_meta_sudan['admin'] = 'Sudan (former)'

cntry_shape_meta = rbind(cntry_shape_meta, cntry_shape_meta_sudan)

# Function to aggregate kcal production for each grid cell
aggreg_kcal <- function(crop, cntry_shape_meta, kcalPerKg, no_data_cntry, cntry_raster, kcal_tot) {
  
  print(crop)
  
  # Function to fill NA values with surrounding data cells
  fill_na <- function(x, i=5) { #i=5 default
    if( is.na(x)[i] ) {
      return(Mode(x, na.rm = T))
    } else {
      return(x[i])
    }
  }
  
  # Import crop specific global production raster (unit: metric tons)
  prod_raster <- raster(paste('dataverse_files/spam2010v2r0_global_prod.geotiff/spam2010V2r0_global_P_',toupper(crop),'_A.tif', sep = ""))
  prod_raster[is.na(prod_raster)] <- 0.0
  
  # Fill the country raster using the fill_na function as long as there are still cells in the production raster that are without
  # country id information
  while (sum(as.matrix((prod_raster * !is.na(cntry_raster) - prod_raster)), na.rm = TRUE) != 0) {
    cntry_raster <- focal(cntry_raster, w = matrix(1,3,3), fun = fill_na, pad = TRUE, NAonly = TRUE)
  }
  
  #plot(cntry_raster)
  
  # Create a table which has a kcal per kg transformation value for all countries across the globe
  # Use average data for subregion, region_wb or the whole globe to fill for missing values (depending on data availability) 
  kcalPerKg_crop <- kcalPerKg %>%
    filter(spam_short == crop) %>%
    full_join(cntry_shape_meta[c('fao_id','admin', 'subregion','region_wb')], by = c('Area.Code' = 'fao_id')) %>%
    group_by(subregion) %>% 
    mutate(kcalPerKg_subregional_mean = mean(kcalPerKg, na.rm = TRUE)) %>%
    ungroup() %>%
    group_by(region_wb) %>% 
    mutate(kcalPerKg_regional_mean = mean(kcalPerKg, na.rm = TRUE)) %>%
    ungroup() %>%
    mutate(kcalPerKg_global_mean = mean(kcalPerKg, na.rm = TRUE)) %>%
    mutate(kcalPerKg_all = ifelse(is.na(kcalPerKg), kcalPerKg_subregional_mean, kcalPerKg)) %>%
    mutate(kcalPerKg_all = ifelse(is.na(kcalPerKg_all), kcalPerKg_regional_mean, kcalPerKg_all)) %>%
    mutate(kcalPerKg_all = ifelse(is.na(kcalPerKg_all), kcalPerKg_global_mean, kcalPerKg_all)) %>%
    drop_na(kcalPerKg_all) %>%
    filter(Area.Code > 0) %>%
    distinct(Area.Code, kcalPerKg_all, .keep_all= TRUE) %>%
    as.data.frame()
  
  # Check countries for which there is no data
  no_data_cntry_new <- setdiff(kcalPerKg_crop[,'Area.Code'], unique(cntry_raster))
  no_data_cntry <- c(union(no_data_cntry, no_data_cntry_new))
  print(no_data_cntry)
  
  # Switch values from the table to a raster using the ids from the cntry_raster
  kcalPerKg_raster <- subs(cntry_raster, kcalPerKg_crop[c('Area.Code','kcalPerKg_all')])
  kcalPerKg_raster[is.na(kcalPerKg_raster)] <- 0.0
  plot(kcalPerKg_raster)
  
  print(sum(as.matrix(prod_raster)))
  
  # Calculate the amount of kcal for each raster cell for the crop in question
  kg_per_tonne = 1000
  kcal_tot <- kcal_tot + kcalPerKg_raster * kg_per_tonne * prod_raster
  
  return(list(no_data_cntry, cntry_raster, kcal_tot))
  
}


#cntry_raster <- raster("cntry_raster_filled.tif")

# Initialize raster with total kcal information
kcal_tot <- cntry_raster
kcal_tot[,] <- 0.0

no_data_cntry <- c()

# Run aggreg_kcal function for each SPAM food crop
for (i in 1:nrow(fao2spam)){
  crop = as.character(fao2spam[i,'spam_short'])
  list_out <- aggreg_kcal(crop, cntry_shape_meta, kcalPerKg, no_data_cntry, cntry_raster, kcal_tot)
  
  no_data_cntry <- list_out[[1]]
  cntry_raster <- list_out[[2]]
  kcal_tot <- list_out[[3]]
}

# Write out resulting rasters
writeRaster(cntry_raster, "C:/Users/heinom2/holdridge/data/cntry_raster_filled.tif", overwrite = T)
writeRaster(kcal_tot, "C:/Users/heinom2/holdridge/data/kcal_tot_final.tif", overwrite = T)

# Resample total kcal raster to same extent as population raster as well as other data
raster_temp <- raster(ncol=4320, nrow=2160, xmn=-180, xmx=180, ymn=-90, ymx=90)
kcal_tot_resampled <- resample(kcal_tot, raster_temp, method="ngb")
writeRaster(kcal_tot_resampled, "C:/Users/heinom2/holdridge/data/kcal_tot_final_resampled.tif", overwrite = T)

cellStats(kcal_tot, sum)/10^9/6.5/365
cellStats(kcal_tot_resampled, sum)/10^9/6.5/365



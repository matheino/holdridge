# Set up libraries

library(ggplot2)
library(ggtern)
library(reshape2)
library(ggalt)
library(dplyr)
library(tidyverse)
library(rstudioapi)

# Define function for importing data
import_data <- function(filename,clim_scen) {

  # data for various PET and prec values
  df = read.table(filename, sep = ',')
  names(df) <- c('PET','prec','ref_present',clim_scen)
  
  # log2 and normalise between 0 and 1
  # PET scaled between 0.125 and 32
  # precip scaled between 62.5 and 16000 mm/yr
  
  df['PET_trans'] <- (log2(df['PET']) - log2(0.125) ) / (log2(32)-log2(0.125))
  
  df['prec_trans'] <- (log2(df['prec']) - log2(62.5) ) / (log2(16000)-log2(62.5))
  
  df[df['PET_trans'] < 0,'PET_trans'] = 0
  df[df['PET_trans'] > 1,'PET_trans'] = 1
  
  df[df['prec_trans'] < 0,'prec_trans'] = 0
  df[df['prec_trans'] > 1,'prec_trans'] = 1
  
  # temp with the function of PET and prec
  df['temp_trans'] <- 1 - df['PET_trans'] - df['prec_trans']
  return(df)

}

# Plot the data into a ternary plot
plot_ternary <- function(df, dtype, list_of_mappings, clim_scen, bins, h) {
  
  # Define tick locations and tick labels to be potentially used in the plots
  breaks_9 <- seq(0, 1, length=9)
  PET_labels <- c("0.125", "0.25","0.5","1","2","4","8","16","32")
  prec_labels <- (c("62.5", "125","250","500","1000","2000","4000","8000","16000"))
  temp_labels <- (c("9999", "888","8","4","2","1","0.5","0.25","0.125"))
  
  # List of the data to plot
  list_to_include = c('ref_present', clim_scen)
  
  # Filter table from unnecessary data and zero values. Also conducta log2 transformation on the 
  # population / livestock / food crop production data
  df_long = as_tibble(df) %>%
    gather(scenario, ref_val, list_to_include) %>%
    filter(ref_val != 0) %>%
    mutate(log_ref_val = log2(ref_val)) %>%
    group_by(scenario)

  # Initialize ternary plot
  tern_plot <-  ggtern(data=df_long,aes(x=PET_trans,y=temp_trans,z=prec_trans)) +
    theme_nogrid_minor() +
    scale_T_continuous(breaks=breaks_9,labels=temp_labels) +
    scale_L_continuous(breaks=breaks_9,labels=PET_labels) +
    scale_R_continuous(breaks=breaks_9,labels=prec_labels) +
    # labs( x       = "",
    #       xarrow  = "PET",
    #       y       = "",
    #       yarrow  = "Temperature",
    #       z       = "",
    #       zarrow  = "Precipitation") +
    # theme_showarrows() +
    theme_notitles() +
    theme_nolabels() +
    theme(legend.position="none") +
    theme_hideprimary() +
    theme_noticks()
  
  # Create a density plot as a reference for the present day (year 2010) scenario
  # Only the outlines of this plot are used for the actual results
  df_long_dens = df_long %>% filter(scenario == list_to_include[list_of_mappings == 'density'])
  tern_plot <- tern_plot + stat_density_tern(data = df_long_dens, aes(fill = log_ref_val),
       alpha = 0.5,
       fill = 'blue',
       geom = 'polygon',
       h = h,
       base = 'identity',
       bins = bins,
       n = 500,
       na.rm = TRUE)
  
  # Create a point plot (scatter) on the ternary using the scenario that is actually investigated
  # The color saturation describes the amount of population / livestock / food crop production in that Holdridge category
  df_long_point = df_long %>% filter(scenario == list_to_include[list_of_mappings == 'point_scale'])
  tern_plot <- tern_plot + geom_point(data = df_long_point, aes(color = scenario, alpha = log_ref_val),
            size = 1,
            na.rm = TRUE)

  filename = paste0('results_review/ternary_mapping/',dtype,'_',list_to_include[2],'.svg')

  ggsave(filename, width = 10, height = 10)
  
  tern_plot
    
}

# FINALIZE TERN PLOTS IN ILLUSTRATOR STILL
dir = dirname(getSourceEditorContext()$path)
setwd(dir)

# Import livestock and food crop production data in different holdridge bins
df_ls_26 = import_data('results_review/ternary_mapping/holdridge_PET_precip_tabulted_livestock_au_rcp26_hold_2090.csv', 'ref_rcp26')
df_ls_85 = import_data('results_review/ternary_mapping/holdridge_PET_precip_tabulted_livestock_au_rcp85_hold_2090.csv', 'ref_rcp85')
df_crop_26 = import_data('results_review/ternary_mapping/holdridge_PET_precip_tabulted_crop_spam_rcp26_hold_2090.csv', 'ref_rcp26')
df_crop_85 = import_data('results_review/ternary_mapping/holdridge_PET_precip_tabulted_crop_spam_rcp85_hold_2090.csv', 'ref_rcp85')

# Plot the data into a ternary plot
plot_ternary(df_ls_26, 'livestock', c('density','point_scale'), 'ref_present', 3, c(0.025, 0.025))
plot_ternary(df_ls_26,'livestock',c('density','point_scale'), 'ref_rcp26', 3, c(0.025, 0.025))
plot_ternary(df_ls_85,'livestock',c('density','point_scale'), 'ref_rcp85', 3, c(0.025, 0.025))

plot_ternary(df_crop_26,'crop',c('density','point_scale'), 'ref_present', 3, c(0.025, 0.025))
plot_ternary(df_crop_26,'crop',c('density','point_scale'), 'ref_rcp26', 3, c(0.025, 0.025))
plot_ternary(df_crop_85,'crop',c('density','point_scale'), 'ref_rcp85', 3, c(0.025, 0.025))


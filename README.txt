
Scripts for: 'Climate change risks to push one-third of global food production outside Safe Climatic Space'
By: Matti Kummu, Matias Heino, Maija Taka, Olli Varis & Daniel Viviroli

The analysis is composed of six main MATLAB and R scripts:

1) holdridge_step1_download_data.m
  - downloads and the present and future climatological datafrom Worldclim (1),
    and combines them to MATLAB format

2) holdridge_step2_define_classes.m
  - classifies global land area using the Holdridge classification system

3) holdridge_step3_calculate_change.m
  - calculates future changes in Holdridge zones 

4) holdridge_step4_analyses_main.m
  - combines holdridge data with resilience and, crop and animal production;
    calculates the proportions within and outside Safe Climatic Space;
    the scripts in step 4 require four external MATLAB packages:
    cbarrow, export_fig, crameri, wprctile

5) holdridge_step5_format_tables.m
  - formats output tables based on scripts in step 4

6) holdridge_step6_holdridge_ggtern.R
  - plots the results computed in step 4 as ternary plots

Functions, except for those which are from external packages, required to run the codes,
are in the 'functions' folder, and the data used for downloading the data and creating the
holdridge zones are in the 'input' folder. Use the provided hLand.mat file to have the same
land mask that was used in the analyses of the study.

The scripts have a coherent file structure, but crop and animal production,
and resilience data are from external sources (2,3,4). Crop production calculations
can be found in R-script 'production_kcal_spam2010.R'.

References:
1) Fick, S.E., and Hijmans, R.J. (2017). WorldClim 2: new 1-km spatial resolution climate surfaces
   for global land areas. International Journal of Climatology 37, 4302–4315.
2) Yu, Q., You, L., Wood-Sichra, U., Ru, Y., Joglekar, A.K.B., Fritz, S., Xiong, W., Lu, M., Wu, W.,
   and Yang, P. (2020). A cultivated planet in 2010 – Part 2: The global gridded agriculturalproduction
   maps. Earth System Science Data 12, 3545–3572.
3) Gilbert, M., Nicolas, G., Cinardi, G., Van Boeckel, T.P., Vanwambeke, S.O., Wint, G.R.W., and
   Robinson, T.P. (2018). Global distribution data for cattle, buffaloes, horses, sheep, goats, pigs,
   chickens and ducks in 2010. Scientific Data 5, 180227.
4) Varis, O., Taka, M., and Kummu, M. (2019). The Planet’s Stressed River Basins: Too Much
   Pressure or Too Little Adaptive Capacity? Earth’s Future 7, 1118–1135.

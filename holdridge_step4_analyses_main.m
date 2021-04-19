clear; clc

% set the folder where .m file is as a working directory
dir = fileparts(matlab.desktop.editor.getActiveFilename);
cd(dir)

%% Create folders for outputs

results_folder = fullfile(dir,'results_review');
ternary_folder = fullfile(dir,'results_review','ternary_mapping');
tables_folder = fullfile(dir,'results_review','matlab');

if exist(results_folder, 'dir') ~= 7
    mkdir( results_folder );
end

if exist(ternary_folder, 'dir') ~= 7
    mkdir( ternary_folder );
end

if exist(tables_folder, 'dir') ~= 7
    mkdir( tables_folder );
end

%% Add paths to search path:
addpath('functions');
addpath('ext_functions\wprctile');
addpath('ext_functions\crameri_v1.05\crameri')
addpath('ext_functions\cbarrow_v1.1\cbarrow')
addpath('ext_functions\altmany-export_fig-5b3965b\altmany-export_fig-5b3965b')

%% SCS main for year 2090 - all outputs:

% Livestock
[ls_med_26, ls_GCMs_26, ls_res_26, ls_cntry_26] = f_holdridge_vs_ref_boxed(dir, 'livestock_au', 'hold_2090', 'rcp26', true, true, true);
[ls_med_85, ls_GCMs_85, ls_res_85, ls_cntry_85] = f_holdridge_vs_ref_boxed(dir, 'livestock_au', 'hold_2090', 'rcp85', true, true, true);

% Crop Production - SPAM
[crop_med_26, crop_GCMs_26, crop_res_26, crop_cntry_26] = f_holdridge_vs_ref_boxed(dir, 'crop_spam', 'hold_2090', 'rcp26', true, true, true);
[crop_med_85, crop_GCMs_85, crop_res_85, crop_cntry_85] = f_holdridge_vs_ref_boxed(dir, 'crop_spam', 'hold_2090', 'rcp85', true, true, true);

cd(dir)
save 'results_review/matlab/main_results.mat' ls* crop*
clearvars -except dir

%% SCS for years 2030, 2050, 2070 - only aggregated outputs (median of GCMs and all GCMs separately)
tic
[ls_med_85_2070, ls_GCMs_85_2070, na, na] = f_holdridge_vs_ref_boxed(dir, 'livestock_au', 'hold_2070', 'rcp85', true, false, false);
[ls_med_85_2050, ls_GCMs_85_2050, na, na] = f_holdridge_vs_ref_boxed(dir, 'livestock_au', 'hold_2050', 'rcp85', true, false, false);
[ls_med_85_2030, ls_GCMs_85_2030, na, na] = f_holdridge_vs_ref_boxed(dir, 'livestock_au', 'hold_2030', 'rcp85', true, false, false);

[ls_med_26_2070, ls_GCMs_26_2070, na, na] = f_holdridge_vs_ref_boxed(dir, 'livestock_au', 'hold_2070', 'rcp26', true, false, false);
[ls_med_26_2050, ls_GCMs_26_2050, na, na] = f_holdridge_vs_ref_boxed(dir, 'livestock_au', 'hold_2050', 'rcp26', true, false, false);
[ls_med_26_2030, ls_GCMs_26_2030, na, na] = f_holdridge_vs_ref_boxed(dir, 'livestock_au', 'hold_2030', 'rcp26', true, false, false);

[crop_med_85_2070, crop_GCMs_85_2070, na, na] = f_holdridge_vs_ref_boxed(dir, 'crop_spam', 'hold_2070', 'rcp85', true, false, false);
[crop_med_85_2050, crop_GCMs_85_2050, na, na] = f_holdridge_vs_ref_boxed(dir, 'crop_spam', 'hold_2050', 'rcp85', true, false, false);
[crop_med_85_2030, crop_GCMs_85_2030, na, na] = f_holdridge_vs_ref_boxed(dir, 'crop_spam', 'hold_2030', 'rcp85', true, false, false);

[crop_med_26_2070, crop_GCMs_26_2070, na, na] = f_holdridge_vs_ref_boxed(dir, 'crop_spam', 'hold_2070', 'rcp26', true, false, false);
[crop_med_26_2050, crop_GCMs_26_2050, na, na] = f_holdridge_vs_ref_boxed(dir, 'crop_spam', 'hold_2050', 'rcp26', true, false, false);
[crop_med_26_2030, crop_GCMs_26_2030, na, na] = f_holdridge_vs_ref_boxed(dir, 'crop_spam', 'hold_2030', 'rcp26', true, false, false);
toc

save results_review/matlab/results_hold_2030to2070.mat ls* crop*
clearvars -except dir

%% Analyses about how resilience and holdridge percentiles relate to the livestock and food crop production

tbl_hold_res_ls_2090_26 = f_map_and_table_for_resilience_vs_holdridge_vs_ref(dir, 'livestock_au', 'hold_2090', 'rcp26', 4, 4, true, true);
tbl_hold_res_ls_2090_85 = f_map_and_table_for_resilience_vs_holdridge_vs_ref(dir, 'livestock_au', 'hold_2090', 'rcp85', 4, 4, true, true);

tbl_hold_res_crop_2090_26 = f_map_and_table_for_resilience_vs_holdridge_vs_ref(dir, 'crop_spam', 'hold_2090', 'rcp26', 4, 4, true, true);
tbl_hold_res_crop_2090_85 = f_map_and_table_for_resilience_vs_holdridge_vs_ref(dir, 'crop_spam', 'hold_2090', 'rcp85', 4, 4, true, true);

tbl_hold_res_ls_2090_26_sens = f_map_and_table_for_resilience_vs_holdridge_vs_ref(dir, 'livestock_au', 'hold_2090', 'rcp26', 4, [0, 20, 25, 30, 100], false, false);
tbl_hold_res_ls_2090_85_sens = f_map_and_table_for_resilience_vs_holdridge_vs_ref(dir, 'livestock_au', 'hold_2090', 'rcp85', 4, [0, 20, 25, 30, 100], false, false);

tbl_hold_res_crop_2090_26_sens = f_map_and_table_for_resilience_vs_holdridge_vs_ref(dir, 'crop_spam', 'hold_2090', 'rcp26', 4, [0, 20, 25, 30, 100], false, false);
tbl_hold_res_crop_2090_85_sens = f_map_and_table_for_resilience_vs_holdridge_vs_ref(dir, 'crop_spam', 'hold_2090', 'rcp85', 4, [0, 20, 25, 30, 100], false, false);

save results_review/matlab/tbl_hold_res.mat  tbl*
clearvars -except dir

%% Maps for background information

f_plot_baseline(dir,'livestock_au')
f_plot_baseline(dir,'crop_spam')
f_plot_baseline(dir,'res')
f_plot_baseline(dir,'res_cats')
f_plot_baseline(dir,'dir_rcp26')
f_plot_baseline(dir,'dir_rcp85')

f_hold_chg_baseline(dir,'rcp26','hold_2090', 4,[0,1])
f_hold_chg_baseline(dir,'rcp85','hold_2090',4,[0,1])

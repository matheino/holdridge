clear; clc

% set the folder where .m file is as a working directory
dir = fileparts(matlab.desktop.editor.getActiveFilename);
cd(dir)

%% Create folders for tables

tables_folder = fullfile(dir, 'results_review', 'tables');

if exist(tables_folder, 'dir') ~= 7
    mkdir( tables_folder );
end

%% Formating output table of aggregated SCS results relative to resilience

load 'results_review/matlab/main_results.mat' ls* crop*

% Check that data is reasonable
sum(ls_res_26(:,1))/10^9
sum(ls_res_85(:,1))/10^9
sum(crop_res_26(:,1))/10^9/6.5/365
sum(crop_res_85(:,1))/10^9/6.5/365

% Combine table from median and individual GCM results combined with
% resilience (results originally obtained from
% f_holdridge_vs_ref_boxed)
tbl_ls_rcp26 = [ls_med_26(2,:)' [ls_res_26(1:4,2)'; ls_res_26(5:end,2)']];
tbl_ls_rcp85 = [ls_med_85(2,:)' [ls_res_85(1:4,2)'; ls_res_85(5:end,2)']];
tbl_crop_rcp26 = [crop_med_26(2,:)' [crop_res_26(1:4,2)'; crop_res_26(5:end,2)']];
tbl_crop_rcp85 = [crop_med_85(2,:)' [crop_res_85(1:4,2)'; crop_res_85(5:end,2)']];

tbl_out = [tbl_ls_rcp26; sum(tbl_ls_rcp26,1);
    tbl_ls_rcp85; sum(tbl_ls_rcp85,1);
    tbl_crop_rcp26; sum(tbl_crop_rcp26,1)
    tbl_crop_rcp85; sum(tbl_crop_rcp85,1)];

sum(tbl_out(:,2:end),2)

filename = 'results_review\tables\SCS_res.xlsx'
xlswrite(filename, tbl_out)
clearvars -except dir crop_* ls_*


%% Boxplotted timeseries showing percentage of livestock and food crop production that fall outside SCS in GCMs
load results_review/matlab/results_hold_2030to2070.mat ls* crop*

% Table of the proportion of livestock that fall outside SCS
% for individual GCMs in 2030, 2050, 2070, 2090
tbl_gcm_ls_rcp26 = [ls_GCMs_26_2030(:,2), ls_GCMs_26_2050(:,2), ls_GCMs_26_2070(:,2), ls_GCMs_26(:,2)];
tbl_med_ls_rcp26 = [sum(ls_med_26_2030(2,:),2), sum(ls_med_26_2050(2,:),2), sum(ls_med_26_2070(2,:),2), sum(ls_med_26(2,:),2)];

tbl_gcm_ls_rcp85 = [ls_GCMs_85_2030(:,2), ls_GCMs_85_2050(:,2), ls_GCMs_85_2070(:,2), ls_GCMs_85(:,2)];
tbl_med_ls_rcp85 = [sum(ls_med_85_2030(2,:),2), sum(ls_med_85_2050(2,:),2), sum(ls_med_85_2070(2,:),2), sum(ls_med_85(2,:),2)];

hold on
% Scatter for median result
scatter([1,2,3,4], tbl_med_ls_rcp26, '*', 'c','g')
scatter([1,2,3,4], tbl_med_ls_rcp85, '*', 'c','g')

% Boxplot for results from different GCMs
boxplot(tbl_gcm_ls_rcp26, 'color', 'g', 'Symbol', 'o' )
boxplot(tbl_gcm_ls_rcp85, 'color', 'b', 'Symbol', 'o', 'Labels', {2030, 2050,2070,2090})
ylim([0, 0.48])
hold off
filename = strcat('results_review\SCS_lifestock_au_boxplot.eps')
print(gcf,filename,'-depsc2','-r300');

% Table of the proportion of food crop production that fall outside SCS
% for individual GCMs in 2030, 2050, 2070, 2090
tbl_gcm_crop_rcp26 = [crop_GCMs_26_2030(:,2), crop_GCMs_26_2050(:,2), crop_GCMs_26_2070(:,2), crop_GCMs_26(:,2)];
tbl_med_crop_rcp26 = [sum(crop_med_26_2030(2,:),2), sum(crop_med_26_2050(2,:),2), sum(crop_med_26_2070(2,:),2), sum(crop_med_26(2,:),2)]
tbl_gcm_crop_rcp85 = [crop_GCMs_85_2030(:,2), crop_GCMs_85_2050(:,2), crop_GCMs_85_2070(:,2), crop_GCMs_85(:,2)];
tbl_med_crop_rcp85 = [sum(crop_med_85_2030(2,:),2), sum(crop_med_85_2050(2,:),2), sum(crop_med_85_2070(2,:),2), sum(crop_med_85(2,:),2)]

figure
hold on
% Scatter for median result
scatter([1,2,3,4], tbl_med_crop_rcp26, '*', 'c','g')
scatter([1,2,3,4], tbl_med_crop_rcp85, '*', 'c','g')

% Boxplot for results from different GCMs
boxplot(tbl_gcm_crop_rcp26, 'color', 'g', 'Symbol', 'o' )
boxplot(tbl_gcm_crop_rcp85, 'color', 'b', 'Symbol', 'o', 'Labels', {2030, 2050,2070,2090})
ylim([0, 0.48])
hold off
filename = strcat('results_review\SCS_crop_spam_boxplot.eps')
print(gcf,filename,'-depsc2','-r300');


% Write boxplot results into a table
tbl_out = [[tbl_med_ls_rcp26; tbl_gcm_ls_rcp26],[tbl_med_crop_rcp26; tbl_gcm_crop_rcp26],...
    [tbl_med_ls_rcp85; tbl_gcm_ls_rcp85],[tbl_med_crop_rcp85; tbl_gcm_crop_rcp85]]

filename = 'results_review\tables\SCS_GCMs.xlsx'
xlswrite(filename, tbl_out)

clearvars -except dir


%% Country level SCS results

load 'results_review/matlab/main_results.mat' *cntry* 

% Check that the country ids match for each table
all(ls_cntry_26(:,[1,2]) == ls_cntry_85(:,[1,2]))
all(crop_cntry_26(:,[1,2]) == crop_cntry_85(:,[1,2]))
all( ls_cntry_85(:,1) == crop_cntry_26(:,1) )

% Combined matrices to one output table
cntry_tbl_out = [ls_cntry_26, ls_cntry_85(:,3:end), crop_cntry_26(:,2:end), crop_cntry_85(:,3:end)];

% As xlswrite doesn't handle NaN/Inf values well, transform those to
% numbers (inf values might come here when dividing zero with zero)
cntry_tbl_out(isinf(cntry_tbl_out)) = 0
cntry_tbl_out(isnan(cntry_tbl_out)) = -9999

filename = 'results_review\tables\cntry_SCS_results.xlsx'
xlswrite(filename, cntry_tbl_out)

clearvars -except dir

%% Tables showing the amount and proportion of livestock and food crop production in different Holdridge and Resilience categories
load results_review/matlab/tbl_hold_res.mat

filename = 'results_review\tables\hold_res_crop_spam_rcp26.xlsx'
xlswrite(filename, tbl_hold_res_crop_2090_26)

filename = 'results_review\tables\hold_res_crop_spam_rcp85.xlsx'
xlswrite(filename, tbl_hold_res_crop_2090_85)

filename = 'results_review\tables\hold_res_lifestock_au_rcp26.xlsx'
xlswrite(filename, tbl_hold_res_ls_2090_26)

filename = 'results_review\tables\hold_res_lifestock_au_rcp85.xlsx'
xlswrite(filename, tbl_hold_res_ls_2090_85)

clearvars -except dir


%% Testing sensitivity to the resilience threshold and the livestock and food crop production data used
load results_review/matlab/tbl_hold_res.mat
load results_review/matlab/main_results.mat ls* crop*


% SCS sensitivity for median results using different threshold
ls_med_85_tot = ls_med_85(2:end,:)
ls_med_26_tot = ls_med_26(2:end,:)

crop_med_85_tot = crop_med_85(2:end,:)
crop_med_26_tot = crop_med_26(2:end,:)

filename = 'results_review\tables\sens_res_hyde.xlsx'
xlswrite(filename, [[ls_med_85_tot; crop_med_85_tot], [ls_med_26_tot; crop_med_26_tot]]);


% Resilience sensitivity for tables showing the amount and proportion of 
% livestock and food crop production in different Holdridge and Resilience categories
sens_hold_res_out = [[sum(tbl_hold_res_ls_2090_26_sens(7:end,4)), sum(tbl_hold_res_ls_2090_26_sens(6:end,4)), tbl_hold_res_ls_2090_26_sens(8,4)];...
    [sum(tbl_hold_res_crop_2090_26_sens(7:end,4)), sum(tbl_hold_res_crop_2090_26_sens(6:end,4)), tbl_hold_res_crop_2090_26_sens(8,4)];...    
    [sum(tbl_hold_res_ls_2090_85_sens(7:end,4)), sum(tbl_hold_res_ls_2090_85_sens(6:end,4)), tbl_hold_res_ls_2090_85_sens(8,4)];...
    [sum(tbl_hold_res_crop_2090_85_sens(7:end,4)), sum(tbl_hold_res_crop_2090_85_sens(6:end,4)), tbl_hold_res_crop_2090_85_sens(8,4)]]';

filename = 'results_review\tables\sens_hold_res.xlsx'
xlswrite(filename, sens_hold_res_out);

clearvars -except dir


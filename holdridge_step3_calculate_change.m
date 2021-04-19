%% holdridge - future change
clear
close all

% set the folder where .m file is as a working directory
folder_wd = fileparts(matlab.desktop.editor.getActiveFilename);
cd(folder_wd)

%% Initialise run

% future time period (2030,2050,2070 or 2090)
futureYear = '2050';

% version of the run
s_version = '11';

%% DO NOT MODIFY FROM HERE ON

%% folder paths

% folder of the output
folder_results = fullfile(folder_wd,'holdridge_data');

% add paths of all needed functions 
folder_functions = fullfile(folder_wd,'functions');
addpath(genpath(folder_functions));

%% define input and out data strings

% date of running the code
date = datestr(now, 'yyyymmdd');

% saved data from step1
file_step2Present = sprintf('holdridge_data/holdridge_results_present_%s.mat', s_version );
file_step2Future = sprintf('holdridge_data/holdridge_results_year%s_%s.mat', futureYear, s_version ); 

% output data
file_resultsChange = sprintf('holdridge_data/holdridge_resultsChange_year%s_%s.mat', futureYear, s_version ); 
file_resultsMap = sprintf('holdridge_data/holdridge_resultsMap_year%s_%s.mat', futureYear, s_version ); 

%% load data

load(file_step2Present,'v_data_hold_present');
load(file_step2Future,'v_data_hold_future');
size(v_data_hold_future)

% % no yet future available, here just dummy future values
% v_data_hold_future = repmat(v_data_hold_present,1,1,4,11);
% v_data_hold_future = rand() * v_data_hold_future;

load(file_step2Present,'hold_class_ce*');

%% calculate the distance of change

temp_distance = zeros(36,36,'single');

for class = 1:size(hold_class_centroids,1)
    for class2 = 1:size(hold_class_centroids,1)
        temp_distance(class,class2) = ...
            sqrt( power((hold_class_centroids(class,3)-hold_class_centroids(class2,3)),2) +...
            (power((hold_class_centroids(class,4)-hold_class_centroids(class2,4)),2)));
    end
end

% zero to 1
temp_distance(temp_distance == 0) = 1;

% find three smallest value
Xs=sort(temp_distance,2);
distance_min_mean = mean(mean(Xs(:,1:3)));

hold_class_centroids(:,5) = mean(Xs(:,1:3),2);

clearvars class* temp* Xs

%% calculate change between present and future

v_data_distance = zeros(size(v_data_hold_present,1),2,size(v_data_hold_future,3),size(v_data_hold_future,4),'single');

% calculate distance of change
for gcm = 1:size(v_data_hold_future,4)
    for rcp = 1:size(v_data_hold_future,3)
        v_data_distance(:,1,rcp,gcm) = sqrt( power((v_data_hold_present(:,6)-v_data_hold_future(:,6,rcp,gcm)),2)...
            + (power((v_data_hold_present(:,7)-v_data_hold_future(:,7,rcp,gcm)),2)));
    end
end

% set different classes for distance
% if distance between present and future is less than 25% of the distance btw centroids, it is not counted
temp_threshold = 0;
temp_threshold(2) = 0.25 * distance_min_mean;
temp_threshold(3) = 0.5 * distance_min_mean;
temp_threshold(4) = 0.75 * distance_min_mean;
temp_threshold(5) = 1 * distance_min_mean;
temp_threshold(6) = nanmax(nanmax(nanmax((v_data_distance(:,1,:,:)))));

for gcm = 1:size(v_data_hold_future,4)
    for rcp = 1:size(v_data_hold_future,3)
        v_temp = zeros(size(v_data_distance(:,1,rcp,gcm)));
        for i = 1:5
            temp = v_data_distance(:,1,rcp,gcm);
            temp = temp >= temp_threshold(i) & temp < temp_threshold(i+1);
            v_temp(temp) = i;
            
            clearvars temp;
        end
        
        v_data_distance(:,2,rcp,gcm) = v_temp;
        
        clearvars v_temp
    end
end

clearvars rcp gcm ans i save v_temp* temp*

% save data
if isfile(file_resultsChange)
    % if file does exist, only append to that one
     save(file_resultsChange,'v_data_distance','-append')
else
    % if it does not exist, create file and save to that one
     save(file_resultsChange, 'v_data_distance','-v7.3')
end

save(file_resultsChange,'distance_min_mean','-append')

%% direction of change

% second dimension: angle, category of angle (direction), h, s, v
% categories: latitudinal region direction (1), wetter conditions (2), larger PET ratio (3)
% HSV color indicates: h is angle, s is distance, v is darkness
v_angle_fut_pres = zeros(size(v_data_distance,1),5,size(v_data_distance,3),size(v_data_distance,4),'single');

% category for direction of change
angle_threshold = pi;
angle_threshold(2) = 5/6*pi;
angle_threshold(3) = pi/6;
angle_threshold(4) = -pi/2;
angle_threshold(5) = -pi;

for gcm = 1:size(v_data_hold_future,4)
    for rcp = 1:size(v_data_hold_future,3)
        [v_angle_fut_pres(:,:,rcp,gcm)] =...
            f_holdridge_change_direction(v_data_hold_present(:,6),v_data_hold_future(:,6,rcp,gcm),...
            v_data_distance(:,1,rcp,gcm),angle_threshold);
    end
end

clearvars rcp gcm ans i

save(file_resultsChange,'v_angle_fut_pres','-append')

%% back to map - present

load(file_step2Present,'hLand','hIndex');

% present
% class
hold_map_present = f_holdridge_back2map(v_data_hold_present(:,10), hLand, hIndex);
% cartesian coordinates
hold_map_present(:,:,2) = f_holdridge_back2map(v_data_hold_present(:,6), hLand, hIndex);
hold_map_present(:,:,3) = f_holdridge_back2map(v_data_hold_present(:,7), hLand, hIndex);

%% back to map - future

hold_map_future = zeros(size(hLand,1),size(hLand,2),3,size(v_data_hold_future,3),size(v_data_hold_future,4),'single');

for gcm = 1:size(v_data_hold_future,4)
    for rcp = 1:size(v_data_hold_future,3)
        % class
        hold_map_future(:,:,1,rcp,gcm) = f_holdridge_back2map(v_data_hold_future(:,10,rcp,gcm), hLand, hIndex);
        % cartesian coordinates
        hold_map_future(:,:,2,rcp,gcm) = f_holdridge_back2map(v_data_hold_future(:,6,rcp,gcm), hLand, hIndex);
        hold_map_future(:,:,3,rcp,gcm) = f_holdridge_back2map(v_data_hold_future(:,7,rcp,gcm), hLand, hIndex);
    end
end


%% back to map - change

hold_map_change = zeros(size(hLand,1),size(hLand,2),3,size(v_data_hold_future,3),size(v_data_hold_future,4),'single');

for gcm = 1:size(v_data_hold_future,4)
    for rcp = 1:size(v_data_hold_future,3)
        % distance from present
        hold_map_change(:,:,1,rcp,gcm) = f_holdridge_back2map(v_data_distance(:,1,rcp,gcm), hLand, hIndex);
        % angle of change
        hold_map_change(:,:,2,rcp,gcm) = f_holdridge_back2map(v_angle_fut_pres(:,1,rcp,gcm), hLand, hIndex);
        % category of change
        hold_map_change(:,:,3,rcp,gcm) = f_holdridge_back2map(v_angle_fut_pres(:,2,rcp,gcm), hLand, hIndex);
    end
end


%% save

save(file_resultsMap, 'hold_map*')

% %% write geotiff maps
% 
% % load needed data (if not in workspace)
% if exist('hold_map_present','var') == 0
%     load(file_resultsMap)
% else
%     % nothing happends
% end
% 
% % order of layers:
% % present: lat, lon, results (hold class, cartesian coordinate x, cartesian
% % coordinate y)
% % future: lat, lon, results (hold class, cartesian coordinate x, cartesian
% % coordinate y), RCP (2.6, 8.5), GCMs (11 different GCMs)
% 
% %size(hold_map_future)
% 
% 
% export to geotiff - present
geotiffNamePresent = sprintf('holdridge_data/holdridge_5min_present_%s.tif',date );

R_5arcmin = georasterref('RasterSize', [2160 4320], ...
      'RasterInterpretation', 'cells', 'ColumnsStartFrom', 'north', ...
      'LatitudeLimits', [-90 90], 'LongitudeLimits', [-180 180]);
temp = single(hold_map_present(:,:,1));
temp(temp == 0) = NaN;
geotiffwrite(geotiffNamePresent,int16(temp),R_5arcmin);


% future - SSP1_2.6
geotiffNameRCP26 = sprintf('holdridge_data/holdridge_5min_RCP26_year%s_%s.tif', futureYear,date );

R_5arcmin = georasterref('RasterSize', [2160 4320], ...
      'RasterInterpretation', 'cells', 'ColumnsStartFrom', 'north', ...
      'LatitudeLimits', [-90 90], 'LongitudeLimits', [-180 180]);
temp = single(nanmean(hold_map_future(:,:,1,1,:),5));
temp(temp == 0) = NaN;
geotiffwrite(geotiffNameRCP26,int16(temp),R_5arcmin);



% future - SSP5_8.5
geotiffNameRCP85 = sprintf('holdridge_data/holdridge_5min_RCP85_year%s_%s.tif', futureYear,date );

R_5arcmin = georasterref('RasterSize', [2160 4320], ...
      'RasterInterpretation', 'cells', 'ColumnsStartFrom', 'north', ...
      'LatitudeLimits', [-90 90], 'LongitudeLimits', [-180 180]);
temp = single(nanmean(hold_map_future(:,:,1,2,:),5));
temp(temp == 0) = NaN;
geotiffwrite(geotiffNameRCP85,int16(temp),R_5arcmin);








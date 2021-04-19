function [SCS_out, aggreg_SCS_GGCMs] = f_mask_for_boxed_raster(ref_data, ref_mask, hold_scen_x, hold_scen_y, bool_present_scenario, hLand, res_raster, dtype, rcp, hold, dir)

    % Obtain resilience quantiles, and isolate lowest resilience quantiles
    [res_cats, temp] = f_hold_rast_categories(res_raster, res_raster, 4, 4);
    res_cats
    res_rast_boolean = res_raster >= res_cats(1) & res_raster < res_cats(2);

    % Initialize grid intervals.
    thresholds = linspace(0.0,1.0,101);
    thresholds(1) = -inf;

    % Vectorize data to allow faster computation
    ref_v = ref_data(:);
    SCS_map_v = zeros(size(ref_v));
    ref_mask_v = ref_mask(:);

    % Create an empty table for aggregated results
    aggreg_SCS_GGCMs = zeros(size(hold_scen_x,5),2);

    % Loop through all GCMs
    for GCM_index = 1:size(hold_scen_x,5)

        % Isolate those intervals in o a 100 x 100  holdridge grid (0.01 spacing)
        % where there is reference data, based on the holdridge x and y
        % coordinates for each GCM.
        hold_scen_x_k = squeeze(hold_scen_x(:,:,:,:,GCM_index));
        hold_scen_y_k = squeeze(hold_scen_y(:,:,:,:,GCM_index));

        [NA, bool_GCM_scenario] = f_100x100_holdridge_box(ref_data, hold_scen_x_k, hold_scen_y_k, 0.95);

        hold_scen_x_v = hold_scen_x_k(:);
        hold_scen_y_v = hold_scen_y_k(:);

        SCS_map_GCM_v = zeros(size(SCS_map_v));

        for i = 1:length(thresholds)-1
            for j = 1:length(thresholds)-1

                % Set 1 (True) to those areas, which fall outside safe climatic space,
                % i.e. areas projected to be within holdridge intervalse where
                % where there is reference data in the GCM scenario
                % but not in the present day (year 2010) scenario
                if bool_GCM_scenario(j,i) == 1 & bool_present_scenario(j,i) == 0

                    logical_i_j = hold_scen_x_v > thresholds(i) & ...
                        hold_scen_x_v <= thresholds(i+1) & ...
                        hold_scen_y_v > thresholds(j) & ...
                        hold_scen_y_v <= thresholds(j+1);        

                    SCS_map_GCM_v(logical_i_j) = 1;                    

                end
            end
        end
        
        % Set those areas to zero, which fall outside the present holdridge
        % extent defined before
        SCS_map_GCM_v(~ref_mask_v) = 0;

        % Calculate proprtion of reference data that fall within (1st column) and
        % outside (2nd column) SCS for each GCM
        aggreg_SCS_GGCMs(GCM_index, 1) = sum((SCS_map_GCM_v == 0).*ref_data(:).*ref_mask_v)/sum(ref_data(:).*ref_mask_v);
        aggreg_SCS_GGCMs(GCM_index, 2) = sum((SCS_map_GCM_v == 1).*ref_data(:).*ref_mask_v)/sum(ref_data(:).*ref_mask_v);
        
        % For each GCM add 1 to those areas, where each GCM show a fall outside
        % SCS
        SCS_map_v = SCS_map_v + SCS_map_GCM_v;

    end

    % Reshape the vectorized data to matrix format
    SCS_map = reshape(SCS_map_v, size(ref_data));

    % Categorize the data based on the number of GCMs that fall outside safe
    % climtic space
    SCS_out = zeros(size(ref_data));
    SCS_out(SCS_map == 0) = 1;
    SCS_out(SCS_map > 0 & SCS_map <= 3) = 2;
    SCS_out(SCS_map > 3 & SCS_map <= 6) = 3;
    SCS_out(SCS_map > 6 & SCS_map <= 8) = 4;
    
    SCS_nores_out = SCS_out;
    
    % Add 4 to the categories, if the area has low resilience
    SCS_out(res_rast_boolean) = SCS_out(res_rast_boolean)+4;

    % Isolate non-land areas and areas without reference data
    SCS_out(ref_mask == 0 | ref_data == 0) = 0;
    SCS_out(~hLand) = -9999;
    
    SCS_nores_out(ref_mask == 0 | ref_data == 0) = 0;
    SCS_nores_out(~hLand) = -9999;

    % Create color mapping for the SCS_out map
    red =   [230, 199, 229, 197, 172, 125,  238,  189, 165, 255] / 255;
    green = [230, 217, 218, 177, 142, 162,  125,  75,  33,  255] / 255;
    blue =  [230, 229, 155, 81,  48,  188,  136,  82,  34,  255] / 255;

    rgb_map_red = zeros(2160,4320);
    rgb_map_green = zeros(2160,4320);
    rgb_map_blue = zeros(2160,4320);

    j = 0;
    for i = [0, 1, 2, 3, 4, 5, 6, 7, 8, -9999]
        j = j+1;
        bool_temp = SCS_out == i;

        rgb_map_red(bool_temp) = red(j);
        rgb_map_green(bool_temp) = green(j);
        rgb_map_blue(bool_temp) = blue(j);
    end

    rgb_map_out = flip(cat(3,rgb_map_red,rgb_map_green,rgb_map_blue),1);
    
    % Create color mapping for the SCS_nores_out map
    red = red([1,6,4,8,9,10]);
    green = green([1,6,4,8,9,10]);
    blue =  blue([1,6,4,8,9,10]);
    red(3) = 236/255;
    green(3) = 238/255;
    blue(3) = 147/255;
    rgb_map_red = zeros(2160,4320);
    rgb_map_green = zeros(2160,4320);
    rgb_map_blue = zeros(2160,4320);

    j = 0;
    for i = [0, 1, 2, 3, 4, -9999]
        j = j+1;
        bool_temp = SCS_nores_out == i;

        rgb_map_red(bool_temp) = red(j);
        rgb_map_green(bool_temp) = green(j);
        rgb_map_blue(bool_temp) = blue(j);
    end

    rgb_map_nores_out = flip(cat(3,rgb_map_red,rgb_map_green,rgb_map_blue),1);

    % Export the mapped SCS_out in png format
    load coastlines

    figure('units','normalized','outerposition',[0 0 1 1]);
    R = georasterref('LatitudeLimits', [-90 90],'LongitudeLimits', [-180 180],'RasterSize', [2160 4320]);
    axesm ('robinson', 'Frame', 'off', 'Grid', 'off','MapLatLimit',[-60,90],'MapLonLimit',[-180,180]);
    geoshow(rgb_map_out, R);
    geoshow(coastlat,coastlon,'Color', 'black')
    set(gca,'XColor','none','YColor','none','XTick',[],'YTick',[])
    
    % save figure
    filename = strcat(dir,'\results_review\map_',dtype,'_',rcp,'_',hold,'.png')
    export_fig(gcf,filename,'-png');
    close all
    
    % Export the mapped SCS_nores_out in png format
    figure('units','normalized','outerposition',[0 0 1 1]);
    R = georasterref('LatitudeLimits', [-90 90],'LongitudeLimits', [-180 180],'RasterSize', [2160 4320]);
    axesm ('robinson', 'Frame', 'off', 'Grid', 'off','MapLatLimit',[-60,90],'MapLonLimit',[-180,180]);
    geoshow(rgb_map_nores_out, R);
    geoshow(coastlat,coastlon,'Color', 'black')
    set(gca,'XColor','none','YColor','none','XTick',[],'YTick',[])

    % save figure
    filename = strcat(dir,'\results_review\map_nores_',dtype,'_',rcp,'_',hold,'.png')
    export_fig(gcf,filename,'-png');
    close all

    
    R_geotiff = georasterref('RasterSize', [2160 4320], ...
        'RasterInterpretation', 'cells', 'ColumnsStartFrom', 'north', ...
        'LatitudeLimits', [-90 90], 'LongitudeLimits', [-180 180]);
    
    % save SCS_out as geotiff
    filename_tiff = strcat(dir,'\results_review\SCS_map_',dtype,'_',rcp,'_',hold,'.tif')
    SCS_out(SCS_out == -9999) = NaN;
    geotiffwrite(filename_tiff, single(SCS_out), R_geotiff);
    
    % save SCS_nores_out as geotiff
    filename_tiff = strcat(dir,'\results_review\SCS_nores map_',dtype,'_',rcp,'_',hold,'.tif')
    SCS_nores_out(SCS_nores_out == -9999) = NaN;
    geotiffwrite(filename_tiff, single(SCS_nores_out), R_geotiff);
    
end






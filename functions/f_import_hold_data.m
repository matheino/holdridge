function [hold_map_present, hold_map_future, hold_map_change] = f_import_hold_data(dir, hold_src)

    cd(dir)

    % hold_map_future (dimensions: 2160 x 4320 x 3 x 4 x 11)
    % Third dimension:
    %   1 layer: Holdridge classification (see xls file provided separately)
    %   2 layer: Cartesian x-coordinate
    %   3 layer: Cartesian y-coordinate
    % Fourth dimension: different RCPs (2.6, 8.5)
    % Fifth dimension: different GCMs
    
    
    % Import holdridge data for the specified scenario (i.e. year)
    if strcmp(hold_src, 'hold_2090')
        load('holdridge_data\holdridge_resultsMap_year2090_11.mat');
    elseif strcmp(hold_src, 'hold_2070')
        load('holdridge_data\holdridge_resultsMap_year2070_11.mat');
    elseif strcmp(hold_src, 'hold_2050')
        load('holdridge_data\holdridge_resultsMap_year2050_11.mat');
    elseif strcmp(hold_src, 'hold_2030')
        load('holdridge_data\holdridge_resultsMap_year2030_11.mat');
    end
    
end
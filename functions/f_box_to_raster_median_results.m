function [SCS_out, glob_sum] = f_box_to_raster_median_results(ref_data, hold_scen_x, hold_scen_y, bool_future_scenario, bool_present_scenario, hLand, res_raster)


    % Obtain resilience quantiles, and isolate lowest resilience quantile
    [res_cats_sens, temp] = f_hold_rast_categories(res_raster, res_raster, [0,20,30,100], 4);
    [res_cats, temp] = f_hold_rast_categories(res_raster, res_raster, 4, 4);
    clear temp

    res_cats
    
    % Find areas on map where resilience is in the lowest category, i.e.
    % lowest 25% in the main analysis, while 20% and 30% threshold for 
    % testing sensitivity
    res_rast_boolean = res_raster >= res_cats(1) & res_raster < res_cats(2);
    res_rast_boolean_20 = res_raster >= res_cats_sens(1) & res_raster < res_cats_sens(2);
    res_rast_boolean_30 = res_raster >= res_cats_sens(1) & res_raster < res_cats_sens(3);

    % Initialize grid intervals.
    thresholds = linspace(0.0,1.0,101);
    thresholds(1) = -inf;

    % Vectorize data to allow faster computation
    ref_v = ref_data(:);
    SCS_map_v = zeros(size(ref_v));

    hold_scen_x = hold_scen_x(:);
    hold_scen_y = hold_scen_y(:);


    % Find those areas, which fall outside safe climatic space, i,e. areas projected
    % to be within holdridge intervalse where where there is reference data
    % in the median GCM scenario but not in the present day reference scenario,
    % and turn those values to one.
    for i = 1:length(thresholds)-1
        for j = 1:length(thresholds)-1

            if bool_present_scenario(j,i) == 0 & bool_future_scenario(j,i) == 1

                logical_i_j = hold_scen_x > thresholds(i) & ...
                    hold_scen_x <= thresholds(i+1) & ...
                    hold_scen_y > thresholds(j) & ...
                    hold_scen_y <= thresholds(j+1);        

                SCS_map_v(logical_i_j) = 1;
            end

        end
    end

    % Reshape the vectorized data to matrix format and categorize low
    % resilience areas
    SCS_out = reshape(SCS_map_v, size(ref_data));
    SCS_out(SCS_out == 1 & res_rast_boolean) = 2;

    % Calculate the sum an percentage of the reference data 
    % in the resilience categories
    % Resilience theshold: 25%
    abs_res = nansum(nansum((SCS_out == 1) .*ref_data));
    abs_nores = nansum(nansum((SCS_out == 2) .*ref_data));

    perc_res = abs_res / nansum(nansum(ref_data));
    perc_nores = abs_nores / nansum(nansum(ref_data));
    
    % Resilience theshold: 20%
    perc_res_20 = nansum(nansum((SCS_out >= 1 & res_rast_boolean_20 == 0) .*ref_data)) / nansum(nansum(ref_data));
    perc_nores_20 = nansum(nansum((SCS_out >= 1 & res_rast_boolean_20 == 1) .*ref_data)) / nansum(nansum(ref_data));

    % Resilience theshold: 30%
    perc_res_30 = nansum(nansum((SCS_out >= 1 & res_rast_boolean_30 == 0) .*ref_data)) / nansum(nansum(ref_data));
    perc_nores_30 = nansum(nansum((SCS_out >= 1 & res_rast_boolean_30 == 1) .*ref_data)) / nansum(nansum(ref_data));

    perc_median_outside_SCS = perc_res+perc_nores

    % Finally, create a table of the global aggregates
    glob_sum = [abs_res, abs_nores; perc_res, perc_nores; perc_res_20, perc_nores_20; perc_res_30, perc_nores_30];

end

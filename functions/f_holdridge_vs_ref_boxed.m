function [aggreg_SCS_med, aggreg_SCS_GGCMs, glob_ref_res_table_out, cntry_table] = f_holdridge_vs_ref_boxed(dir,...
    ref_src, ...
    hold_src, ...
    clim_scen, ...
    GCMs_yes,...
    cntry_yes,...
    ternary_yes)

    aggreg_SCS_med = NaN;
    aggreg_SCS_GGCMs = NaN;
    glob_ref_res_table_out = NaN;
    cntry_table = NaN;
    

    %% Import holdridge, resilience, and livestock / food crop production data as well as a land mask and country id raster
    cd(dir)
    
    % Land data
    load('holdridge_data\hLand.mat')

    % Resilience data:
    res_time = ncread('ref_data\resilience.nc', 'time');
    res_all = ncread('ref_data\resilience.nc', 'resilience');
    res_m = res_all(:,:,res_time == 2010)';
    res_m(res_m == -9) = NaN;
    res_m(~hLand) = NaN;

    % Reference data (i.e. livestock / food crop production):
    ref_m = f_import_ref_data(dir, ref_src);    
    ref_m_present = ref_m;
    
    % Holdridge data
    [hold_map_present, hold_map_future, NA] = f_import_hold_data(dir, hold_src);

    % Country id raster
    [cntry_m, R_cntry] = geotiffread('ref_data\cntry_raster_fao_id_plus.tif');
    cntry_m(~hLand) = 0;
    
    % Select RCP scenario index
    if strcmp(clim_scen,'rcp26')
        rcp_i = 1;
    elseif strcmp(clim_scen,'rcp85')
        rcp_i = 2;
    end

    clear R* hold_map_change mapAnalysis NA

    
    %% Holdridge mapping for present day (2010) scnario
    
    % Present day holdrige mapping for livestock or food crop production
    [aggreg_box_present, bool_box_present] = f_100x100_holdridge_box(ref_m_present, hold_map_present(:,:,2), hold_map_present(:,:,3), 0.95);

    % Creata a spatial mask for current livestock or food crop production
    % that includes Holdridge areas that hold 95% of total livestock or
    % food crop production
    ref_present_mask = f_hold_mask_ref_raster(ref_m_present, hold_map_present(:,:,2), hold_map_present(:,:,3), bool_box_present);
    ref_95_prcnt_hold_pres = ref_m.*ref_present_mask;
    
    %% Holdridge mapping (median), future
    
    % Calculate median across different GCMs
    hold_med = nanmedian(hold_map_future,5);

    % Aggregate livestock and food crop production data to a 100x100 holdridge grid
    % that is based on median holdridge x and y coordinates.
    [aggreg_box_med, bool_box_med] = f_100x100_holdridge_box(ref_m, hold_med(:,:,2,rcp_i),hold_med(:,:,3,rcp_i), 0.95);    

    %% Median aggregates to matrix and median global table
    
    [ref_map_med, aggreg_SCS_med] = f_box_to_raster_median_results(ref_95_prcnt_hold_pres, hold_med(:,:,2,rcp_i), hold_med(:,:,3,rcp_i), bool_box_med, bool_box_present, hLand, res_m);
    
    %% Proportion of GGCMs that  aggregates to matrix and median global table
    if GCMs_yes == true
        
        [ref_map_GCMs, aggreg_SCS_GGCMs] = f_hold_ref_box_to_raster_allGCMs(ref_m, ref_present_mask, hold_map_future(:,:,2,rcp_i,:), hold_map_future(:,:,3,rcp_i,:), bool_box_present, hLand, res_m, ref_src, clim_scen, hold_src, dir);

    % Aggregate results globally
  
        glob_ref_GCMs_abs = zeros(8,1);

        for i = 1:8

            glob_ref_GCMs_abs(i,1) = nansum(nansum(ref_95_prcnt_hold_pres.*(ref_map_GCMs == i)));

        end

        glob_ref_GCMs_prop = glob_ref_GCMs_abs / sum(glob_ref_GCMs_abs);

        glob_ref_res_table_out = [glob_ref_GCMs_abs, glob_ref_GCMs_prop];
        
    end

    %% Aggregate results for each country
    
    if cntry_yes == true
    
    % Create country indices
        cntry_m(cntry_m == 0) = max(cntry_m(:))+999;
        cntry_idx = double(accumarray(cntry_m(:), cntry_m(:),[],@nanmax));
    
    % Calculate sum of ref data outside safe climatic space
    % an with low resilience for each country
        ref_xtrm = ref_95_prcnt_hold_pres.*(ref_map_GCMs == 4 | ref_map_GCMs == 8);
        ref_res_xtrm = ref_95_prcnt_hold_pres.*(ref_map_GCMs == 8);

        ref_tot_per_cntry = accumarray(cntry_m(:), ref_95_prcnt_hold_pres(:), [], @nansum);

    % Create a table for country level results - columns: country_id, sum
    % of reference data, proportion outside SCS, and proportion outside SCS
    % with low resilience.
        cntry_table = [cntry_idx,...
            ref_tot_per_cntry,...
            accumarray(cntry_m(:),ref_xtrm(:),[],@nansum) ./ ref_tot_per_cntry,...
            accumarray(cntry_m(:),ref_res_xtrm(:),[],@nansum) ./ ref_tot_per_cntry,...
            ];

        cntry_table(cntry_table(:,1) == 0,:) = [];
    
    end

    %%
    if ternary_yes == true
    % Define min and max for PET-ratio (2nd column) and precipitation (1st column)
        class_bound = [62.5 0.125; 16000 32];

    % Define center of the 
        x = linspace(0.005,0.995,100);
        y = linspace(0.005,0.995,100);

        [X, Y] = meshgrid(x,y);

        X = X(:);
        Y = Y(:);

    % Based on the x- and y-coordinates, calculate the location on the axis in
    % the holdridge triangle for precipitation (t1) and PET-ratio (t2). The
    % equations are reverse engineered from f_holdridge_cartesian_coord.m
        t1 = X-0.5*Y;
        t2 = 1-X-0.5*Y;

    % Calculate precipitation and PET-ratio, based on the location on the
    % triangle axes.
        log10_precip = t1*(log10(class_bound(2,1))-log10(class_bound(1,1))) + log10(class_bound(1,1));
        precip = 10.^log10_precip;

        log10_PET_ratio = t2*(log10(class_bound(2,2))-log10(class_bound(1,2))) + log10(class_bound(1,2));
        PET_ratio = 10.^log10_PET_ratio;

    % Check that the numbers make sense.
        'min P'
        min(precip)
        'max P'
        max(precip)

        'min PET'
        min(PET_ratio)
        'max PET'
        max(PET_ratio)

    % Export the data
        aggreg_box_present(~bool_box_present) = 0;
        aggreg_box_med(~bool_box_med) = 0;

        v_aggreg_box_present = aggreg_box_present(:);
        v_aggreg_box_med = aggreg_box_med(:);

        filename = strcat(dir,'\results_review\ternary_mapping\holdridge_PET_precip_tabulted_',ref_src,'_',clim_scen,'_',hold_src,'.csv')

        csvwrite(filename,[PET_ratio, precip, v_aggreg_box_present, v_aggreg_box_med]);
        
    end




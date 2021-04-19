function ref_m = f_import_data(dir, ref_src)

    cd(dir)

    load('holdridge_data\hLand.mat')
    
    % Import reference data based on ref_src variable
        
    if strcmp(ref_src, 'crop_spam')
        [ref_m, R_crop] = geotiffread('ref_data\kcal_tot_final_resampled.tif');
        
    elseif strcmp(ref_src, 'livestock_au')
        [ref_m, R_ls] = geotiffread('ref_data\AU_per_pixel.tif');
        ref_m(ref_m == nanmin(ref_m(:))) = 0;
    end

    % Change no data or no land cells to zero
    ref_m(ref_m == -9999) = 0;
    ref_m(isnan(ref_m)) = 0;
    ref_m(hLand == 0) = 0;
    
end
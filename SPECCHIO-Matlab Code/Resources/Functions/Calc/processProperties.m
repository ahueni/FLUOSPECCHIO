function processProperties(user_data, ids_Rapp, ids_SIF)
out_table = user_data.out_table;

[ids_FLAME, space_FLAME, spectra_FLAME, filenames_FLAME] = restrictToSensor(user_data, 'RoX', ids_Rapp);


VI = computeVIs(space_FLAME.getAverageWavelengths(), spectra_FLAME);
insertVIs(user_data, ids_FLAME, VI);

SIFmetric = table(out_table.f_int, out_table.f_max_R, out_table.f_max_FR) ;
SIFmetric.Properties.VariableNames = {'Total_SIF', 'SIF_R_max','SIF_FR_max'};
insertVIs(user_data, ids_SIF, SIFmetric);

end
function [outF_SpecFit, outR_SpecFit, SIF_R_max, SIF_R_wl,     ...
    SIF_FR_max, SIF_FR_wl, SIFint,  outF_SFM, outR_SFM, ...
    provenance_spectrum_ids] = processFLUO(ids, space, spectra, filenames)
 % select groups of 3 and loop over data
     group_no = ids.size / 3;
     no_of_bands = space.getDimensionality.intValue; % use explicit conversion as for some reason a Java Integer cannot be used to create a matrix with 'ones'.
     
     
     [L, L0] = deal(zeros(no_of_bands, group_no));
     % DEFINE OUTPUT ARRAYS:
     provenance_spectrum_ids    = java.util.ArrayList();

     [outF_SpecFit, outR_SpecFit, SIF_R_max, SIF_R_wl,     ...
        SIF_FR_max, SIF_FR_wl, SIFint, outF_SFM_A, outF_SFM_B, outR_SFM_A,  ...
        outR_SFM_B] = deal(nan(no_of_bands, ids.size));
     
     for i=0:group_no-1
         
         group_start = i*3;
         
         group_filenames = filenames.subList(group_start, group_start+3);
         
         % select WR by file name | WR = Incoming radiance (n.b.: WR and VEG
         % might be flipped, is handled later on)
         WR_pos = false(3,1);
         for j=0:2
             
             filename = java.lang.String(group_filenames.get(j));
             if(filename.contains(java.lang.String('WR')))
                 
                 WR_pos(j+1) = true; % zero indexed
                 
             end
             
         end
         
         WR_indices = false(ids.size, 1);
         TGT_indices = WR_indices;
         WR_indices(group_start+1:group_start+1+2) = WR_pos;
         TGT_indices(group_start+1:group_start+1+2) = ~WR_pos;
         
         % calculate average WR and TGT, but only if there is more than 1
         % spectrum
         WR_arr = spectra(WR_indices, :);
         
         if(sum(WR_indices) > 1)
             WR_avg = mean(WR_arr);
         else
             WR_avg = WR_arr;
         end
         
         % calculate average TGT (just in case the channels were switched)
         TGT_arr = spectra(TGT_indices, :);
         
         if(sum(TGT_indices) > 1)
             TGT_avg = mean(TGT_arr);
         else
             TGT_avg = TGT_arr;
         end
       
         
         % calculate SIF and TR
         
         L0(:,i+1) = WR_avg';
         L(:,i+1) = TGT_avg';
         
                  
         
         % compile provenance_spectrum_ids: get target id by using
         % TGT_indices logical vector
         provenance_spectrum_ids.add(java.lang.Integer(ids.get(find(TGT_indices, 1) - 1)));
   
     end
     
     wvl = space.getAverageWavelengths();
     [outF_SpecFit, outR_SpecFit, SIF_R_max, SIF_R_wl,     ...
    SIF_FR_max, SIF_FR_wl, SIFint,  outF_SFM, outR_SFM] =  FLOX_SpecFit_master(wvl,L0,L);
end
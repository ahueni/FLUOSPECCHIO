function [R, provenance_spectrum_ids] = processFLAME(user_data, ids, space, spectra, filenames)
 % select groups of 3 and loop over data
     group_no = ids.size / 3;
     no_of_bands = space.getDimensionality.intValue; % use explicit conversion as for some reason a Java Integer cannot be used to create a matrix with 'ones'.
     
     R = ones(no_of_bands, group_no);
     provenance_spectrum_ids = java.util.ArrayList();
     
     
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
         
         
         
         if 1==0
             figure
             plot(space.getAverageWavelengths(), WR_arr, 'b')
             hold
             plot(space.getAverageWavelengths(), WR_avg, 'r')
             plot(space.getAverageWavelengths(), spectra(TGT_indices, :), 'g')
             
             figure
             plot(space.getAverageWavelengths(), TGT_avg, 'b')
             hold
             plot(space.getAverageWavelengths(), WR_avg, 'r')
             if user_data.switch_channels_for_rox == false
                 legend({'TGT', 'WR avg'});
             else
                 legend({'WR', 'TGT avg'});
             end
             
         end
         
         % calculate R
         
         if user_data.switch_channels_for_rox == false
             R(:,i+1) = (TGT_avg ./ WR_avg);
         else
             R(:,i+1) = (WR_avg ./ TGT_avg);
         end
         
         if 1==0
             figure
             plot(space.getAverageWavelengths(), R, 'b')
         end
         
         
         % compile provenance_spectrum_ids: get target id by using
         % TGT_indices logical vector
         provenance_spectrum_ids.add(java.lang.Integer(ids.get(find(TGT_indices, 1) - 1)));
   
     end
end
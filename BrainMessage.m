% This script creates fMRI data with hidden "signal" that can be decomposed
% with ICA to produce components that look like letters.  The letters, of
% course, spell a secret message!  This script requires spm to read and
% write data.  If you use another package, change these functions.

% message: the word or letters you want spelled in the brain
%          since we will put one letter / slice, the max length is the
%          number of slices in the functional data
% outname: the name for the output nifti file.

function dummy = BrainMessage(message,outname)

    template_hdr = spm_vol('mr/fMRI.nii');
    template_img = spm_read_vols(template_hdr);

    % Read in letters templates
    load('data/BrainLetters.mat');
    letters_dim = size(letters(:,:,1));
    
    % Read in timecourse templates
    load('data/timecourses.mat');
    
    % Calculate the padding
    diff_x = size(template_img,2) - letters_dim(2); diff_x = floor(diff_x / 2);
    diff_y = size(template_img,1) - letters_dim(1); diff_y = floor(diff_y / 2);
    padded_letters = cell(length(letters),1);
    
    % Pad the letters to be (approximately) the same size as the slices
    % This serves to center the letter, dimensions don't need to be exact
    for p=1:size(letters,3)
        padded_letters{p} = padarray(letters(:,:,p),[ diff_y diff_x ]);
    end    
    
    % Check that letters in message is not > 46.  This is arbitrary because
    % I've provided 46 "real" fMRI timecourses.  Feel free to create more,
    % or edit the script to generate them on the fly.  I wanted the ICA to
    % be as real as possible, so I chose not to generate.
    if length(message) > 46
       error('Please limit your message to 46 characters!'); 
    end
    
    % Pick components to tweak
    comps = [ 1:size(template_img,4) ]; comps = randsample(comps,length(message));
    
    % Convert all letters to uppercase
    message = upper(message);
    
    % remove symbols we do not have
    message(regexp(message,'[^A-Z0-9]'))=[]
    
    % Create data matrix to hold data we are mixing
    matrix = zeros(size(timecourses,1),size(template_img,1)*size(template_img,2)*size(template_img,3));
    
    fprintf('%s\n','Adding custom signal to data...');
    % Each letter will be used as a mask to apply a timecourse to a set of
    % voxels in one (central) brain slice.  We will then multiply the timecourse by 
    % this spatial map, and add to our mixed matrix.  The completed mixed matrix
    % will be written to file as a nifti image, for input into ICA!
    for s=1:length(message)
        current_letter = message(s);
        
        % Look up current letter in index
        letter_index = lookup(current_letter);
        lettermr = padded_letters{letter_index};
        
        % Select a component to tweak, and its associated timecourse
        current_comp = comps(s);
        current_ts = timecourses(:,current_comp);
        
        % Create a mask
        original_comp = template_img(:,:,:,current_comp);
        original_mask = (original_comp ~= 0);
        
        % Sort the values in the component to get the highest
        [sorted,indexy] = sort(abs(original_comp(:)),'descend');
        
        % Find the indices of the letter mask
        [lookup_row,lookup_col] = find(lettermr == 1);
       
        % These values will be for the letter - we will fill it with the
        % top 5 percent that are in the component map
        top5 = floor(.05*(length(sorted)));
        sig = indexy(1:top5);
        nonsig = indexy(top5+1:end); sorted = sorted(top5+1:end);
        sorted = (sorted ~= 0); nonsig = nonsig(1:length(sorted));
        
        % Create a temporary image to write data to
        temp_img = zeros(size(original_comp));
        
        % Find an approximately middle slice, go a little up/down to make it interesting
        up_down_move = [ 1 2 3 -1 -2 -3 ];
        middle_slice = floor(size(template_img,3) / 2) + randsample(up_down_move,1);

        % For each letter value, fill with randomly selected significant values
        for f=1:length(lookup_row)
            temp_img(lookup_row(f),lookup_col(f),middle_slice) = original_comp(sig(ceil(rand(1)*length(sig))));
        end
        
        % For outside of letter mask, fill with other lower values
        % This is where most of processing time is, and could be sped up :)
        nonsig_mask = temp_img; nonsig_mask(nonsig_mask ~= 0) = 1;
        nonsig_index = ((original_mask + nonsig_mask) == 1);
        nonsig_voxels = find(nonsig_index == 1);
        for f=1:length(nonsig_voxels)
            temp_img(nonsig_voxels) = original_comp(nonsig(f));
        end
        
        % Now we have an "edited" component image, and we multiply it by 
        % the timecourse, and save it to our mixed data matrix
        matrix = matrix + current_ts*temp_img(:)';
        
    end
    
    fprintf('%s\n','Adding real component signal...');
    % Now that we've finished with our "custom" components, we will add the 
    % original components that we didn't use
    comps_notused = setdiff([ 1:size(template_img,4) ],comps);
    for i=1:length(comps_notused)
       current_comp = comps_notused(i);
       current_ts = timecourses(:,current_comp); 
       original_comp = template_img(:,:,:,current_comp);
       matrix = matrix + current_ts*original_comp(:)'; 
    end
    
    fprintf('%s\n','Writing image to file...');
    % Edit header data and write to file
    new_header = template_hdr;
    
    for t=1:size(matrix,1)
       new_header(t) = template_hdr(1);
       new_header(t).fname = outname;
       new_header(t).n = [t 1];
       new_header(t).private.descrip = 'BrainMessage v 1.0';
       new_header(t).descrip = 'BrainMessage v 1.0';
       dummy = spm_write_vol(new_header(t),reshape(matrix(t,:),[size(template_img,1) size(template_img,2) size(template_img,3)]));
    end
   
end

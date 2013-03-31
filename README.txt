BRAIN MESSAGE v1.0

What does Brain Message do?

It takes as input a specified message, and an output file name, and outputs a nifti file for use with independent component analysis:

    dummy = BrainMessage('message','output.nii');

You will want to create the image using the command above, and then run ICA.  You can use the GIFT toolbox in Matlab, or FSL's MELODIC.  The script uses SPM to read and write images, and feel free to change these two calls if you use different software.

 
How does it work?

I basically start with a set of real component timecourses and spatial map distributions, and modify the spatial maps to take the shape of letter templates. The algorithm solves for the matrix W in the equation S = W X, where S is the observed signal, W is some matrix of weights, and X is the unmixed signal. Applied to fMRI, our matrix of weights consists of columns of timecourses, and the unmixed signal has rows of component spatial maps. I therefore went about this backwards, and multiplied rows of timecourses with edited spatial maps to come up with the observed data, S. In other words, for each letter, we multiply a column of Nx1 timepoints by a squished spatial map (a row of 1xV voxels) to result in a matrix of size NxV. I then decided to add in some real functional network spatial maps to make the data more realistic.
Where do the templates come from?

These three sets of templates come zipped up with the script, and there are 46 of them, meaning that you are limited to creating messages 46 characters long. Why did I choose to do this? I wanted this data to be as "real" as possible as opposed to the other option of generating random timecourses and distributions. You could easily edit the script to make everything faux and remove this limit. Secondly, I wanted uncovering the letters to not be consistently easy. By using real data I would be sampling from components with varying strength, and so a resulting spatial map can come out weaker by chance, making seeing it more challenging.

What can I change?

You can easily modify the script to generate fake timecourses, and not limit to messages of 46 characters. You can also create new templates (smiley faces, custom logos), or improve the code however you see fit. Have fun!


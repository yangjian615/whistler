function export_theta( Theta, fileName )
%EXPORT_THETA(Theta, fileName) exports the neural network parameters, THETA,
%	to FILENAME in a flat text format.  Each layer is divided by a line break.
%
%	Written by: Michael Hutchins

	fid = fopen(fileName,'wt');
	
	for i = 1 : length(Theta)
		
		currentTheta = Theta{i};
		
		for j = 1 : size(currentTheta,1);
		
			fprintf(fid,'%g\t',currentTheta(j,:));
			fprintf(fid,'\n');
		end
		
		fprintf(fid,'\n');
		
	end

end


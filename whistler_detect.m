%% Whistler_detect.m searches for whistlers in the given wideband file
%
%	Written by: Michael Hutchins

%% Go to directory

	try
		cd('whistler');
	end
	
%% Import data

	% Whistler is a nose-whistler!
	% Dispersion is about 170
	[time, eField, Fs] = wideband_import('WB20130223140900.dat');

	% Dispersion is about 170
	[time, eField, Fs] = wideband_import('WB20130223141800.dat');
%% Get spectral power density

	[timeBase,freqBase,power] = wideband_fft(eField,Fs);

	
%% Get noise floor

	loc = freqBase < 5600 & freqBase > 3500;
	
	freqWindow = freqBase(loc);
	powerWindow = power(loc,:);
	
	noise = prctile(powerWindow(:),95);
	
%% Create binary image

	powerBinary = powerWindow > noise;
	
%% Find starting points

	startPoints = sum(powerBinary(end - 1 : end,:)) == 2;
	startPoints = startPoints & ~circshift(startPoints,[0,1]);
	
	startIndex = find(startPoints);
	
%% Check shape starting at each start point

	whistlers = {};
	index = 1;
	
	for i = 1 : length(startIndex)
		
		startPoint = [size(powerBinary,1),startIndex(i)];
		
		if i > 1
			if shape(startPoint(1),startPoint(2))
				continue
			end
		end
		
		shape = shape_extract(powerBinary,startPoint);
		
		% Check for whistler shape
		
		% Cut small shapes
		if sum(shape(:)) < 30
			continue
		end
		
		topRow = timeBase(sum(shape(end - 4 : end,:),1) > 0);
		bottomRow = timeBase(sum(shape(1:4,:),1) > 0);

		if isempty(topRow) || isempty(bottomRow)
			continue
		end
		
		% Cut shapes where the start is not far from the end
		if mean(bottomRow) < mean(topRow) + 0.1;
			continue
		end
		
		whistlers{index,1} = shape;
		whistlers{index,2} = startIndex(i);
		index = index + 1;
		
	end
	
%% Get dispersion and start time

	% Pick whistler number
	whistlerNumber = 1;

	% Set window for dispersion window size
	freqCut = [50,200];
	timeCut = [whistlers{whistlerNumber,2} - 20,...
			   whistlers{whistlerNumber,2} + 120];

	% Cut and pad with minimum power
	padSize = 0;
	
	spectra = power;
	spectra = spectra(freqCut(1) : freqCut(2), timeCut(1) : timeCut(2));
	
	spectraZero = zeros(size(spectra,1),padSize) + min(spectra(:));
	spectra = [spectraZero, spectra, spectraZero];
	
	% Remove sferics
	
	sferic = sum(spectra([end-10:end],:),1) >= -200;
	
	spectra(:,sferic) = min(spectra(:));	
	
	% Calculate dispersion
	
	freqChirp = freqBase(freqCut(1) : freqCut(2));
	timeChirp = timeBase(timeCut(1) - padSize : timeCut(2) + padSize);
	
	[dispersion, arrivalTime,dechirp] = ...
		dispersion_check(spectra, freqChirp, timeChirp);

%% Plot dechirped spectra

	%dechirp = de_chirp(spectra,170,timeChirp,freqChirp);

	imagesc(timeChirp,freqChirp,circshift(dechirp,[0,100]))
	title(dispersion)
	xlabel('Time')
	ylabel('Frequency')
	set(gca,'Ydir','Normal')
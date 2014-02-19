function ceps = mfcc(input, samplingRate, PREPROCESS)

% ceps = mfcc(input, samplingRate)
%
% Find the Mel frequency cepstral coefficients (ceps) corresponding to an 
% input speech signal.  Also calculates the first and second derivatives.
%
% INPUTS: 
%
% input: Matrix of speech frames. Each column represents a frame of speech.
% samplingrate: Sampling Frequency in Hz.
% PREPROCESS: Flag to apply pre-emphasis and windowing on speech frames.
%             1 = YES, 0 = NO.
% 
% OUTPUTS:
%
% ceps: Matrix of 13 MFCC, 13 delta MFCC, and 13 delta-delta MFCC 
%       coefficents.  Each feature vector in a column.  
%
% Derived from the original function 'mfcc.m' in the Auditory Toolbox
% written by: 
%
% Malcolm Slaney
% Interval Research Corporation
% malcolm@interval.com
% http://cobweb.ecn.purdue.edu/~malcolm/interval/1998-010/
%
% Also uses the 'deltacoeff.m' function written by:
%
% Olutope Foluso Omogbenigun
% London Metropolitan University
% http://www.mathworks.com/matlabcentral/fileexchange/19298

% Get framesize and number of frames
[windowSize,frames] = size(input);

%	Filter bank parameters
lowestFrequency = 133.3333;
linearFilters = 13;
linearSpacing = 66.66666666;
logFilters = 27;
logSpacing = 1.0711703;
fftSize = 512;
cepstralCoefficients = 13;

% Keep this around for later....
totalFilters = linearFilters + logFilters;

% Now figure the band edges.  Interesting frequencies are spaced
% by linearSpacing for a while, then go logarithmic.  First figure
% all the interesting frequencies.  Lower, center, and upper band
% edges are all consequtive interesting frequencies. 

freqs = lowestFrequency + (0:linearFilters-1)*linearSpacing;
freqs(linearFilters+1:totalFilters+2) = ...
		      freqs(linearFilters) * logSpacing.^(1:logFilters+2);

lower = freqs(1:totalFilters);
center = freqs(2:totalFilters+1);
upper = freqs(3:totalFilters+2);

% We now want to combine FFT bins so that each filter has unit
% weight, assuming a triangular weighting function.  First figure
% out the height of the triangle, then we can figure out each 
% frequencies contribution
mfccFilterWeights = zeros(totalFilters,fftSize);
triangleHeight = 2./(upper-lower);
fftFreqs = (0:fftSize-1)/fftSize*samplingRate;

for chan=1:totalFilters
	mfccFilterWeights(chan,:) = ...
  (fftFreqs > lower(chan) & fftFreqs <= center(chan)).* ...
   triangleHeight(chan).*(fftFreqs-lower(chan))/(center(chan)-lower(chan)) + ...
  (fftFreqs > center(chan) & fftFreqs < upper(chan)).* ...
   triangleHeight(chan).*(upper(chan)-fftFreqs)/(upper(chan)-center(chan));
end

hamWindow = 0.54 - 0.46*cos(2*pi*(0:windowSize-1)/windowSize);

% Figure out Discrete Cosine Transform.  We want a matrix
% dct(i,j) which is totalFilters x cepstralCoefficients in size.
% The i,j component is given by 
%                cos( i * (j+0.5)/totalFilters pi )
% where we have assumed that i and j start at 0.
mfccDCTMatrix = 1/sqrt(totalFilters/2)*cos((0:(cepstralCoefficients-1))' * ...
				(2*(0:(totalFilters-1))+1) * pi/2/totalFilters);
mfccDCTMatrix(1,:) = mfccDCTMatrix(1,:) * sqrt(2)/2;

% Filter the input with the preemphasis filter and window.  
if PREPROCESS
	preEmphasized = filter([1 -.97], 1, input);
    preEmphasized = preEmphasized.*repmat(hamWindow(:),1,frames);
else
	preEmphasized = input;
end

% Ok, now let's do the processing.  For each chunk of data:
%    * Find the magnitude of the fft,
%    * Convert the fft data into filter bank outputs,
%    * Find the log base 10,
%    * Find the cosine transform to reduce dimensionality.
%    * Perform cepstral mean subtraction 

fftMag = abs(fft(preEmphasized,fftSize));
earMag = log10(mfccFilterWeights * fftMag);
ceps = mfccDCTMatrix * earMag;
meanceps = mean(ceps,2);
ceps = ceps - repmat(meanceps,1,frames);

%Call the deltacoeff function to compute derivatives of MFCC
%coefficients 
d = (deltacoeff(ceps')).*0.6;     %Computes delta-mfcc
d1 = (deltacoeff(d)).*0.4;        %as above for delta-delta-mfcc
ceps = [ceps; d'; d1'];           %concatenates all together

function diff = deltacoeff(x)
%Author:        Olutope Foluso Omogbenigun
%Email:         olutopeomogbenigun at hotmail.com
%University:    London Metropolitan University
%Date:          12/07/07
%Syntax:        diff = deltacoeff(Matrix);
%Calculates the time derivative of  the MFCC
%coefficients matrix x and returns the result as a new matrix. 

[nr,nc] = size(x);

K = 3;          %Number of frame span(backward and forward span equal)
b = K:-1:-K;    %Vector of filter coefficients

%pads cepstral  coefficients matrix by repeating first and last rows K times
px = [repmat(x(1,:),K,1);x;repmat(x(end,:),K,1)];

diff = filter(b, 1, px, [], 1);  % filter data vector along each column
diff = diff/sum(b.^2);           %Divide by sum of square of all span values
% Trim off upper and lower K rows to make input and output matrix equal
diff = diff(K + [1:nr],:);



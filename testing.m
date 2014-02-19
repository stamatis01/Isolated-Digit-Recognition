function  testing( data ,Fs)
% This accepts input training speech for each digit and its sampling 
%frequency, and estimates a Gaussian Mixture Model from the training 
%vectors for each digit.

%For each detected word, this function then ...
%
% 1) Windows each frame of speech with a Hamming window
% 2) Applys a pre-emphasis filter to each frame
% 3) Calculates 13 MFCC, 13 delta MFCC, and 13 delta-delta MFCC 
%    coefficients for each frame
% 4) Estimates an 8 mixture Gaussian Mixture Model for the 13 dimensional
%    training vectors (with diagonal covariance matrix).
% 5) The GMM parameters for each digit are saved to a structure called
%    'model' within a file called 'MODELS.mat'.  This .mat file is loaded
%    from within 'digitrecgui.m' to perform the classification.


% Calculate MFCC coefficients from overlapped speech frames
mfccdata = mfcc(data,Fs,1);

% Calculate a GMM fit for the training data and save to MODELS
load MODELS;
handles.models = models;


% Calculate negative log-likelihood from posterior 
% probabilities to determine the spoken digit (with 
% maximum likelihood)
nll = zeros(10,1);
            for nll_idx = 1:10
                
                 [junk,nll(nll_idx)] = posterior(handles.models(nll_idx).gmm,mfccdata');
            end
[nll_VAL,nll_IDX] = min(nll);

digit = whichdigit(nll_IDX);  %whichdigit just returns a string that veryfies
                              % the classification
disp(digit);
end

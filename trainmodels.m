function  trainmodels(speech,model)
% This accepts input training speech for each digit, and estimates a
% Gaussian Mixture Model from the training vectors for each digit.
%
% Accepts input speech of repeated utterances of a single digit.  Input
% speech must be sampled at 8000 Hz.  For each frame of 160 samples (with 
% 80 sample overlap) this function then detects isolated digit utterances 
% using the algorithm described in 'speechdetect.m'.  For each detected
% word, this function then ...
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

Fs = 8000;                          % Sampling Frequency
seglength = 160;                    % Length of frames
overlap = seglength/2;              % # of samples to overlap
stepsize = seglength - overlap;     % Frame stepsize
nframes = length(speech)/stepsize-1;
std_energy = 0.5;           % Energy STD gain factor for Voice Activity (VA)
std_zxings = 0.5;           % Zero xing STD gain factor for VA
noiseframes = 50;           % # of frames used to estimate background noise
bufferlength = 10;          % Min # of non-VA frames to signify a break in 
                            % speech (silence between words)

% Initialise Variables
samp1 = 1; samp2 = seglength;           %Initialise frame start and end
energy_thresh_buf = zeros(noiseframes,1);
zxings_thresh_buf = zeros(noiseframes,1);
VAbuff = zeros(bufferlength,1);

VA = 0;             % "Voice Activity" flag
DETECT = 0;         % "VA indicator" flag
WORD = 0;           % "Word has been detected" flag
WORDbuff = zeros(seglength,200);
ALLdata = [];


for i = 1:nframes
    % Remove mean from analysis frame
    frame = speech(samp1:samp2)-mean(speech(samp1:samp2));

    % Calculate energy and zero xings in current frame
    % These are used as voice activity indicators
    frame_energy = log(sum(frame.*frame)+eps);
    frame_zxings = zerocross;
    
    % Simple estimation of low energy threshold and zero crossings 
    % threshold. (Assumes no speech activity for the first 'noiseframes' 
    % overlapped frames)
    if i < noiseframes
        energy_thresh_buf(i) = frame_energy;
        zxings_thresh_buf(i) = frame_zxings;
    elseif i == noiseframes
        energy_thresh = mean(energy_thresh_buf) + ...
            std_energy*std(energy_thresh_buf);
        
        % Requires a minimum threshold of 25 zero crossings
        xing_thresh = max(mean(zxings_thresh_buf) + ...
            std_zxings*std(zxings_thresh_buf),25);
    else

        % Initial indicator of Voice Activity
        if frame_energy >= energy_thresh || frame_zxings >= xing_thresh
            DETECT = 1;
        else
            DETECT = 0;
        end
        
        % Now need to decide if we really do have voice activity based on
        % the length of time that "DETECT" == 1.   
        if VA   % We may have voice activity
            
            VAframes = VAframes + 1;        % Increment VAframe counter
            WORDbuff(:,VAframes) = frame;   % Save in buffer
            
            % Circular shift buffer and save current frame indicator
            VAbuff = circshift(VAbuff,1); 
            if DETECT 
                VAbuff(1) = 1;
            else
                VAbuff(1) = 0; 
            end
                       
            % Look at buffer of frames where DETECT = 1
            if VAbuff(1) 
                % Reset buffer 
                VAbuff = [1; zeros(bufferlength-1,1)];
            elseif VAbuff(end)
                % There was no voice activity for duration of buffer.  Turn
                % off VA flag and calculate number of contiguous frames 
                % with voice activity.     
                VA = 0;
                VAframes = VAframes - bufferlength - 1;
                % Disregard any contiguous frames less than 0.25s
                if VAframes > 25; 
                    WORD = 1;
                    WORDdata = WORDbuff(:,1:VAframes);
                    WORDbuff = zeros(seglength,200); 
                else
                    WORD = 0;
                    WORDbuff = zeros(seglength,200);
                end
            end                                         
        
        else    % No voice detected yet
            
            % Do indicators suggest VA?
            if DETECT
                VA = 1;                 % Set flag to say we may have VA
                VAframes = 1;           % Re-Initialise VA frame number
                WORDbuff(:,1) = frame;  % Save in buffer
                            
                % Initialise buffer to record the previous frames where
                % DETECT = 1.  This is used to determine contiguous frames
                % of voice or non-voice activity
                VAbuff = [1; zeros(bufferlength-1,1)];
            end            

        end
        
        % Combine all speech frames in one big matrix
        if WORD
            ALLdata = [ALLdata WORDdata];
            WORD = 0;
        end

        
    end

    % Step up to next frame of speech
    samp1 = samp1 + stepsize;
    samp2 = samp2 + stepsize;
    
end
    %Nested function for zero crossing calculation
    function numcross = zerocross
        currsum = 0;
        prevsign = 0;

        for kk = 1:seglength
            currsign = sign(frame(kk));
            if (currsign * prevsign) == -1
                currsum = currsum + 1;
            end
            if currsign ~= 0
                prevsign = currsign;
            end
        end

        numcross = currsum;

    end

% Calculate MFCC coefficients from overlapped speech frames
mfccdata = mfcc(ALLdata,Fs,1);

% Calculate a GMM fit for the training data and save to MODELS
if exist('MODELS.mat','file')
    load MODELS
end

modelidx = getmodelidx;
models(modelidx).word = model;
options = statset('MaxIter',500,'Display','final');
disp(['Starting GMM Training for: ' model]);
models(modelidx).gmm = gmdistribution.fit(mfccdata',8,'CovType',...
    'diagonal','Options',options);
save MODELS models

    % Nested function to get index for model structure
    function idx = getmodelidx
        switch model
            case 'one', idx = 1;
            case 'two', idx = 2;
            case 'three', idx = 3;
            case 'four', idx = 4;
            case 'five', idx = 5;
            case 'six', idx = 6;
            case 'seven', idx = 7;
            case 'eight', idx = 8;
            case 'nine', idx = 9;
            case 'zero', idx = 10;
            otherwise, error('Invalid Word for training');
        end
    end

% Also save training vectors to TRAINDATA (maybe for future use)
%if exist('TRAINDATA.mat','file')
%    load TRAINDATA
%end
%traindata.(model).trainvectors=mfccdata;
%save TRAINDATA traindata

end

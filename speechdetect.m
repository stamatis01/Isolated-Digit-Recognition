function  speechdetect(speech,std_energy,std_zxings)
%
% Utility function to test speech detection algorithm on input speech.
% Returns a plot indicating detected voice activity.  Number of inputs must
% be 1 or 3.
%
% INPUTS: 
%   speech: Input speech utterance
%   std_energy: Energy STD gain factor for VA (default = 0.5)
%   std_zxings: Zero xings STD gain factor for VA (default = 0.5)
%
% Usage: 
% speechdetect(speech)
% speechdetect(speech,std_energy,std_zxings)
%           
% Accepts input speech of repeated utterances of a single digit.  Input
% speech must be sampled at 8000 Hz.  For each frame of 160 samples (with 
% 80 sample overlap) this function then... 
%
% 1) Calculates the energy and number of zero crossings in the frame
% 2) Compares these values with a threshold to determine if we have 
%    possible voice activity and hence a spoken digit.
% 3) If either energy or zero crossings exceeds the threshold, continue
%    analysing frames and start buffering.
% 4) If number of contiguous frames does not exceed "bufferlength", we 
%    have a false alarm.  Continue analysing frames and go back to (1). 
% 5) If number of contiguous frames exceeds "bufferlength", we have
%    detected a word.  Continue buffering and analysing frames.
% 6) Keep analysing frames until we encounter "bufferlength" contiguous
%    frames where neither energy or zero crossing exceeds the threshold.
%    This means we have analysed past the end of the spoken digit.  
% 7) Compare duration of detected digit with threshold (0.25s).  If
%    duration exceeds threhold, mark voice activity.  If duration does not
%    exceed threshold, disregard digit. Continue analysing frames and go 
%    back to (1).

if nargin == 1
    std_energy = 0.5;       % Energy STD gain factor for Voice Activity (VA)
    std_zxings = 0.5;       % Zero xing STD gain factor for VA
end
if nargin == 2
    error('Incorrect number of input arguments');
end

seglength = 160;                    % Length of frames
overlap = seglength/2;              % # of samples to overlap
stepsize = seglength - overlap;     % Frame stepsize
nframes = length(speech)/stepsize-1;

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
outdetect = zeros(size(speech));


for i = 1:nframes
    % Remove mean from analysis frame
    frame = speech(samp1:samp2)-mean(speech(samp1:samp2));

    % Calculate energy and zero xings in current frame
    % These are used as voice activity indicators
    frame_energy = log(sum(frame.*frame)+eps);
    frame_zxings = zerocross;
    
    % Simple estimation of low energy threshold (Assumes no speech activity
    % for the first 'noiseframes' overlapped frames
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
                endframe = i-bufferlength-1;
                VA = 0;
                % Disregard any contiguous frames less than 0.25s
                if (endframe-startframe) > 25; 
                    WORD = 1;
                    outdetect((startframe-1)*stepsize+1:endframe*stepsize) = 1;
                else
                    WORD = 0;
                end
            end                                         
        
        else    % No voice detected yet
            
            % Do indicators suggest VA?
            if DETECT
                VA = 1;             % Set flag to say we may have VA
                startframe = i;     % Record current frame number
                
                % Initialise buffer to record the previous frames where
                % DETECT = 1.  This is used to determine contiguous frames
                % of voice or non-voice activity
                VAbuff = [1; zeros(bufferlength-1,1)];
            end            

        end

        
    end

    
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

    plot(speech); hold on; plot(outdetect,'r'); hold off; axis([0 4e4 -0.5 1.1]);
end

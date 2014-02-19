%-----------------------------Training Script----------------------------
y = wavread('one.wav'); %read the wav file
trainmodels(y,'one');   %train the GMM

%same for the rest training set files.
y = wavread('two.wav');
trainmodels(y,'two');
y = wavread('three.wav');
trainmodels(y,'three');
y = wavread('four.wav');
trainmodels(y,'four');
y = wavread('five.wav');
trainmodels(y,'five');
y = wavread('six.wav');
trainmodels(y,'six');
y = wavread('seven.wav');
trainmodels(y,'seven');
y = wavread('eight.wav');
trainmodels(y,'eight');
y = wavread('nine.wav');
trainmodels(y,'nine');
y = wavread('zero.wav');
trainmodels(y,'zero');

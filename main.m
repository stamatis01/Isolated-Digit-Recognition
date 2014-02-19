%----------------------------------MAIN-----------------------------------
[y,Fs]=wavread('testone.wav'); %read test input
x=testmodels(y);%sets up the speech signal on the right form matching 
                %the GMM training of the earlier steps.
testing(x,Fs);%perform negative log-likelihood check

%Now the same for the rest test inputs.
[y,Fs]=wavread('testtwo.wav');
x=testmodels(y);
testing(x,Fs);
[y,Fs]=wavread('testthree.wav');
x=testmodels(y);
testing(x,Fs);
[y,Fs]=wavread('testfour.wav');
x=testmodels(y);
testing(x,Fs);
[y,Fs]=wavread('testfive.wav');
x=testmodels(y);
testing(x,Fs);
[y,Fs]=wavread('testsix.wav');
x=testmodels(y);
testing(x,Fs);
[y,Fs]=wavread('testseven.wav');
x=testmodels(y);
testing(x,Fs);
[y,Fs]=wavread('testeight.wav');
x=testmodels(y);
testing(x,Fs);
[y,Fs]=wavread('testnine.wav');
x=testmodels(y);
testing(x,Fs);
[y,Fs]=wavread('testzero.wav');
x=testmodels(y);
testing(x,Fs);

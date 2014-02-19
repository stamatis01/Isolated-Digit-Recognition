Isolated-Digit-Recognition
==========================

Isolated Digit Recognition from Recorded Speech Signals

What it does?

It tries to recognise isolated digits from speech signals. It is supposed to recognise 0-9 in english language.

How it works?

Basically you have to extract MFCCs from a speech signal that has repeated sentences of a spoken digit. Then you train a Gaussian Mixture Model for each digit based on the MFCCs extracted. And finally you give it a testing by performing NLOG-likelihood test upon a new test speech signal.

How to find those inputs?

You have to create them by scratch. One way is the use this set of commands to record your own voice and at least perform your voice check!

1) y=wavrecord(30*8000,8000); %speak for 30 sec, repeating the same digit over and over with a short pause between.

2) wavwrite(y,8000,'one.wav'); %if everything goes as planned you should have your first file!

Run the above on MATLAB and make sure you have a microphone on your pc. Good luck!

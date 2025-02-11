function [Days, nEpochs] = days_in_recording(EEGPoints, SampleRate, EpochLength)
% identifies what time in seconds to seperate the EEG into 24 h days, and
% adjusts the scoring string with blanks (or cuts) to make sure it matches
% the provided EEG. WARNING: this will avoid crashing, but could lead to
% incorrect results if the scoring doesn't actually correspond to the EEG.

Day = 60*60*24;
RecordingDuration = EEGPoints/SampleRate;
Epochs = 0:EpochLength:RecordingDuration;
nEpochs = numel(Epochs);

Days = Epochs(dsearchn(Epochs', [0:Day:RecordingDuration+Day]'));

# Sleep across species

## Project description

This project aims to test whether the speed with which an animal falls asleep is determined by cortical size. It is currently in an exploratory stage, so most of the code right now is just to load in data and look at it.


## Data format

For ease of use, this dataset will be saved in 2 formats: EDF + CSV and MAT. The EDFs will be generated at some point whenever someone else needs them. The MAT files will contain:

`EEG`: an EEGLAB structure with fields:
    - `data` a channel x time matrix. This can include EEG, EMG, and accelerometry.
    - `srate`: sample rate of the data
    - `chanlocs`: a structure with fields:
        -  `labels`: a string with the original labels. 
            `type`: either: "EEG", "EMG", "EKG", "ACC" (accelerometer), "TEMP" (temperature)
        - `X`, `Y`, `Z`: coordinates in space, if available.

`ScoringString`: a character string of the different sleep stages. They will be:
    - "w" for wake
    - "r" for REM
    - "n" for NREM
    - "1" for N1
    - "2" for N2
    - "3" for N3
    - "c" for 'chewing', i.e. rumination
    - "a" for active wake

`EpochLength`: a number in seconds of how long the scoring string is

`LightString`: a character string of the light/dark conditions of each epoch. This is not always available or accurate.
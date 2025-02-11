% Runs the code on animal data (from A. Osorio-Forero). This repo does not include the data, you'll need to have your own. Sorry :/

addpath('D:\Code\MyToolboxes\eeg-oscillations')
addpath('D:\Code\ExternalToolboxes\fieldtrip')
ft_defaults
addpath('D:\Code\sleep-sizes\functions\')

%%
clear
close all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% setup

% choose what to do
PlotIndividuals = true;

%%% analysis parameters

% power
WelchWindowLength = 4; % in seconds
WelchOverlap = .5; % 50% of the welch windows will overlap

% fooof
FooofFrequencyRange = [3 40]; % frequencies over which to fit the model
SmoothSpan = 3;
MaxError = .15;
MinRSquared = .95;
Refresh = false;

% plot parameters
ScatterSizeScaling = 20;
Alpha = .1;

% locations
DataFolder = 'F:\Animalia\Jackdaws\4SD';
EEGFolder = fullfile(DataFolder, 'MAT');
ResultsFolder = fullfile(DataFolder, 'Results');
ScoringFolder = fullfile(DataFolder, 'Scoring');
if ~exist(ResultsFolder, 'dir')
    mkdir(ResultsFolder)
end

% stages
OldEpochLength = 4;
NewEpochLength = 16; % Can be as low as 4, or as high as you want. Should be multiple of 4.
SampleRate = 250;
channel_indices = 11:42;

% time to keep
% TimeToKeep = [0.0001 60*60*1]; % in seconds

if ~exist(EEGFolder, 'dir')
    mkdir(EEGFolder)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run
%%
Files = oscip.list_filenames(DataFolder);

%%% Cut data into days to speed up processing
for FileIdx = 8 %1:numel(Files)
    A = tic;

    File = Files(FileIdx);
    FilenameCore = extractBefore(File, '.edf');
    FileEEG1 = [FilenameCore{1}, '_Day1.mat'];
    [ScoringString, ScoringTable, LightString] = load_sjoerd_scoring(ScoringFolder, FilenameCore);


    if exist(fullfile(EEGFolder, FileEEG1), 'file') && ~Refresh
        disp(['Already did ', FileEEG1])
        continue
    else
        disp(['loading ', FilenameCore])
        [data, event] = load_edf(fullfile(DataFolder, File), SampleRate, channel_indices);
        EEG = format_eeglab(data);

         chop_and_save_recording_by_days(EEG, ScoringString, LightString, ...
           OldEpochLength, EEGFolder, FilenameCore{1})
    end
    clc
    disp(['it took ', num2str(round(toc(A)/60)), ' minutes to do ', FilenameCore])
end


%%% Run analysis

%%
Files = oscip.list_filenames(EEGFolder);

for FileIdx = 19:numel(Files)

    File = Files{FileIdx};

    if exist(fullfile(ResultsFolder, File), 'file') & ~Refresh
        load(fullfile(ResultsFolder, File), 'Scoring', 'ScoringIndexes', 'ScoringLabels', ...
            'SmoothPower', 'Frequencies', 'Slopes', 'Intercepts', ...
            'FooofFrequencies', 'PeriodicPeaks', 'WhitenedPower', 'Errors','RSquared', 'ScoringTable')
    else

        load(fullfile(EEGFolder, File), 'EEG', 'ScoringStringCut', 'ScoringTable')
        Data = EEG.data;

        % calculate power
        [EpochPower, Frequencies] = oscip.compute_power_on_epochs(Data, ...
            SampleRate, NewEpochLength, WelchWindowLength, WelchOverlap);

        % select most common score for each epoch (when new epoch is larger
        % than old)
        [Scoring, ScoringIndexes, ScoringLabels] = oscip.convert_animal_scoring(ScoringStringCut, size(EpochPower, 2), NewEpochLength, OldEpochLength);

        SmoothPower = oscip.smooth_spectrum(EpochPower, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth

        % run FOOOF
        [Slopes, Intercepts, FooofFrequencies, PeriodicPeaks, WhitenedPower, Errors, RSquared] ...
            = oscip.fit_fooof_multidimentional(SmoothPower, Frequencies, FooofFrequencyRange, MaxError, MinRSquared);

        save(fullfile(ResultsFolder, File), 'Scoring', 'ScoringIndexes', 'ScoringLabels', ...
            'SmoothPower', 'Frequencies', 'Slopes', 'Intercepts', ...
            'FooofFrequencies', 'PeriodicPeaks', 'WhitenedPower', 'Errors','RSquared', 'ScoringTable')
    end

    % plot
    close all


    for ChIdx =  [1, 3, 14, 21, 25 31] %1:size(Data, 1)

        Title = [replace(replace(File, '.mat', ''), '_', ' '), '; ch ', num2str(ChIdx)];
        oscip.plot.temporal_overview(squeeze(WhitenedPower(ChIdx, :, :)), ...
            FooofFrequencies, NewEpochLength, Scoring, ScoringIndexes, ScoringLabels, Slopes(ChIdx, :), [], [], Title)
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(ResultsFolder, [Title, '_time']), '-dtiff', '-r1000')


        oscip.plot.frequency_overview(SmoothPower(ChIdx, :, :), Frequencies, PeriodicPeaks(ChIdx,:, :), ...
            Scoring, ScoringIndexes, ScoringLabels, ScatterSizeScaling, Alpha, true, true)
        xlim(FooofFrequencyRange)
        % ylim([1 6])
        title(Title)
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(ResultsFolder, [Title, '_frequency']), '-dtiff', '-r1000')

        figure('Units','normalized','Position',[  0.3536    0.6733    0.2156    0.1575])
        oscip.plot.histogram_stages(Slopes(ChIdx, :), Scoring, ScoringLabels, ScoringIndexes);
        title(Title)
        print(fullfile(ResultsFolder, [Title, '_slopes']), '-dtiff', '-r1000')

    end
end


% Runs the code on animal data (from A. Osorio-Forero). This repo does not include the data, you'll need to have your own. Sorry :/
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
Alpha = .5;

% locations
DataFolder = 'F:\Animalia\Geese\Raw Data';
EEGFolder = fullfile(DataFolder, 'MAT');
ScoringFolder = 'F:\Animalia\Geese\Processed Data\Autoscored files';
ResultsFolder = fullfile(DataFolder, 'Results');
if ~exist(ResultsFolder, 'dir')
    mkdir(ResultsFolder)
end

% stages
OldEpochLength = 4;
NewEpochLength = 8; % Can be as low as 4, or as high as you want. Should be multiple of 4.
SampleRate = 100;
channel_indices = [4 5];

% time to keep
% TimeToKeep = [0.0001 60*60*1]; % in seconds

if ~exist(EEGFolder, 'dir')
    mkdir(EEGFolder)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run

Files = oscip.list_filenames(DataFolder);

%%% Cut data into days to speed up processing
for FileIdx = 2:numel(Files)

    File = Files(FileIdx);
    FilenameCore = extractBefore(File, '.edf');
    FileEEG1 = [FilenameCore{1}, '_Day1.mat'];

     [ScoringString, ScoringTable] = load_sjoerd_scoring(ScoringFolder, FilenameCore);

    if exist(fullfile(EEGFolder, FileEEG1), 'file') && ~Refresh
        continue
    else
        disp(['loading ', FilenameCore{1}])
        [data, event] = load_edf(fullfile(DataFolder, File), SampleRate, channel_indices);
        EEGWhole = format_eeglab(data);

        % figure out where the breaks are for
        [Days, ScoringString] = calculate_days_from_sjoerd_scoring(ScoringString, ...
            size(EEGWhole.data, 2), EEGWhole.srate, OldEpochLength);

        Idx = 1;
        for DayIdx = 1:numel(Days)-1
            Start = Days(DayIdx);
            End = Days(DayIdx+1);

            if End > size(EEGWhole.data,2)
                End = size(EEGWhole.data,2);
            end

            EEG = pop_select(EEGWhole, 'time', [Start, End]);
            save(fullfile(EEGFolder, [FilenameCore{1}, '_Day', num2str(Idx), '.mat']), 'EEG', 'ScoringString', 'ScoringTable', '-v7.3')
            Idx = Idx+1;
        end
    end
end


%%% Run analysis

%%
Files = oscip.list_filenames(EEGFolder);
Files(~contains(Files,'Day2')) = [];

for FileIdx =  1:numel(Files)

    File = Files{FileIdx};

    if exist(fullfile(ResultsFolder, File), 'file') & ~Refresh
        disp(['Loading already calculated ', File])
        load(fullfile(ResultsFolder, File), 'Scoring', 'ScoringIndexes', 'ScoringLabels', ...
            'SmoothPower', 'Frequencies', 'Slopes', 'Intercepts', ...
            'FooofFrequencies', 'PeriodicPeaks', 'WhitenedPower', 'Errors','RSquared')
    else
        disp(['Loading ', File])
        load(fullfile(EEGFolder, File), 'EEG', 'ScoringString')
        Data = EEG.data;

        % calculate power
        [EpochPower, Frequencies] = oscip.compute_power_on_epochs(Data, ...
            SampleRate, NewEpochLength, WelchWindowLength, WelchOverlap);

        % select most common score for each epoch (when new epoch is larger
        % than old)
        [Scoring, ScoringIndexes, ScoringLabels] = oscip.convert_animal_scoring(ScoringString, size(EpochPower, 2), NewEpochLength, OldEpochLength);



        SmoothPower = oscip.smooth_spectrum(EpochPower, Frequencies, SmoothSpan); % better for fooof if the spectra are smooth

        % run FOOOF
        [Slopes, Intercepts, FooofFrequencies, PeriodicPeaks, WhitenedPower, Errors, RSquared] ...
            = oscip.fit_fooof_multidimentional(SmoothPower, Frequencies, FooofFrequencyRange, MaxError, MinRSquared);

        save(fullfile(ResultsFolder, File), 'Scoring', 'ScoringIndexes', 'ScoringLabels', ...
            'SmoothPower', 'Frequencies', 'Slopes', 'Intercepts', ...
            'FooofFrequencies', 'PeriodicPeaks', 'WhitenedPower', 'Errors','RSquared')
    end

    % plot
    close all
    for ChIdx = 1:size(Slopes, 1)

        Title = [replace(replace(File, '.mat', ''), '_', ' '), '; ch ', num2str(ChIdx)];
        oscip.plot.temporal_overview(squeeze(WhitenedPower(ChIdx, :, :)), ...
            FooofFrequencies, NewEpochLength, Scoring, ScoringIndexes, ScoringLabels, Slopes(ChIdx, :), [], [], Title)
        set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        print(fullfile(ResultsFolder, [Title, '_time']), '-dtiff', '-r1000')

        % oscip.plot.frequency_overview(SmoothPower, Frequencies, PeriodicPeaks, ...
        %     Scoring, ScoringIndexes, ScoringLabels, ScatterSizeScaling, Alpha, true, true)
        % xlim([5 20])
        % ylim([1 6])
        % title(Title)
        % set(gcf, 'InvertHardcopy', 'off', 'Color', 'w')
        % print(fullfile(Destination, [FigureTitle, '_frequency']), '-dtiff', '-r1000')
    end
end


function [ScoringString, ScoringTable, LightString] = load_sjoerd_scoring(ScoringFolder, FilenameCore)
% loads in scoring based on how Sjoerd van Hasselt saves his EEG and
% scoring names.

FilenameParts = split(FilenameCore, '_');
BirdID = FilenameParts{end};
Date = FilenameParts{3};
Day = Date(1:2);
Month = Date(3:4);

if contains(ScoringFolder, 'Jackdaws')
    Wake ='Wake';
    NREM = 'SWS';
    REM = 'REM';

    ScoringCol = 'Var1';
    if contains(ScoringFolder, '8SD')
        SD = '8SD';
    elseif contains(ScoringFolder, '4SD')
        SD = '4SD';
    end
    ScoringFilename = strjoin({'Asleep', BirdID, [SD, '.txt']}, '_');

elseif contains(ScoringFolder, 'Geese')
    Wake ='Wake';
    NREM = 'NREM';
    REM = 'REM';
    ScoringCol = 'Score';
    ScoringFilename = strjoin({'goose', num2str(str2double(BirdID)), [Day, '-', Month], 'autoscore.txt'}, ' ');
else
    error('no animal path found')
end

ScoringPath = fullfile(ScoringFolder, ScoringFilename);


if exist(ScoringPath, 'file')
    ScoringTable = readtable(ScoringPath);
    if contains(ScoringFolder, 'Jackdaws')
        ScoringCell = ScoringTable{:, 1};
        LightString = '';
    else
        ScoringCell = ScoringTable.(ScoringCol);
        LDCell = ScoringTable.Light_DarkPhase;
        LDCell(strcmp(LDCell, 'Light')) = {'l'};
        LDCell(strcmp(LDCell, 'Dark')) = {'d'};
        LightString = char(LDCell)';
    end

    ScoringCell(strcmp(ScoringCell, Wake)) = {'w'};
    ScoringCell(strcmp(ScoringCell, NREM)) = {'n'};
    ScoringCell(strcmp(ScoringCell, REM)) = {'r'};
    ScoringString = char(ScoringCell)';
else
    warning(['No scoring found for ' FilenameCore{1}])
    ScoringString = '';
    ScoringTable = table();
    LightString = '';
end
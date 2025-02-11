function NewString = adjust_scoring_string(OldString, nEpochs, Default)
arguments
    OldString
    nEpochs
    Default = 'w';
end

if isempty(OldString)
    NewString = repmat(Default, 1, nEpochs);
else
    if nEpochs<numel(OldString)
        warning(['Scoring longer than file by ', num2str(100*(numel(OldString)-nEpochs)/nEpochs), '%'])
        NewString = OldString(1:nEpochs);
    elseif nEpochs>numel(OldString)
        warning(['File longer than scoring by ', num2str(100*(nEpochs-numel(OldString))/nEpochs), '%'])
        NewString = repmat('?', 1, nEpochs);
        NewString(1:numel(OldString)) = OldString;
    end
end
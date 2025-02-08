function [data, event] = load_edf(filename, SampleRate, channel_indices)
%%% my adaptation of EDF2FIELDTRIP which doesn't use the highest sample
%%% rate but rather the requested sample rate

% EDF2FIELDTRIP reads data from a EDF file with channels that have a different
% sampling rates. It upsamples all data to the highest sampling rate and
% concatenates all channels into a raw data structure that is compatible with the
% output of FT_PREPROCESSING.
%
% Use as
%   data = edf2fieldtrip(filename)
% or
%   [data, event] = edf2fieldtrip(filename)
%
% For reading EDF files in which all channels have the same sampling rate, you can
% use the standard procedure with FT_DEFINETRIAL and FT_PREPROCESSING.
%
% See also FT_PREPROCESSING, FT_DEFINETRIAL, FT_REDEFINETRIAL,
% FT_READ_EVENT

% Copyright (C) 2015-2021, Robert Oostenveld
% Copyright (C) 2022-, Robert Oostenveld and Jan-Mathijs Schoffelen
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

headerformat = 'edf';
dataformat = 'edf';

hdr = ft_read_header(filename, 'headerformat', headerformat);
samplerates = unique(hdr.orig.SampleRate);
samplerates(~ismember(samplerates, SampleRate)) = [];

data = cell(size(samplerates));


for i=1:numel(samplerates)
    chanindx = find(hdr.orig.SampleRate==samplerates(i));
    if exist("channel_indices", "var")
        chanindx = intersect(chanindx, channel_indices);
        if isempty(chanindx)
            continue
        end
    end
    fprintf('reading %d channels with %g Hz sampling rate\n', numel(chanindx), samplerates(i));

    % read the header and data for the selected channels
    hdr = ft_read_header(filename, 'chanindx', chanindx, 'headerformat', headerformat);
    dat = ft_read_data(filename, 'header', hdr, 'headerformat', headerformat, 'dataformat', dataformat);

    % construct a time axis, starting at 0 seconds
    time = ((1:(hdr.nTrials*hdr.nSamples)) - 1)./hdr.Fs;

    % make a raw data structure
    data{i}.hdr   = hdr;
    data{i}.label = hdr.label;
    data{i}.time  = {time}; % only single data segment
    data{i}.trial = {dat};  % only single data segment

end

% [~, maxindex] = max(samplerate);

if any(samplerates==SampleRate)
    Time = data{find(samplerates==SampleRate, 1, 'first')}.time;
else
    [~, maxindex] = max(samplerate);
    MaxT = data{maxindex}.time{1}(end);
    Time = {1/SampleRate:1/SampleRate:MaxT};
    warning('no sample rate matched requested, so generating time vector')
end

% upsample the data to the highest sampling rate
for i=1:numel(samplerates)
    if samplerates(i)==SampleRate
        continue
    elseif isempty(data{i})
        continue
    end
    fprintf('resampling %d channels from %g to %g Hz\n', numel(data{i}.label), samplerates(i), SampleRate);

    cfg = [];
    cfg.time = Time;
    % cfg.resamplefs = SampleRate;
    data{i} = ft_resampledata(cfg, data{i});
    data{i}.hdr.nSamples = size(data{i}, 2);
end

% concatenate them into a single data structure

EmptySampleRates = cellfun(@isempty, data);
data(EmptySampleRates) = [];


cfg = [];
cfg.appenddim = 'chan';
data = ft_appenddata(cfg, data{:});

% reorder the channels to the original order in the EDF file
origlabel     = cellstr(hdr.orig.Label);
[currentorder, origorder] = match_str(origlabel, data.label); % sorted according to the 1st input argument
data.label    = data.label(origorder);
data.trial{1} = data.trial{1}(origorder,:);

% annotate the manual operation in the data structure provenance
cfg = [];
cfg.comment = 'reordered the channels to the original order in the EDF file';
data = ft_annotate(cfg, data);

if isfield(data, 'hdr')
    % remove this, as otherwise it might be very confusing with the subselections
    data = rmfield(data, 'hdr');
end

try
    event = ft_read_event(filename);
    sel   = ~cellfun('isempty',{event.value}');
    event = event(sel(:));
catch
    ft_warning('could not extract events from the data');
    event = [];
end
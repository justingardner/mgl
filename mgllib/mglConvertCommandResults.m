% mglConvertCommandResults: Convert GPU result timestamps to CPU time.
%
%      usage: results = mglConvertCommandResults(results, cpuBefore, gpuBefore, cpuAfter, gpuAfter)
%         by: Benjamin Heasly
%       date: 01/30/2024
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Convert GPU results timestamps to CPU time
%      usage: results = mglConvertCommandResults(results, cpuBefore, gpuBefore, cpuAfter, gpuAfter)
%
% This function aligns GPU timestamps to CPU time, following the
% interpolation strategy discussed in Apple's Metal docs here:
% https://developer.apple.com/documentation/metal/gpu_counters_and_counter_sample_buffers/converting_gpu_timestamps_into_cpu_time
%
% Inputs:
%
%   results:    struct array with command results, as from
%               mglReadCommandResults()
%   cpuBefore:  a CPU timestamp preceeding results, as from
%               mglMetalSampleTimestamps()
%   gpuBefore:  a GPU timestamp preceeding results, as from
%               mglMetalSampleTimestamps()
%   cpuAfter:   a CPU timestamp following results, as from
%               mglMetalSampleTimestamps()
%   gpuAfter:   a GPU timestamp following results, as from
%               mglMetalSampleTimestamps()
%
% Output:
%
%   results:    the same results struct give, with GPU timestamps converted
%               to values comparable to CPU timestamps and mglGetSecs().
%
% Example:
%
% mglOpen()
% [cpuBefore, gpuBefore] = mglMetalSampleTimestamps();
% results = mglFlush()
% [cpuAfter, gpuAfter] = mglMetalSampleTimestamps();
% results2 = mglConvertCommandResults(results, cpuBefore, gpuBefore, cpuAfter, gpuAfter)
function results = mglConvertCommandResults(results, cpuBefore, gpuBefore, cpuAfter, gpuAfter)

% Convert specific timestamps from GPU to CPU time.
% We know which ones to convert because of implementation details,
% not because there's anything special we can tell about them from here.
[results.vertexStart] = num2list(gpu2cpu([results.vertexStart], cpuBefore, gpuBefore, cpuAfter, gpuAfter));
[results.vertexEnd] = num2list(gpu2cpu([results.vertexEnd], cpuBefore, gpuBefore, cpuAfter, gpuAfter));
[results.fragmentStart] = num2list(gpu2cpu([results.fragmentStart], cpuBefore, gpuBefore, cpuAfter, gpuAfter));
[results.fragmentEnd] = num2list(gpu2cpu([results.fragmentEnd], cpuBefore, gpuBefore, cpuAfter, gpuAfter));

function cpu = gpu2cpu(gpu, cpuBefore, gpuBefore, cpuAfter, gpuAfter)
% Leave zeros alone, since these indicate no data.
if all(gpu == 0)
    cpu = gpu;
    return
end

% Express gpu as a fraction of the range [gpuBefore gpuAfter].
gpuRange = gpuAfter - gpuBefore;
gpuFraction = (gpu - gpuBefore) / gpuRange;

% Compute cpu from the same fraction, of the range [cpuBefore, cpuAfter].
cpuRange = cpuAfter - cpuBefore;
cpu = cpuBefore + gpuFraction * cpuRange;

function varargout = num2list(numbers)
varargout = num2cell(numbers);

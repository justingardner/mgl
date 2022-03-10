% mglBltTexture.m
%
%        $Id$
%      usage: [ackTime, processedTime] = mglBltTexture(tex, position, hAlignment, vAlignment, rotation, phase, width, height)
%         by: justin gardner
%       date: 05/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Draw a texture to the screen in desired position.
%             Please see also mglMetalBltTexture().
function [ackTime, processedTime] = mglBltTexture(tex, position, hAlignment, vAlignment, rotation, phase, width, height)

[ackTime, processedTime] = mglMetalBltTexture(tex, position, hAlignment, vAlignment, rotation, phase, width, height);

% eegplugin_eepimport() - EEGLAB plugin for importing ANT EEProbe data files.
%                         With this menu it is possible to import and export a continous CNT file (*.cnt) or 
%                         an averaged file (*.avr), linked with an event file (*.trg).
%
% Usage:
%   >> eegplugin_eepimport(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks. 
%
% Notes:
%   This plugins consist of the following Matlab files:
%   pop_loadeep.m           pop_loadeep_avg.m
%   loadeep.m               loadeep_avg.m
%   read_eep_cnt.m          read_eep_avr.m
%   read_eep_cnt.mexglx     read_eep_avr.mexglx
%   read_eep_cnt.dll        read_eep_avr.dll
%
% Create a plugin:
%   For more information on how to create an EEGLAB plugin see the
%   help message of eegplugin_besa() or visit http://www.sccn.ucsd.edu/eeglab/contrib.html
%
% Author: Maarten-Jan Hoeve, ANT Software, The Netherlands / www.ant-software.nl, 3 October 2003
%
% See also: eeglab(), pop_loadeep(), loadeep(), read_eep_cnt(), pop_loadeep_avg(), loadeep_avg(), read_eep_avg()

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2003 Maarten-Jan Hoeve, ANT Software, The Netherlands, m.hoeve@ieee.org / info@ant-software.nl
%

function vers = eegplugin_eepimport(fig, trystrs, catchstrs)
    
  vers = 'eepimport1.01';
  if nargin < 3
      error('eegplugin_eepimport requires 3 arguments');
  end;
    
  % add folder to path
  % ------------------
  if ~exist('pop_loadeep_avg')
      p = which('eegplugin_eepimport.m');
      p = p(1:findstr(p,'eegplugin_eepimport.m')-1);
      addpath([ p vers ] );
  end;

  % find import data menu
  % ---------------------
  menu = findobj(fig, 'tag', 'import data');
  
  % menu callbacks
  % --------------
  comcnt = [ trystrs.no_check '[EEG LASTCOM] = pop_loadeep;'     catchstrs.new_and_hist ]; 
  comavr = [ trystrs.no_check '[EEG LASTCOM] = pop_loadeep_avg;' catchstrs.new_and_hist ];
  
  % create menus
  % ------------
  uimenu( menu, 'label', 'From ANT .CNT file', 'callback', comcnt, 'separator', 'on' );
  uimenu( menu, 'label', 'From ANT .AVR file', 'callback', comavr );

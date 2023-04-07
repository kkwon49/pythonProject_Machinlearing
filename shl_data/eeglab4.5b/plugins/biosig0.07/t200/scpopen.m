function [HDR]=scpopen(HDR,PERMISSION,arg3,arg4,arg5,arg6)
% SCPOPEN reads SCP-ECG files 
%
% HDR = scpopen(Filename,PERMISSION);
%
% HDR contains the Headerinformation and internal data
%
% see also: SOPEN, SREAD, SSEEK, STELL, SCLOSE, SWRITE, SEOF


% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

%	$Revision: 1.11 $
%	$Id: scpopen.m,v 1.11 2004/07/02 16:17:02 schloegl Exp $
%	(C) 2004 by Alois Schloegl
%	a.schloegl@ieee.org	
%    	This is part of the BIOSIG-toolbox http://biosig.sf.net/

if nargin<1, PERMISSION='rb'; end;

VER = version;

fid = fopen(HDR.FileName,PERMISSION,'ieee-le');
if ~isempty(findstr(PERMISSION,'r')),		%%%%% READ 
        HDR.FILE.CRC = fread(fid,1,'uint16');
        HDR.FILE.Length = fread(fid,1,'uint32');
	HDR.data = [];
        
        DHT = [0,1,-1,2,-2,3,-3,4,-4,5,-5,6,-6,7,-7,8,-8,9,-9;0,1,5,3,11,7,23,15,47,31,95,63,191,127,383,255,767,511,1023]';
        prefix  = [1,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,10,10];

        %PREFIX = [0,4,5,12,13,28,29,60,61,124,125,252,253,508,509,1020,1021,1022,1023];
        PREFIX  = [0,4,5,12,13,28,29,60,61,124,125,252,253,508,509,1020,1021,1022,1023]'.*2.^[32-prefix]';
        codelength = [1,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,18,26];
        mask    = [1,7,7,15,15,31,31,63,63,127,127,255,255,511,511,1023,1023,1023,1023]'.*2.^[32-prefix]';
        %MASK    = dec2bin(mask);
        %mask   = [1,7,7,15,15,31,31,63,63,127,127,255,255,511,511,1023,1023,1023,1023]';

        mask2    = [1,7,7,15,15,31,31,63,63,127,127,255,255,511,511,1023,1023,1023,1023]';
        PREFIX2  = DHT(:,2);

	HT19999 = [prefix',codelength',ones(length(prefix),1),DHT];
	HT = [prefix',codelength',ones(length(prefix),1),DHT];
        
        dd = [0:255]';
        ACC = zeros(size(dd));
        c = 0;
        for k2 = 1:8,
                ACC = ACC + (dd>127).*(2^c);
                dd  = mod(dd*2, 256);
                c   = c + 1;
        end;
        
        K  = 0;
        section.CRC = fread(fid,1,'uint16');
        while ~feof(fid)
                pos = ftell(fid);
                section.ID      = fread(fid,1,'uint16');
                section.Length  = fread(fid,1,'uint32');
                section.Version = fread(fid,[1,2],'uint8');
                section.tmp     = fread(fid,[1,6],'uint8');
                
                K = K + 1;
                HDR.Section{K} = section;
                if section.ID==0, 
                        for k = 1:((section.Length-16)/10),
                                HDR.Block(k).id = fread(fid,1,'uint16');    
                                HDR.Block(k).length = fread(fid,1,'uint32');    
                                HDR.Block(k).startpos = fread(fid,1,'uint32');    
                        end;
                        
                elseif section.ID==1,
                        tag = 0; 
                        k1  = 0;
                        while tag~=255,
                                tag = fread(fid,1,'uchar');    
                                len = fread(fid,1,'uint16');    
                                field = fread(fid,[1,len],'uchar');

                                if tag == 0,	
                                        HDR.Patient.LastName = char(field);
                                elseif tag == 1,
                                        HDR.Patient.FirstName = char(field);
                                elseif tag == 2,
                                        HDR.Patient.ID = char(field);
                                elseif tag == 3,
                                        HDR.Patient.LastName2 = char(field);
                                elseif tag == 4,
                                        HDR.Patient.Age = str2double(char(field(1:2)));
                                        tmp = field(3);
                                        if tmp==0, unit=' ';
                                        elseif tmp==1, unit='Y';
                                        elseif tmp==2, unit='M';
                                        elseif tmp==3, unit='W';
                                        elseif tmp==4, unit='d';
                                        elseif tmp==5, unit='h';
                                        end;
                                        HDR.Patient.AgeUnit = unit;
                                elseif tag == 5,
                                %        HDR.Patient.DateOfBirth = [field(1:2)*[1;256],field(3:4)];
                                elseif tag == 6,
                                        HDR.Patient.Height = field(1:2)*[1;256];
                                        tmp = field(3);
                                        if tmp==0, unit=' ';
                                        elseif tmp==1, unit='cm';
                                        elseif tmp==2, unit='inches';
                                        elseif tmp==3, unit='mm';
                                        end;
                                        HDR.Patient.HeightUnit = unit;
                                elseif tag == 7,
                                        HDR.Patient.Weight = field(1:2)*[1;256];
                                        tmp = field(3);
                                        if tmp==0, unit=' ';
                                        elseif tmp==1, unit='kg';
                                        elseif tmp==2, unit='g';
                                        elseif tmp==3, unit='pound';
                                        elseif tmp==4, unit='ounce';
                                        end;
                                        HDR.Patient.WeightUnit = unit;
                                elseif tag == 8,
                                        HDR.Patient.Sex = field;
                                elseif tag == 9,
                                        HDR.Patient.Race = field;
                                elseif tag == 10,
                                        HDR.Patient.Medication = field;
                                elseif tag == 11,
                                        HDR.Patient.BloodPressure.Systolic = field*[1;256];
                                elseif tag == 12,
                                        HDR.Patient.BloodPressure.Diastolic = field*[1;256];
                                elseif tag == 13,
                                        HDR.Patient.Diagnosis = char(field);
                                elseif tag == 14,
                                        HDR.SCP1.AcquiringDeviceID = char(field);
                                elseif tag == 15,
                                        HDR.SCP1.AnalyisingDeviceID = char(field);
                                elseif tag == 16,
                                        HDR.SCP1.AcquiringInstitution = char(field);
                                elseif tag == 17,
                                        HDR.SCP1.AnalyzingInstitution = char(field);
                                elseif tag == 18,
                                        HDR.SCP1.AcquiringDepartment = char(field);
                                elseif tag == 19,
                                        HDR.SCP1.AnalyisingDepartment = char(field);
                                elseif tag == 20,
                                        HDR.SCP1.Physician = char(field);
                                elseif tag == 21,
                                        HDR.SCP1.LatestComfirmingPhysician = char(field);
                                elseif tag == 22,
                                        HDR.SCP1.Technician = char(field);
                                elseif tag == 23,
                                        HDR.SCP1.Room = char(field);
                                elseif tag == 24,
                                        HDR.SCP1.Emergency = field;
                                elseif tag == 25,
                                        HDR.T0(1,1:3) = [field(1:2)*[1;256],field(3:4)];
                                elseif tag == 26,
                                        HDR.T0(1,4:6) = field(1:3);
                                elseif tag == 27,
                                        HDR.Filter.HighPass = field(1:2)*[1;256]/100;
                                elseif tag == 28,
                                        HDR.Filter.LowPass = field(1:2)*[1;256]/100;
                                elseif tag == 28,
                                        HDR.Filter.BitMap = field;
                                elseif tag == 30,
                                        HDR.SCP1.FreeText = char(field);
                                elseif tag == 31,
                                        HDR.SCP1.ECGSequenceNumber = char(field);
                                elseif tag == 32,
                                        HDR.SCP1.MedicalHistoryCodes = char(field);
                                elseif tag == 33,
                                        HDR.SCP1.ElectrodeConfigurationCodes = field;
                                elseif tag == 34,
                                        HDR.SCP1.Timezone = field;
                                elseif tag == 35,
                                        HDR.SCP1.MedicalHistory = char(field);
                                elseif tag == 255,
                                        % section terminator	
                                end;
                        end;
                        
                elseif section.ID==2, 	% Huffman tables 
                        HDR.SCP2.NHT = fread(fid,1,'uint16');            
                        HDR.SCP2.NCT = fread(fid,1,'uint16');    
			if HDR.SCP2.NHT~=19999,
				NHT = HDR.SCP2.NHT;
			else
				NHT = 0; 
			end;
                        k3 = 0;
                        for k1 = 1:NHT,
                                for k2 = 1:HDR.SCP2.NCT,
                                	tmp = fread(fid,3,'uint8') ;
                                        HDR.SCP2.prefix = tmp(1);
                                        HDR.SCP2.codelength = tmp(2);
                                        HDR.SCP2.TableModeSwitch = tmp(3);
                                        tmp(4) = fread(fid,1,'int16');    
                                        tmp(5) = fread(fid,1,'uint32');    
                                	k3 = k3 + 1;
				        HT(k3,:) = [k1,k2,tmp']; 
                                end;
			end;
			if HDR.SCP2.NHT~=19999,
				HDR.SCP2.HT = HT;
			else
				tmp = size(HT19999,1);
				HDR.SCP2.HT = [ones(tmp,1),[1:tmp]',HT19999];
			end;

                elseif section.ID==3, 
                        HDR.NS = fread(fid,1,'char');    
                        HDR.FLAG.Byte = fread(fid,1,'char');    
                        HDR.FLAG.ReferenceBeat = mod(HDR.FLAG.Byte,2);    
                        %HDR.NS = floor(mod(HDR.FLAG.Byte,128)/8);    
                        for k = 1:HDR.NS,
                                HDR.LeadPos(k,1:2) = fread(fid,[1,2],'uint32');    
                                HDR.Lead(k,1) = fread(fid,1,'uint8');    
                        end;
                        HDR.N = max(HDR.LeadPos(:))-min(HDR.LeadPos(:))+1;
                        
                        LeadIdTable = 	{'I';'II';'V1';'V2';'V3';'V4';'V5';'V6';'V7';'V2R';'V3R';'V4R';'V5R';'V6R';'V7R';'X';'Y';'Z';'CC5';'CM5';'left arm';'right arm';'left leg';'I';'E';'C';'A';'M';'F';'H';'I-cal'};
                        if max(HDR.Lead)<length(LeadIdTable),        
                                HDR.Label = LeadIdTable(HDR.Lead);
                        end;
                        
                elseif section.ID==4, 
                        HDR.SCP4.L = fread(fid,1,'int16');    
                        HDR.SCP4.fc0 = fread(fid,1,'int16');    
                        HDR.SCP4.N = fread(fid,1,'int16');    
                        HDR.SCP4.type = fread(fid,[7,HDR.SCP4.N],'uint16')'*[1,0,0,0; 0,1,0,0;0,2^16,0,0; 0,0,1,0;0,0,2^16,0; 0,0,0,1;0,0,0,2^16];   

                        tmp = fread(fid,[2*HDR.SCP4.N],'uint32');
                        HDR.SCP4.PA = reshape(tmp,2,HDR.SCP4.N)';   
                        HDR.SCP4.pa = [0;tmp;HDR.N];   
                        
                elseif any(section.ID==[5,6]), 
                        SCP = [];
                        SCP.Cal = fread(fid,1,'int16')/1e6;    
                        SCP.PhysDim = 'mV';
                        SCP.Dur = fread(fid,1,'int16');    
                        SCP.SampleRate = 1e6/SCP.Dur;
                        SCP.FLAG.DIFF = fread(fid,1,'uint8');    
                        SCP.FLAG.bimodal_compression = fread(fid,1,'uint8');    
                        SCP.SPR = fread(fid,HDR.NS,'uint16');
                        
                        if section.ID==6,
                                HDR.HeadLen = ftell(fid);
                                HDR.FLAG.DIFF = SCP.FLAG.DIFF;
                                HDR.FLAG.bimodal_compression = SCP.FLAG.bimodal_compression;
                                HDR.data = [];
                        end;

                        if ~isfield(HDR,'SCP2'),
                                if any(SCP.SPR(1)~=SCP.SPR),
                                        error('SCPOPEN: SPR do not fit');
                                else
                                        S2 = fread(fid,[SCP.SPR(1)/2,HDR.NS],'int16');
                                end;
        
                        elseif HDR.SCP2.NHT==19999,
                                HuffTab = DHT;
				S2 = []; %repmat(NaN,HDR.N,HDR.NS);
                                for k = 1:HDR.NS,
                                        SCP.data{k} = fread(fid,SCP.SPR(k),'uint8');    
                                        s2 = SCP.data{k};
                                        s2 = [s2; repmat(0,ceil(max(HDR.SCP2.HT(:,4))/8),1)];
					k1 = 0;	
					l2 = 0; 
					accu = 0;
					c  = 0; 
					x  = [];
					HT = HDR.SCP2.HT(find(HDR.SCP2.HT(:,1)==1),3:7);
					while (l2 < HDR.LeadPos(k,2)),
						while c < max(HT(:,2));
							k1 = k1 + 1;
 %                                                       [k1,length(s2),k,HDR.NS],ret
							dd = s2(k1);
							accu = accu + ACC(dd+1)*(2^c);
							c = c + 8;

							if 0, %for k2 = 1:8,
								accu = accu + (dd>127)*(2^c);
								dd = mod(dd*2,256);
								c = c + 1;
							end;
						end;

                                                ixx = 1;
                                                %acc = mod(accu,2^32);   % bitand returns NaN if accu >= 2^32
						acc = accu - 2^32*fix(accu*(2^(-32)));   % bitand returns NaN if accu >= 2^32
						while (bitand(acc,2^HT(ixx,1)-1) ~= HT(ixx,5)),
							ixx = ixx + 1;
						end;
                                                
                                                dd = HT(ixx,2) - HT(ixx,1);
						if HT(ixx,3)==0,
							HT = HDR.SCP2.HT(find(HDR.SCP2.HT(:,1)==HT(ixx,5)),3:7);
							fprintf(HDR.FILE.stderr,'Warning SCPOPEN: Switching Huffman Tables is not tested yet.\n');
						elseif (dd==0),
							l2 = l2 + 1;
							x(l2) = HT(ixx,4);
						else %if (HT(ixx,3)>0),
							l2 = l2 + 1;
							%acc2  = fix(accu*(2^(-HT(ixx,1))));
							%tmp = mod(fix(accu*(2^(-HT(ixx,1)))),2^dd);
							
                                                        tmp = fix(accu*(2^(-HT(ixx,1))));       % bitshift(accu,-HT(ixx,1))
                                                        tmp = tmp - (2^dd)*fix(tmp*(2^(-dd)));  % bitand(...,2^dd)
                                                        
                                                        %tmp = bitand(accu,(2^dd-1)*(2^HT(ixx,1)))*(2^-HT(ixx,1));
                                                        % reverse bit-pattern
                                                        if dd==8,
                                                                tmp = ACC(tmp+1);
                                                        else
                                                                tmp = dec2bin(tmp);
                                                                tmp = [char(repmat('0',1,dd-length(tmp))),tmp];
                                                                tmp = bin2dec(tmp(length(tmp):-1:1));
                                                        end
                                                        x(l2) = tmp-(tmp>=(2^(dd-1)))*(2^dd);
						end;
						accu = fix(accu*2^(-HT(ixx,2)));
						c = c - HT(ixx,2); 
					end;

                                        if k==1,
                                                S2 = x';
                                        elseif size(x,2)==size(S2,1),
                                                S2(:,k) = x';
					else
	                                        fprintf(HDR.FILE.stderr,'Error SCPOPEN: Huffman decoding failed (%i) \n',size(x,1));
	    					HDR.data = S2;
						return;
                                        end;
				end;
                                
                                
                        elseif (HDR.SCP2.NHT==19999), % alternative decoding algorithm. 
                                HuffTab = DHT;
                                for k = 1:HDR.NS,
                                        SCP.data{k} = fread(fid,SCP.SPR(k),'uint8');    
                                end;
                                clear S2;
                                for k = 1:HDR.NS,
                                        tmp = SCP.data{k};
                                        accu = [tmp(4)+256*tmp(3)+65536*tmp(2)+2^24*tmp(1)];
                                        %accu = bitshift(accu,HDR.SCP2.prefix,32);
                                        c  = 0; %HDR.SCP2.prefix;
                                        l  = 4;
                                        l2 = 0;
                                        clear x;
                                        Ntmp = length(tmp);
                                        tmp = [tmp; zeros(4,1)];
                                        while c <= 32, %1:HDR.SPR(k),
                                                ixx = 1;
                                                while (bitand(accu,mask(ixx)) ~= PREFIX(ixx)), 
                                                        ixx = ixx + 1;
                                                end;

                                                if ixx < 18,
                                                        c = c + prefix(ixx);
                                                        %accu  = bitshift(accu, prefix(ixx),32);
                                                        accu  = mod(accu.*(2^prefix(ixx)),2^32);
                                                        l2    = l2 + 1;
                                                        x(l2) = HuffTab(ixx,1);
                                                        
                                                elseif ixx == 18,
                                                        c = c + prefix(ixx) + 8;
                                                        %accu = bitshift(accu, prefix(ixx),32);
                                                        accu  = mod(accu.*(2^prefix(ixx)),2^32);
                                                        l2    = l2 + 1;
                                                        
                                                        acc1  = mod(floor(accu*2^(-24)),256);
                                                        %accu = bitshift(accu, 8, 32);
                                                        accu  = mod(accu*256, 2^32);
                                                        
                                                        x(l2) = acc1-(acc1>=2^7)*2^8;
                                                        acc2  = 0;
                                                        for kk = 1:8,
                                                                acc2 = acc2*2 + mod(acc1,2);
                                                                acc1 = floor(acc1/2);
                                                        end;
                                                        
                                                elseif ixx == 19,
                                                        c = c + prefix(ixx);
                                                        %accu = bitshift(accu, prefix(ixx),32);
                                                        accu  = mod(accu.*(2^prefix(ixx)),2^32);
                                                        l2    = l2 + 1;
                                                        while (c > 7) & (l < Ntmp),
                                                                l = l+1;
                                                                c = c-8;
                                                                accu = accu + tmp(l)*2^c;
                                                        end;
                                                        
                                                        acc1 = mod(floor(accu*2^(-16)),2^16);
                                                        %accu = bitshift(accu, 16, 32);
                                                        accu = mod(accu.*(2^16), 2^32);
                                                        
                                                        x(l2) = acc1-(acc1>=2^15)*2^16;
                                                        acc2 = 0;
                                                        for kk=1:16,
                                                                acc2 = acc2*2+mod(acc1,2);
                                                                acc1 = floor(acc1/2);
                                                        end;
                                                        %x(l2) = acc2;
                                                        c = c + 16;
                                                end;
                                                
                                                while (c > 7) & (l < Ntmp),
                                                        l = l+1;
                                                        c = c-8;
                                                        accu = accu + tmp(l)*(2^c);
                                                end;
                                                %accu,
                                        end;
                                        %HDR.SCP6.S(:,k) = x(1:end-1)';
                                        x = x(1:end-1)';
                                        if k==1,
                                                S2=x;
                                        elseif size(x,1)==size(S2,1),
                                                S2(:,k) = x;
					else
	                                        fprintf(HDR.FILE.stderr,'Error SCPOPEN: Huffman decoding failed (%i) \n',size(x,1));
	    					HDR.data=S2;
						return;
                                        end;
                                end;
                                        
                        elseif (HDR.SCP2.NHT==1) & (HDR.SCP2.NCT==1) & (HDR.SCP2.prefix==0), 
				codelength = HDR.SCP.HT(1,4);
                                if (codelength==16)
                                        S2 = fread(fid,[HDR.N,HDR.NS],'int16');  
                                elseif (codelength==8)
                                        S2 = fread(fid,[HDR.N,HDR.NS],'int8');  
                                else
                                        fprintf(HDR.FILE.stderr,'Warning SCPOPEN: codelength %i is not supported yet.',codelength);
                                        fprintf(HDR.FILE.stderr,' Contact <a.schloegl@ieee.org>\n');
                                        return;
                                end;                                        
                                
                        elseif HDR.SCP2.NHT~=19999,
                                fprintf(HDR.FILE.stderr,'Warning SOPEN SCP-ECG: user specified Huffman Table not supported\n');
                                HDR.SCP = SCP;
                                return;
                                
                        else
                                HDR.SCP2,
                        end;
                        
                        % Decoding of Difference encoding                  
                        if SCP.FLAG.DIFF==2,
                                for k1 = 3:size(S2,1);
                                        S2(k1,:) = S2(k1,:) + [2,-1] * S2(k1-(1:2),:);
                                end;
                        elseif SCP.FLAG.DIFF==1,
                                S2 = cumsum(S2);    
                        end;
                        
                        S2 = S2 * SCP.Cal;
                        if section.ID==5,
                                HDR.SCP5 = SCP;
                                HDR.SCP5.data = S2;
                                HDR.SampleRate = SCP.SampleRate;
                                
                        elseif section.ID==6,
                                HDR.SCP6 = SCP;
                                HDR.SampleRate = SCP.SampleRate;
                                HDR.PhysDim = HDR.SCP6.PhysDim;
                                HDR.data = S2;
                                
                                if HDR.SCP6.FLAG.bimodal_compression,
                                        F = HDR.SCP5.SampleRate/HDR.SCP6.SampleRate;
                                        HDR.SampleRate = HDR.SCP5.SampleRate;
                                        HDR.FLAG.F = F;
                                        
                                        tmp=[HDR.SCP4.PA(:,1);HDR.LeadPos(1,2)]-[1;HDR.SCP4.PA(:,2)+1];
                                        if ~all(tmp==floor(tmp))
                                                tmp,
                                        end;
                                        t  = (1:HDR.N) / HDR.SampleRate;
                                        S1 = zeros(HDR.N, HDR.NS);
                                        
                                        
                                        p = 1;
                                        k2 = 1;
                                        pa = [HDR.SCP4.PA;NaN,NaN];
                                        flag = 1;
                                        for k1 = 1:HDR.N,
                                                if k1 == pa(p,2)+1,
                                                        flag = 1;
                                                        p    = p+1;
                                                        accu = S2(k2,:);
                                                elseif k1 == pa(p,1),
                                                        flag = 0;
                                                        k2 = ceil(k2);
                                                end;
                                                
                                                if flag,
                                                        S1(k1,:) = ((F-1)*accu + S2(fix(k2),:)) / F;
                                                        k2 = k2 + 1/F;
                                                else	
                                                        S1(k1,:) = S2(k2,:);
                                                        k2 = k2 + 1;
                                                end;
                                        end;	
                                        
                                        HDR.SCP.S2 = S2;
                                        HDR.SCP.S1 = S1;
                                        S2 = S1;
                                end;
                                
                                if HDR.FLAG.ReferenceBeat,
                                        for k = find(~HDR.SCP4.type(:,1)'),
                                                t1 = (HDR.SCP4.type(k,2):HDR.SCP4.type(k,4));
                                                t0 = t1 - HDR.SCP4.type(k,3) + HDR.SCP4.fc0;
                                                S2(t1,:) = S2(t1,:) + HDR.SCP5.data(t0,:); 
                                        end;
                                end;
                                HDR.data = S2;
                        end;
                        
                elseif section.ID==7, 
                        HDR.SCP7.byte1 = fread(fid,1,'uint8');    
                        HDR.SCP7.Nspikes = fread(fid,1,'uint8');    
                        HDR.SCP7.meanPPI = fread(fid,1,'uint16');    
                        HDR.SCP7.avePPI = fread(fid,1,'uint16');    
                        
                        for k=1:HDR.SCP7.byte1,
                                HDR.SCP7.RefBeat{k} = fread(fid,16,'uint8');    
                                %HDR.SCP7.RefBeat1 = fread(fid,16,'uint8');    
                        end;
                        
                        for k=1:HDR.SCP7.Nspikes,
                                tmp = fread(fid,16,'uint16');    
                                tmp(1,2) = fread(fid,16,'int16');    
                                tmp(1,3) = fread(fid,16,'uint16');    
                                tmp(1,4) = fread(fid,16,'int16');    
                                HDR.SCP7.ST(k,:) = tmp;
                        end;
                        for k=1:HDR.SCP7.Nspikes,
                                tmp = fread(fid,6,'uint8');    
                                HDR.SCP7.ST2(k,:) = tmp;
                        end;
                        HDR.SCP7.Nqrs = fread(fid,1,'uint16');    
                        HDR.SCP7.beattype = fread(fid,HDR.SCP7.Nqrs,'uint8');    
                        
                        HDR.SCP7.VentricularRate = fread(fid,1,'uint16');    
                        HDR.SCP7.AterialRate = fread(fid,1,'uint16');    
                        HDR.SCP7.QTcorrected = fread(fid,1,'uint16');    
                        HDR.SCP7.TypeHRcorr = fread(fid,1,'uint8');    
                        
                        len = fread(fid,1,'uint16');
                        tag = 255*(len==0); 
                        k1 = 0;
                        while tag~=255,
                                tag = fread(fid,1,'uchar');    
                                len = fread(fid,1,'uint16');    
                                field = fread(fid,[1,len],'uchar');    
                                
                                if tag == 0,	
                                        HDR.Patient.LastName = char(field);
                                elseif tag == 1,
                                        
                                end;
                        end;
                        HDR.SCP7.P_onset = fread(fid,1,'uint16');    
                        HDR.SCP7.P_offset = fread(fid,1,'uint16');    
                        HDR.SCP7.QRS_onset = fread(fid,1,'uint16');    
                        HDR.SCP7.QRS_offset = fread(fid,1,'uint16');    
                        HDR.SCP7.T_offset = fread(fid,1,'uint16');    
                        HDR.SCP7.P_axis = fread(fid,1,'uint16');    
                        HDR.SCP7.QRS_axis = fread(fid,1,'uint16');    
                        HDR.SCP7.T_axis = fread(fid,1,'uint16');    
                        
                elseif section.ID==8, 
                        tmp = fread(fid,9,'uint8');    
                        HDR.SCP8.Report = tmp(1);    
                        HDR.SCP8.Time = [[1,256]*tmp(2:3),tmp(4:8)'];    
                        HDR.SCP8.N = tmp(9);    
                        for k = 1:HDR.SCP8.N,
                                ix  = fread(fid,1,'uint8');
                                len = fread(fid,1,'uint16');
                                tmp = fread(fid,[1,len],'uchar');    
                                HDR.SCP8.Statement{k} = char(tmp);    
                        end
                        
                elseif section.ID==9, 
                        HDR.SCP9.byte1 = fread(fid,1,'uint8');    
                        
                elseif section.ID==10, 
                        HDR.SCP10.byte1 = fread(fid,1,'uint8');    
                        
                elseif section.ID==11, 
                        
                end;
                
                %tmp = fread(fid,min(section.Length-16,1000),'uchar');    
                
                fseek(fid, pos+section.Length-2, -1);
                section.CRC = fread(fid,1,'uint16');
        end;
        
        HDR.FILE.FID  = fid;
        HDR.FILE.OPEN = 1; 
        HDR.FILE.POS  = 0; 
        [HDR.SPR, HDR.NS] = size(HDR.data);
        HDR.NRec = 1;
        HDR.AS.endpos = HDR.SPR;
        
end;


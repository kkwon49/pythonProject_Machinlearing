function [ResEDF, ResUserData, Replace] = analyse(EDF, UserData, Opt)
% template for a plugin function
% a plugin *must* set the ResEDF values for:
%   Head.NS, Head.NRec, Head.PhysMin, Head.PhysMax, Labels

% Changes:
% 09/18/98 : data format changed
% (c) 2-Dec-1998 Michi Woertz
% (c) 3-Dec-1998 Alois Schloegl, modified. 
% (c) 1-Mar-1999 Alois Schloegl, major revision, PCA3 included, 
% (c) 2-Mar-1999 Alois Schloegl, ECG from PCA3 removed, sorting of EV by EW, PhysDim of PCA set to 1
% (c) 11-Mar-1999 Alois Schloegl, PCA4, PCA4-001, PCA4-001-002 implemented, available for P002302 only. 
% (c) 30-Mar-1999 Alois Schloegl, Dialog improved.

if nargin < 3
  Opt = '';
end;

Replace=0;         % a tribute to viewedf2

switch Opt
  case 'Reset'
    % Check whether EDF File has changed, update UserData, ...
    [ResEDF, ResUserData] = LocalReset(EDF, UserData);
  case 'Menu'
    % set UserData if necessary
    [ResEDF, ResUserData] = LocalConfigure(EDF, UserData);
  otherwise
    % Update ResEDF
    [ResEDF, ResUserData] = LocalUpdate(EDF, UserData);
end;
%return;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ResEDF, ResUserData] = LocalConfigure(EDF, UserData)    % channel selection only
if UserData.RESerror
   [ResEDF, ResUserData] = LocalReset(EDF, UserData);
   UserData=ResUserData;         % overcome the problem of recursions
   EDF=ResEDF;
   UserData.select=zeros(6,1);
else
   [UserData]=channels(UserData,2);
end;
[ResEDF, ResUserData] = LocalUpdate(EDF, UserData);
%return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ResEDF, ResUserData] = LocalReset(EDF, UserData)
% proove existence     % needed only once
FN=EDF.Head.FILE.Name;
UserData.RESerror=1;
ResUserData=UserData;
ResEDF=EDF;
ResEDF.Head.NS=0;
UserData.select=zeros(6,1);

m=[8 1 1; 9 1 -1; 1 2 1; 4 2 1; 7 2 1; 8 2 -1; 9 2 -1; 3 3 1; 6 3 1; 7 3 2; 8 3 -2; 9 3 -2; 12 4 1];
m=sparse(m(:,1),m(:,2),m(:,3),EDF.Head.NS,4);
m(:,2)=m(:,2)/2;
m(:,3)=m(:,3)/4;

clear IN XC310 RES XC4
RES=[];
IN=[];

%cmd=['load (''' FN 'res.mat'', ''RES'' ) ' ]; eval(cmd,'-1;');
cmd=['load ' FN 'res.mat RES']; eval(cmd,'-1;');

if 0; ~(exist('RES')==1)
        [FILENAME, PATHNAME] = uigetfile([ FN 'res.mat'],['Searching the ' FN 'in.mat-file...']);
        cmd=['load ' PATHNAME, FN 'res.mat RES']; eval(cmd,'-1;');
        if ~(exist('RES')==1)
                fprintf(2,'Error in plug-in %s: %sres.mat invalid or not found\n',mfilename,FN);
                %return;
        end
end;

%eval('load([FN ''cov310a.mat'']);', '-1;');
cmd=['load ' FN 'cov310a.mat XC310']; eval(cmd,'-1;');
cmd=['load ' FN 'cov4.mat XC4']; eval(cmd,'-1;');

if 0; ~(exist('XC310')==1)
        [FILENAME, PATHNAME] = uigetfile([ FN 'cov310a.mat'],['Searching the ' FN 'in.mat-file...']);
        cmd=['load ' PATHNAME, FN 'cov310a.mat XC310']; eval(cmd,'-1;');
        if ~(exist('XC310')==1)
                fprintf(2,'Error in plug-in %s: %scov310a.mat invalid or not found\n',mfilename,FN);
                %return;
        end
end;

UserData.ModeEnable=zeros(4,1);
UserData.RESerror=0;
UserData.FN=FN;

if FN(1)=='n' 
        IN.chansel=[1:9 17:21];
else
        IN.chansel=[1:9 ];
end;

%IN.chansel=[1:9 12];
fprintf(1,'PreProc PCA1:\n');
if isfield(RES,'XCN');
		  UserData.ModeEnable(1)=1;
   	  [mu,sd,COV,xc]=decovm(RES.XCN);
        IN.COV=COV;
        [IN.PCA1,D]=eig(COV(IN.chansel,IN.chansel));
        [IN.EVD1,I]=sort(-diag(D));
        IN.EVD1=-IN.EVD1;
        IN.PCA1=IN.PCA1(:,I);
        fprintf(1,'PCA1:  OK\n');
else
        fprintf(2,'PCA1 not available in %s\n',FN);
        %warnh = warndlg('PCA1 not available for this file','pca4-plugin Warning');
end;

fprintf(1,'PreProc PCA2:\n');
if isfield(RES,'XCNeog')
		  UserData.ModeEnable(2)=1;
        [mu,sd,COV,xc]=decovm(RES.XCNeog);
        IN.COV=COV;
        [IN.PCA2,D]=eig(COV(IN.chansel,IN.chansel));
        [IN.EVD2,I]=sort(-diag(D));
        IN.EVD2=-IN.EVD2;
        IN.PCA2=IN.PCA2(:,I);
        fprintf(1,'PCA2: OK\n');
else
        fprintf(2,'PCA2 not available in %s\n',FN);
        %warnh = warndlg('PCA2 not available for this file','pca4-plugin Warning');
end;

fprintf(1,'PreProc PCA3: \n');
if exist('XC310')
		  UserData.ModeEnable(3)=1;
        [mu,sd,XC,xc] = decovm(XC310);
        XC = diag(EDF.Head.Cal) * XC * diag(EDF.Head.Cal);
        IN.COV=XC;
        [IN.PCA3,D] = eig(XC(IN.chansel,IN.chansel));
        [IN.EVD3,I] = sort(-diag(D));
        IN.EVD3 = -IN.EVD3;
        IN.PCA3 = IN.PCA3(:,I);
        %fprintf(1,'Channels\tEigenvalues (variance) PCA3\n');
        %fprintf(1,'%i\t%f\n',[(1:length(IN.chansel)); IN.EVD3']);
        fprintf(1,'PCA3: OK\n');
else
        fprintf(2,'PCA3 not available in %s\n',FN);
        %warnh = warndlg('PCA3 not available for this file','pca4-plugin Warning');
        
end;

fprintf(1,'PreProc PCA4:\n');
if exist('XC4');
		  UserData.ModeEnable(4)=1;
        [mu,sd,COV,xc]=decovm(XC4);
        COV = diag(EDF.Head.Cal)*COV*diag(EDF.Head.Cal);
        IN.COV=COV;
        [IN.PCA4,D]=eig(COV(IN.chansel,IN.chansel));
        [IN.EVD4,I]=sort(-diag(D));
        IN.EVD4=-IN.EVD4;
        IN.PCA4=IN.PCA4(:,I);
        fprintf(1,'PCA4:  OK\n');
else
        fprintf(2,'PCA4 not available in %s\n',FN);
        %warnh = warndlg('PCA4 not available for this file','pca4-plugin Warning');
end;

UserData.IN=IN; 
UserData=channels(UserData,2);    % channel selection
[ResEDF, ResUserData] = LocalUpdate(EDF, UserData);
%return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ResEDF, ResUserData] = LocalUpdate(EDF, UserData)
% This function returns the first channel of the first EDF file
if ~UserData.RESerror
   [ResEDF,ResUserData]=eogtmpl(EDF, UserData);
else
   ResEDF=EDF;                 % no valid RES-file present, nothing can be calculated
   ResUserData=UserData;
   ResEDF.Head.NS=0;
end;
%return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	Version 0.70
%	20.08.1998
%	Copyright (c) by  Alois Schloegl
%	a.schloegl@ieee.org	
% Init
function [ResEDF,ResUserData]=eogtmpl(EDF, UserData);

% Selektiert die Kanäle EEG, EOG und ECG [1:9 12]   
% belasse ich derweil so, Rechnung scheint schnell genug... MW
% ersetze aber die Kanalauswahl für das Display...

IN=UserData.IN;                        % do not reload res-Data
maxspr=0;
for k=1:length(IN.chansel),K=IN.chansel(k);
        maxspr=max(maxspr,length(EDF.Record{K}));
end;                                   % UserData required for the Display-Option
S=zeros(maxspr,EDF.Head.NS);
for k=1:EDF.Head.NS,%length(IN.chansel),K=IN.chansel(k);
        K=k;
        if maxspr==length(EDF.Record{K})
                tmp=EDF.Record{K}(:);
        else
                tmp=reshape((ones(maxspr/length(EDF.Record{K}),1)*(EDF.Record{K})'),maxspr,1);
        end;
        S(:,k)=tmp;
end;                                   % UserData required for the Display-Option

ResEDF=EDF;
ResUserData=UserData;
ResEDF.Head.NS=0;                      % up to now
count=1;                               % counter for calculated channels

if UserData.select(1)
PCA1.out=S(:,IN.chansel)*IN.PCA1;
PCA1.NS=size(IN.PCA1,2);
PCA1.Label=[ones(PCA1.NS,1)*'PCA1- ' reshape(sprintf('%03i       ',1:PCA1.NS),10,PCA1.NS)'];
ResEDF.Record(count:PCA1.NS)=num2cell(PCA1.out,[10 1]);    % put into output
ResEDF.Head.Label(count:PCA1.NS,:)=PCA1.Label(1:PCA1.NS,:);
ResEDF.Head.PhysDim(count+(0:PCA1.NS-1),:)=setstr(32*ones(PCA1.NS,8));
ResEDF.Head.NRec=EDF.Head.NRec;
ResEDF.Head.PhysMin(count:PCA1.NS+count-1)=-1e2*ones(PCA1.NS,1);
ResEDF.Head.PhysMax(count:PCA1.NS+count-1)=1e2*ones(PCA1.NS,1);
ResEDF.Head.DigMin(count:PCA1.NS+count-1)=-1e2*ones(PCA1.NS,1);
ResEDF.Head.DigMax(count:PCA1.NS+count-1)=1e2*ones(PCA1.NS,1);
ResEDF.Head.Cal(count:PCA1.NS+count-1)=ones(PCA1.NS,1);
ResEDF.Head.Off(count:PCA1.NS+count-1)=zeros(PCA1.NS,1);
count=count+PCA1.NS;
end;

if UserData.select(2)
PCA2.NS=size(IN.PCA2,2);
PCA2.Label=[ones(PCA2.NS,1)*'PCA2- ' reshape(sprintf('%03i       ',1:PCA2.NS),10,PCA2.NS)'];
ResEDF.Record(count:PCA2.NS+count-1)=num2cell(PCA2.out,[10 1]);    % put into output
ResEDF.Head.Label(count:PCA2.NS+count-1,:)=PCA2.Label(1:PCA2.NS,:);
ResEDF.Head.PhysDim(count:PCA2.NS+count-1,:)=setstr(32*ones(PCA2.NS,8));
ResEDF.Head.NRec=EDF.Head.NRec;
ResEDF.Head.PhysMin(count:PCA2.NS+count-1)=-1e2*ones(PCA2.NS,1);
ResEDF.Head.PhysMax(count:PCA2.NS+count-1)=1e2*ones(PCA2.NS,1);
ResEDF.Head.DigMin(count:PCA2.NS+count-1)=-1e2*ones(PCA2.NS,1);
ResEDF.Head.DigMax(count:PCA2.NS+count-1)=1e2*ones(PCA2.NS,1);
ResEDF.Head.Cal(count:PCA2.NS+count-1)=ones(PCA2.NS,1);
ResEDF.Head.Off(count:PCA2.NS+count-1)=zeros(PCA2.NS,1);
count=count+PCA2.NS;
end;
if UserData.select(3)
        M  = IN.PCA4(:,1);
        cov= IN.COV(IN.chansel,IN.chansel);
        IN.REG1b=(eye(length(IN.chansel))-M*((M'*cov*M)\(M'*cov)));
        
NS=size([M IN.REG1b],2);
REG1.out = S(:,IN.chansel)*[M IN.REG1b];
REG1.Label=['PCA4-001        ';[ones(NS-1,1)*'Corr: ' EDF.Head.Label(IN.chansel,1:10)]];

ResEDF.Head.Label(count+(0:NS-1),:)=REG1.Label(1:NS,:);
ResEDF.Record(count+(0:NS-1))=num2cell(REG1.out,1);    % put into output
ResEDF.Head.PhysDim(count,:)='        ';
ResEDF.Head.PhysDim(count+(1:NS-1),:)=EDF.Head.PhysDim([  IN.chansel],:);
ResEDF.Head.PhysMin(count:NS+count-1)=EDF.Head.PhysMin([8 IN.chansel]);
ResEDF.Head.PhysMax(count:NS+count-1)=EDF.Head.PhysMax([8 IN.chansel]);
ResEDF.Head.DigMin(count:NS+count-1)=EDF.Head.DigMin([8 IN.chansel]);
ResEDF.Head.DigMax(count:NS+count-1)=EDF.Head.DigMax([8 IN.chansel]);
ResEDF.Head.NRec=EDF.Head.NRec;
count=count+NS; 
end;
if UserData.select(4)
        M  = IN.PCA4(:,1:2);
        cov= IN.COV(IN.chansel,IN.chansel);
        IN.REG1b=(eye(length(IN.chansel))-M*((M'*cov*M)\(M'*cov)));
        
NS=size([M IN.REG1b],2);
REG1.out = S(:,IN.chansel)*[M IN.REG1b];
REG1.Label=['PCA4-001        ';'PCA4-002        ';[ones(NS-2,1)*'Corr: ' EDF.Head.Label(IN.chansel,1:10)]];

ResEDF.Head.Label(count+(0:NS-1),:)=REG1.Label(1:NS,:);
ResEDF.Record(count+(0:NS-1))=num2cell(REG1.out,1);    % put into output
ResEDF.Head.PhysDim(count+(0:1),:)=['        ';'        '];
ResEDF.Head.PhysDim(count+(2:NS-1),:)=EDF.Head.PhysDim([    IN.chansel],:);
ResEDF.Head.PhysMin(count:NS+count-1)=EDF.Head.PhysMin([8 8 IN.chansel]);
ResEDF.Head.PhysMax(count:NS+count-1)=EDF.Head.PhysMax([8 8 IN.chansel]);
ResEDF.Head.DigMin(count:NS+count-1)=EDF.Head.DigMin([8 8 IN.chansel]);
ResEDF.Head.DigMax(count:NS+count-1)=EDF.Head.DigMax([8 8 IN.chansel]);
ResEDF.Head.NRec=EDF.Head.NRec;
count=count+NS; 
end;
if UserData.select(5)
PCA3.out=S(:,IN.chansel)*IN.PCA3;
PCA3.NS=size(IN.PCA3,2);
PCA3.Label=[ones(PCA3.NS,1)*'PCA3- ' reshape(sprintf('%03i       ',1:PCA3.NS),10,PCA3.NS)'];
ResEDF.Record(count:PCA3.NS+count-1)=num2cell(PCA3.out,[10 1]);    % put into output
ResEDF.Head.Label(count:PCA3.NS+count-1,:)=PCA3.Label(1:PCA3.NS,:);
ResEDF.Head.PhysDim(count:PCA3.NS+count-1,:)=setstr(32*ones(PCA3.NS,8));
ResEDF.Head.NRec=EDF.Head.NRec;
ResEDF.Head.PhysMin(count:PCA3.NS+count-1)=-1e2*ones(PCA3.NS,1);
ResEDF.Head.PhysMax(count:PCA3.NS+count-1)=1e2*ones(PCA3.NS,1);
ResEDF.Head.DigMin(count:PCA3.NS+count-1)=-1e2*ones(PCA3.NS,1);
ResEDF.Head.DigMax(count:PCA3.NS+count-1)=1e2*ones(PCA3.NS,1);
ResEDF.Head.Cal(count:PCA3.NS+count-1)=ones(PCA3.NS,1);
ResEDF.Head.Off(count:PCA3.NS+count-1)=zeros(PCA3.NS,1);
count=count+PCA3.NS;
end;
if UserData.select(6)
PCA4.out=S(:,IN.chansel)*IN.PCA4;
PCA4.NS=size(IN.PCA4,2);
PCA4.Label=[ones(PCA4.NS,1)*'PCA4- ' reshape(sprintf('%03i       ',1:PCA4.NS),10,PCA4.NS)'];
ResEDF.Record(count:PCA4.NS+count-1)=num2cell(PCA4.out,[10 1]);    % put into output
ResEDF.Head.Label(count:PCA4.NS+count-1,:)=PCA4.Label(1:PCA4.NS,:);
ResEDF.Head.PhysDim(count:PCA4.NS+count-1,:)=setstr(32*ones(PCA4.NS,8));
ResEDF.Head.NRec=EDF.Head.NRec;
ResEDF.Head.PhysMin(count:PCA4.NS+count-1)=-1e2*ones(PCA4.NS,1);
ResEDF.Head.PhysMax(count:PCA4.NS+count-1)=1e2*ones(PCA4.NS,1);
ResEDF.Head.DigMin(count:PCA4.NS+count-1)=-1e2*ones(PCA4.NS,1);
ResEDF.Head.DigMax(count:PCA4.NS+count-1)=1e2*ones(PCA4.NS,1);
ResEDF.Head.Cal(count:PCA4.NS+count-1)=ones(PCA4.NS,1);
ResEDF.Head.Off(count:PCA4.NS+count-1)=zeros(PCA4.NS,1);
count=count+PCA4.NS;
end;

ResEDF.Head.NS=count-1;                % total number of calculated signals...

%return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LocalSelectChannels
% select channels to be displayed on the screen
function [UserDaten]=channels(UserDaten,what)

% what=1: select all
% what=0: unselect all
% what=2: no change

%UserDaten.select(2:3)=0;
chans=1:6;
if what~=2
   UserDaten.select(chans)=what;     % pre-set
end;

% find selected channels
text=['Select the various calculations performed...'];
dlgh = dialog(...
    'Name', text, ...
    'CloseRequestFcn', 'set(gcf,''UserData'',''Cancel'');uiresume;');
cbx = 0.1;
cby = 0.95;
cbxspace = 0.4;
cbyspace = 0.8 / 2 + 0.005; 
cbwidth = 0.35;
cbheight = LocalGetFontHeight;
% display EDF channels
text={'PCA1','PCA2','Remove PCA4-001','Remove PCA4-001 & -002','PCA3','PCA4'};
i=[1 2 5 6 3 4]';
tmp=UserDaten.ModeEnable; tmp=tmp([1 2 4 4 3 4]);
texpos=[cbx + rem(i-1,2)*cbxspace, cby - floor((i-1)/2)*cbyspace];
for i = 1:6;
	   if tmp(i)
   	   EnableMode='on';
	   else
   	   EnableMode='off';
	   end;
      
  uih(i) = uicontrol(dlgh, ...
    'Style', 'CheckBox', ...
    'Units', 'Normalized', ...
    'String', text{i}, ...
    'Enable', EnableMode, ...
    'Value', UserDaten.select(i), ...
    'Position', [texpos(i,:), cbwidth, cbheight]);
 
end;
uicontrol(dlgh, ...
    'Style', 'PushButton', ...
    'Units', 'Normalized', ...
    'String', 'Cancel', ...
    'Position', [0.1, 0.02, 0.2, 0.05], ...
    'Callback', 'set(gcf,''UserData'',''Cancel'');uiresume;');
uicontrol(dlgh, ...
    'Style', 'PushButton', ...
    'Units', 'Normalized', ...
    'String', 'OK', ...
    'Position', [0.7, 0.02, 0.2, 0.05], ...
    'Callback', 'set(gcf,''UserData'',''OK'');uiresume;');
 uicontrol(dlgh, ...
    'Style', 'PushButton', ...
    'Units', 'Normalized', ...
    'String', 'Unselect', ...
    'Position', [0.1, 0.08, 0.2, 0.05], ...
    'Callback', 'set(gcf,''UserData'',''Unselect'');uiresume;');
 uicontrol(dlgh, ...
    'Style', 'PushButton', ...
    'Units', 'Normalized', ...
    'String', 'Select', ...
    'Position', [0.7, 0.08, 0.2, 0.05], ...
    'Callback', 'set(gcf,''UserData'',''Select'');uiresume;');
uiwait(dlgh);
changed = 0;
hilfe=get(dlgh,'UserData');
if strcmp(hilfe,'OK')
   changed = 1;
   for i=1:6;   UserDaten.select(i)=get(uih(i),'Value');    end;
   %UserDaten.select=[0 0 0 0 1 0];
end; 
if strcmp(hilfe,'Unselect')
   delete(dlgh);
   [UserDaten]=channels(UserDaten,0);   %unselect all
   return;
elseif strcmp(hilfe,'Select')
   delete(dlgh);
   [UserDaten]=channels(UserDaten,1);   %select all
   return;
end;
delete(dlgh);
if ~(sum(UserDaten.select))               
   text=['No calculation selected!'];
   h=errordlg(text, 'Warning');
   waitfor(h);
end;
%UserDaten.select(2:3)=0;
%return;

% LocalGetFontHeight
% get Fontheight
function hght=LocalGetFontHeight()
tempH = uicontrol(...
    'Style', 'Text', ...
    'String', 'Gg', ...
    'Units', 'Normalized', ...
    'FontUnits', 'Normalized', ...
    'Position', [0, 0, 1, 1], ...
    'Visible', 'off');
hght = get(tempH, 'FontSize') * 1.25; % 1.25 makes things look better
delete(tempH);
%return;


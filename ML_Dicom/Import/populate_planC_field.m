function dataS = populate_planC_field(cellName, dcmdir_patient)
%"populate_planC_field"
%   Given the name of a child cell to planC, such as 'scan', 'dose',
%   'comment', etc. return a copy of that cell with all fields properly
%   populated with data from the files contained in a dcmdir.PATIENT
%   structure.
%
%JRA 06/15/06
%YWU Modified 03/01/08
%
%Usage:
%   dataS = populate_planC_field(cellName, dcmdir);
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

%Get template for the requested cell.
persistent rtPlans

structS = initializeCERR(cellName);
names   = fields(structS);

dataS = [];

switch cellName
    case 'header'
        rtPlans = []; % Clear persistent object
        for i = 1:length(names)
            dataS.(names{i}) = populate_planC_header_field(names{i}, dcmdir_patient);
        end
        
    case 'scan'
        % supportedModalities = {'CT'};
        
        scansAdded = 0;
        
        %Extract all series contained in this patient.
        [seriesC, typeC] = extract_all_series(dcmdir_patient);
        
        %ctSeries = length(find(seriesC(strcmpi(typeC, 'CT'))==1));
        
        %Place each series (CT, MR, etc.) into its own array element.
        for seriesNum = 1:length(seriesC)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%Commented By Divya adding support for US %%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %             if ismember(typeC{seriesNum}, supportedModalities)
            %
            %                 %Populate each field in the scan structure.
            %                 for i = 1:length(names)
            %                     dataS(scansAdded+1).(names{i}) = populate_planC_scan_field(names{i}, seriesC{seriesNum}, typeC{seriesNum});
            %                 end
            %
            %                 scansAdded = scansAdded + 1;
            %             end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%                  End Comment            %%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Test IOP here to find if it is "nominal" or "non-nominal"
            % % %             outIOP = getTest_Scan_IOP(seriesC{seriesNum}.Data(1).file);
            
            if strcmpi(typeC{seriesNum}, 'CT') || strcmpi(typeC{seriesNum}, 'OT') || strcmpi(typeC{seriesNum}, 'NM') ||...
                    strcmpi(typeC{seriesNum}, 'MR') || strcmpi(typeC{seriesNum}, 'PT') || strcmpi(typeC{seriesNum}, 'ST')
                
                %Populate each field in the scan structure.
                for i = 1:length(names)
                    dataS(scansAdded+1).(names{i}) = populate_planC_scan_field(names{i}, seriesC{seriesNum}, typeC{seriesNum}, seriesNum);
                end
                
                if isempty(dataS(scansAdded+1).scanInfo(1).rescaleIntercept)
                   dataS(scansAdded+1).scanInfo(1).rescaleIntercept = 0; 
                end
                
                %Apply ReScale Intercept and Slope
                if strcmpi(typeC{seriesNum}, 'CT')
                    if abs(dataS(scansAdded+1).scanInfo(1).rescaleSlope - 1) > eps*1e5
                        dataS(scansAdded+1).scanArray = single(int32(dataS(scansAdded+1).scanArray) * dataS(scansAdded+1).scanInfo(1).rescaleSlope + dataS(scansAdded+1).scanInfo(1).rescaleIntercept + 1000);
                    else
                        if min(dataS(scansAdded+1).scanArray(:)) >= -32768 && max(dataS(scansAdded+1).scanArray(:)) <= 32767
                            dataS(scansAdded+1).scanArray = uint16(int16(dataS(scansAdded+1).scanArray) * dataS(scansAdded+1).scanInfo(1).rescaleSlope + dataS(scansAdded+1).scanInfo(1).rescaleIntercept + 1000);
                        else
                            dataS(scansAdded+1).scanArray = uint16(int32(dataS(scansAdded+1).scanArray) * dataS(scansAdded+1).scanInfo(1).rescaleSlope + dataS(scansAdded+1).scanInfo(1).rescaleIntercept + 1000);
                        end
                    end
                elseif ~strcmpi(typeC{seriesNum}, 'PT')
                    if abs(dataS(scansAdded+1).scanInfo(1).rescaleSlope - 1) > eps*1e5
                        dataS(scansAdded+1).scanArray = single(int32(dataS(scansAdded+1).scanArray) * dataS(scansAdded+1).scanInfo(1).rescaleSlope + dataS(scansAdded+1).scanInfo(1).rescaleIntercept);
                    else
                        if min(dataS(scansAdded+1).scanArray(:)) >= -32768 && max(dataS(scansAdded+1).scanArray(:)) <= 32767
                            dataS(scansAdded+1).scanArray = uint16(int16(dataS(scansAdded+1).scanArray) * dataS(scansAdded+1).scanInfo(1).rescaleSlope + dataS(scansAdded+1).scanInfo(1).rescaleIntercept);
                        else
                            dataS(scansAdded+1).scanArray = uint16(int32(dataS(scansAdded+1).scanArray) * dataS(scansAdded+1).scanInfo(1).rescaleSlope + dataS(scansAdded+1).scanInfo(1).rescaleIntercept);
                        end
                    end
                end

                scansAdded = scansAdded + 1;
                
            elseif strcmpi(typeC{seriesNum}, 'US')
                %Populate each field in the scan structure.
                for i = 1:length(names)
                    dataS(scansAdded+1).(names{i}) = populate_planC_USscan_field(names{i}, seriesC{seriesNum}, typeC{seriesNum});
                end
                
                scansAdded = scansAdded + 1;
            end
            
        end
        
        
        %     case 'comment'
        %         populate_planC_comment_field(fieldName, dcmdir);
        %
        
    case 'structures'
        [seriesC, typeC]    = extract_all_series(dcmdir_patient);
        supportedTypes      = {'RTSTRUCT'};
        structsAdded          = 0;
        
        hWaitbar = waitbar(0,'Loading Structures Please wait...');
        
        strSeries = length(find(strcmpi(typeC, 'RTSTRUCT')==1));
        
        %Place each structure into its own array element.
        for seriesNum = 1:length(seriesC)
            
            %if ismember(typeC{seriesNum}, supportedTypes)
            if strcmpi(typeC{seriesNum}, 'RTSTRUCT')
                
                RTSTRUCT = seriesC{seriesNum}.Data;
                for k = 1:length(RTSTRUCT)
                    strobj  = scanfile_mldcm(RTSTRUCT(k).file);
                    
                    %ROI Contour Sequence.
                    el = strobj.get(hex2dec('30060039'));
                    % ROI = strobj.getInt(org.dcm4che2.data.Tag.ROIContourSequence);
                    
                    nStructures = el.countItems;
                    curStructNum = 1; %wy modified for suppport multiple RS files
                    for j = 1:nStructures
                        
                        %Populate each field in the structure field set
                        for i = 1:length(names)
                            dataS(structsAdded+1).(names{i}) = populate_planC_structures_field(names{i}, RTSTRUCT, curStructNum, strobj);
                        end
                        curStructNum = curStructNum + 1;
                        structsAdded = structsAdded + 1;
                        
                        waitbar(structsAdded/(nStructures*length(RTSTRUCT)*strSeries), hWaitbar, 'Loading structures, Please wait...');
                        
                        %a temporary limit of 52 structs
                        %if (structsAdded>=52)
                        %    return;
                        %end
                        
                    end
                end
                
            end
            
        end
        close(hWaitbar);
        pause(1);
        
        %     case 'structureArray'
        %         populate_planC_structureArray_field(fieldName, dcmdir);
        
    case 'dose'
        [seriesC, typeC]    = extract_all_series(dcmdir_patient);
        supportedTypes      = {'RTDOSE'};
        dosesAdded          = 0;
        
        %Place each RTDOSE into its own array element.
        for seriesNum = 1:length(seriesC)
            
            %             if ismember(typeC{seriesNum}, supportedTypes)
            if strcmpi(typeC{seriesNum}, 'RTDOSE')                
                
                RTDOSE = seriesC{seriesNum}.Data; %wy RTDOSE{1} for import more than one dose files;
                for doseNum = 1:length(RTDOSE)
                    doseobj  = scanfile_mldcm(RTDOSE(doseNum).file);
                    
                    %check if it is a DVH                    
                    dvhsequence = populate_planC_dose_field('dvhsequence', RTDOSE(doseNum), doseobj, rtPlans);
                    
                    %Check if doesArray is present
                    dose3M = populate_planC_dose_field('doseArray', RTDOSE(doseNum), doseobj, rtPlans);
                    
                    if isempty(dvhsequence) || ~isempty(dose3M)
                        %Populate each field in the dose structure.
                        for i = 1:length(names)
                            dataS(dosesAdded+1).(names{i}) = populate_planC_dose_field(names{i}, RTDOSE(doseNum), doseobj, rtPlans);
                        end
                        dosesAdded = dosesAdded + 1;
                    end
                end
            end
            
        end
        
    case 'DVH'
        [seriesC, typeC]    = extract_all_series(dcmdir_patient);
        supportedTypes      = {'DVH'};
        dvhsAdded           = 0;
        
        %Place each RTDOSE into its own array element.
        for seriesNum = 1:length(seriesC)
            
            %             if ismember(typeC{seriesNum}, supportedTypes)
            if strcmpi(typeC{seriesNum}, 'RTDOSE')                
                
                RTDOSE = seriesC{seriesNum}.Data; %wy RTDOSE{1} for import more than one dose files;
                for doseNum = 1:length(RTDOSE)
                    doseobj  = scanfile_mldcm(RTDOSE(doseNum).file);
                    
                    %check if it is a DVH                    
                    dvhsequence = populate_planC_dose_field('dvhsequence', RTDOSE(doseNum), doseobj, rtPlans);

                    if ~isempty(dvhsequence)
                        % get a list of Structure Names
                        for seriesNumStr = 1:length(seriesC)

                            if strcmpi(typeC{seriesNumStr}, 'RTSTRUCT')

                                RTSTRUCT = seriesC{seriesNumStr}.Data;   
                                structureNameC = {};
                                structureNumberV = [];
                                for k = 1:length(RTSTRUCT)
                                    strobj  = scanfile_mldcm(RTSTRUCT(k).file);

                                    %ROI Contour Sequence.
                                    el = strobj.get(hex2dec('30060039'));
                                    % ROI = strobj.getInt(org.dcm4che2.data.Tag.ROIContourSequence);                                    
                                    nStructures = el.countItems;                                    
                                    for js = 1:nStructures
                                        %get Structure name
                                        structureNameC{end+1} = populate_planC_structures_field('structureName', RTSTRUCT, js, strobj);
                                        structureNumberV(end+1) = populate_planC_structures_field('roiNumber', RTSTRUCT, js, strobj);
                                    end                                    
                                end

                            end

                        end                        
                        
                        DVH_items = fieldnames(dvhsequence);
                        for i = 1:length(DVH_items)
                            for j = 1:length(names)
                                dataS(dvhsAdded+1).(names{j}) = populate_planC_DVH_field(names{j}, RTDOSE(doseNum), doseobj, rtPlans);
                            end
                            
                            dataS(dvhsAdded+1).volumeType = dvhsequence.(['Item_',num2str(i)]).DVHType;                                                        
                            dataS(dvhsAdded+1).doseType = dvhsequence.(['Item_',num2str(i)]).DoseType; 
                            dataS(dvhsAdded+1).doseUnits = dvhsequence.(['Item_',num2str(i)]).DoseUnits; 
                            structureNumber = dvhsequence.(['Item_',num2str(i)]).DVHReferencedROISequence.Item_1.ReferencedROINumber;
                            indROINumber = find(structureNumberV==structureNumber);
                            dataS(dvhsAdded+1).structureName = structureNameC{indROINumber};
                            dataS(dvhsAdded+1).doseScale = dvhsequence.(['Item_',num2str(i)]).DVHDoseScaling;
                            binWidthsV = dvhsequence.(['Item_',num2str(i)]).DVHData(1:2:end);
                            %maxDVHDose = dvhsequence.(['Item_',num2str(i)]).DVHMaximumDose;
                            %minDVHDose = dvhsequence.(['Item_',num2str(i)]).DVHMinimumDose;
                            doseBinsV = [];
                            doseBinsV(1) = 0;
                            for iBin = 2:length(binWidthsV)
                                doseBinsV(iBin) = doseBinsV(iBin-1) + binWidthsV(iBin);
                            end                                                          
                            dataS(dvhsAdded+1).DVHMatrix(:,1) = doseBinsV(:);
                            if strcmpi(dataS(dvhsAdded+1).volumeType,'cumulative')
                                 volumeBinsV = dvhsequence.(['Item_',num2str(i)]).DVHData(2:2:end);
                                 volumeBinsV = diff(volumeBinsV(1)-volumeBinsV);
                                 volumeBinsV = [volumeBinsV(1); volumeBinsV(:)];
                            else
                                volumeBinsV = dvhsequence.(['Item_',num2str(i)]).DVHData(2:2:end);
                                volumeBinsV = volumeBinsV(:);
                            end
                            dataS(dvhsAdded+1).DVHMatrix(:,2) = volumeBinsV;                            
                            dvhsAdded = dvhsAdded + 1;
                        end
                        
                    end
                end
            end
            
        end
                
                
        %     case 'digitalFilm'
        %         populate_planC_digitalFilm_field(fieldName, dcmdir);
        %     case 'RTTreatment'
        %         populate_planC_RTTreatment_field(fieldName, dcmdir);
        %     case 'IM'
        %         populate_planC_IM_field(fieldName, dcmdir);
        
    case 'beams'
        [seriesC, typeC] = extract_all_series(dcmdir_patient);
        %%%DK Re-writing RTPLAN file to not use MATLAB image processing
        %%%tool.
        
        seriesNum = strmatch('RTPLAN', typeC);
        
        planCount = 0;
        
        for j = 1:length(seriesNum)
            RTPLAN = seriesC{seriesNum(j)}.Data;
            
            for planNum = 1:length(RTPLAN)
                
                planCount = planCount + 1;

                planobj  = scanfile_mldcm(RTPLAN(planNum).file);

                %Populate each field in the dose structure.
                for i = 1:length(names)
                    dataS(planCount).(names{i}) = populate_planC_beams_field(names{i}, RTPLAN(planNum), planobj);
                end

            end

        end
        rtPlans= dataS;
        
    case 'beamGeometry'
        
        dataS = initializeCERR('beamGeometry');
        
        for i = 1:length(rtPlans)
            test = populate_planC_beamGeometry_field(rtPlans(i), dataS);
            
            for j = 1:length(test)
                dataS = dissimilarInsert(dataS, test(j), length(dataS)+1);
            end
        end
        
        %%%OLD RTPLAN import code. commented DK 
        % %         %Place RTPLAN into planC{indexS.beams}
        % %         plansAdded = 0;
        % %         for seriesNum = 1:length(seriesC)
        % %             RTPLAN = seriesC{seriesNum}.Data;
        % %             for planNum =  1:length(RTPLAN)
        % %
        % %                 if strcmpi(typeC{seriesNum}, 'RTPLAN')
        % %
        % %                     try
        % %                         if plansAdded == 0m
        % %                             dataS =
        % dicominfo(seriesC{seriesNum}.Data(planNum).file);
        % %                         else
        % %                             dataS(plansAdded + 1) = dicominfo(seriesC{seriesNum}.Data(planNum).file);
        % %                         end
        % %                         plansAdded = plansAdded + 1;
        % %                         warning('Matlab''s Image Processing Toolbox was used to read RTPLAN...')
        % %                     catch
        % %                         warning('Matlab''s Image Processing Toolbox is required to read RTPLAN. Ignoring...')
        % %                     end
        % %
        % %                 end
        % %
        % %             end
        % %         end
        
    case 'importLog'
        %Implementation is unnecessary.
        
    case 'CERROptions'
        dataS = CERROptions;
        
    case 'indexS'
        %Implementation is unnecessary.
        
    otherwise
        % disp(['DICOM Import has no methods defined for import into the planC{indexS.' cellName '} structure, leaving empty.']);
end
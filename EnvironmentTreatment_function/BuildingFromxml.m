%%
%BulidingFromxml
function [tBuilding]=BuildingFromxml(filename)

%  extract data
Dom=xmlread(filename);
BuildingArray= Dom.getElementsByTagName('tBuilding');  %
tBuilding.IndexBuliding=BuildingArray.getLength;
FaceArray= Dom.getElementsByTagName('tFace');  %
BuildIdArray=strings;
for i = 0 : FaceArray.getLength-1
    tBuilding.tFace(i+1,:).IndexFace=i+1;
    thisItem = FaceArray.item(i);  %
    %     FDsAttributes = char(thisItem.getAttributes.item(0).getValue)
    childNode = thisItem.getFirstChild;
    
    while ~isempty(childNode)
        if childNode.getNodeType == childNode.ELEMENT_NODE 
            childNodeNm= char(childNode.getTagName);
            if  strcmp('fPointPos',childNodeNm)
                fPointPos = char(childNode.getFirstChild.getData);
                fPointPos=str2num(fPointPos);
                fPointPos=round(fPointPos,3);
                tBuilding.tFace(i+1,1).fPointPos=fPointPos;
            elseif strcmp('material',childNodeNm)
                material = char(childNode.getFirstChild.getData);
                %material = str2num(char(childNode.getFirstChild.getData));
                tBuilding.tFace(i+1,1).material=material;
            elseif strcmp('thickness',childNodeNm)
                thickness = str2num(char(childNode.getFirstChild.getData));
                tBuilding.tFace(i+1,1).thickness=thickness;
            elseif strcmp('objectId',childNodeNm)
                objectId = char(childNode.getFirstChild.getData);
                tBuilding.tFace(i+1,1).objectId=objectId;
            elseif strcmp('buildingId',childNodeNm)
                buildingId = char(childNode.getFirstChild.getData);
                tBuilding.tFace(i+1,1).buildingId=buildingId;
                if ~ismember(buildingId,BuildIdArray)
                    BuildIdArray(end+1)=buildingId;
                end
            elseif strcmp('ifscatting',childNodeNm)
                ifscatting=char(childNode.getFirstChild.getData);
                tBuilding.tFace(i+1,1).ifscatting=str2double(ifscatting);
            elseif strcmp('S',childNodeNm)
                S=char(childNode.getFirstChild.getData);
                tBuilding.tFace(i+1,1).S=str2double(S);
            elseif strcmp('alpha_R',childNodeNm)
                alpha_R=char(childNode.getFirstChild.getData);
                tBuilding.tFace(i+1,1).alpha_R=str2double(alpha_R);
            elseif strcmp('model_type',childNodeNm)
                model_type=char(childNode.getFirstChild.getData);
                tBuilding.tFace(i+1,1).model_type=str2double(model_type);
            end
        end  % End IF
        childNode = childNode.getNextSibling;
    end  % End WHILE
    
end
disp('ok')

function [faceDataSort,sortedIndices] = GetFaceData(sourcePoint,aPoint,FaceEquation,FaceCoordinates,FaceNum,Tx)
faceDataSort = [];
sortedIndices = [];
for indexFace=1:FaceNum
    faceCrossData(indexFace)=struct('validFace',[],'faceNum',[],'validPoint',[],'distance',[],'crossFace',[]);
 pointCross = CrosspointLineFace(sourcePoint ,aPoint,...
                        FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                    if (CpInFace2(pointCross,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))%相交测试
                        %同时要有方向性问题，先判断面是否在两个点的中间
                 
                        point2soure=sourcePoint -pointCross;point2apoint=aPoint-pointCross;
                        point2soure=point2soure./sqrt(sum(point2soure.^2,2));%归一化一下
                        point2apoint=point2apoint./sqrt(sum(point2apoint.^2,2));%归一化一下
                        if (dot(point2soure,point2apoint)+1)<0.1 && (dot(point2soure,point2apoint)+1)>-0.1
                            %此时面在两个点中间
                            faceCrossData(indexFace).validFace=FaceEquation(indexFace,:);%保证validFace和distance大小相同，编号对应
                            faceCrossData(indexFace).faceNum=indexFace;
                            faceCrossData(indexFace).validPoint= pointCross;
                            faceCrossData(indexFace).distance=norm(Tx-pointCross);
                            faceCrossData(indexFace).crossFace=indexFace;
                        elseif (dot(point2soure,point2apoint)-1)<0.1 && (dot(point2soure,point2apoint)-1)>-0.1
                            %此时面在两个点的旁边，需要判断在那一边
                            if sqrt(sum((sourcePoint -pointCross).^2,2))>sqrt(sum((aPoint-pointCross).^2,2))
                                faceCrossData(indexFace).validFace=FaceEquation(indexFace,:);
                                faceCrossData(indexFace).faceNum=indexFace;
                                faceCrossData(indexFace).validPoint= pointCross;
                                faceCrossData(indexFace).distance=norm(Tx-pointCross);
                                faceCrossData(indexFace).crossFace=indexFace;
                            end

                        end

                        % 保留非空元素
                        %删除distance为0的数据
                        distanceThreshold = 0.01;
                        distances = [faceCrossData.distance];
                        rowsToRemove = distances < distanceThreshold;
                        faceCrossData(rowsToRemove) = [];
                        isEmptyElement = arrayfun(@(x)  isempty(x.validPoint) && isempty(x.distance) && isempty(x.faceNum), faceCrossData);
                        filteredFaceCrossData = faceCrossData(~isEmptyElement);
                        distances = [filteredFaceCrossData.distance];

                        % 根据 distance 进行从小到大排序并获取排序后的索引
                        [~,sortedIndices] = sort(distances);
                       
                        % 使用排序后的索引来重新排列结构体数组
                        faceDataSort = filteredFaceCrossData(sortedIndices);%储存第n条射线符合要求的相交面方程，交点，面的参数，距离
                       
                     
                        %按照距离从小到大排序
                    end
                  
end          
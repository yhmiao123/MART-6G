function visable_Faceindex = test_2D_1(Tx, FaceNum, FaceCoordinates, FaceEquation)
%传入起始点，面的个数，每个面的坐标
%%调试用的
%V1版本更正了Tx在屋顶时可见面失效的情况
%先找出在二维坐标系下Tx的可见范围
point = [];
All_segment=[];
%考虑的比较简单，直接将Z坐标变为0进行画图
for jj = 1:FaceNum
    coordinates = FaceCoordinates(jj).Face(:,1:2);
    unique_coordinates = coordinates;
        for kk = 1:size(unique_coordinates,1)
            segment(kk,:) = [unique_coordinates(kk,:),unique_coordinates(mod(kk, size(unique_coordinates, 1)) + 1, :)];%存储线段的端点值
        end
    All_segment = [All_segment;segment];
    point = [point;unique_coordinates];
end
%为了找出重复的线段，将其删去
All_segment = unique(All_segment,'row');
rowsToDelete = false(size(All_segment, 1), 1);
for ii = 1:size(All_segment,1)
    judge1 = isequal(All_segment(ii,1),All_segment(ii,3));
    judge2 = isequal(All_segment(ii,2),All_segment(ii,4));
    if (judge1 &&judge2)
        rowsToDelete(ii) = true;
    end
end
All_segment = All_segment(~rowsToDelete, :);
point = unique(point,'row');
% 下面是画图代码
figure;
for n = 1:size(All_segment,1)
    x1=All_segment(n,1);
    y1=All_segment(n,2);
    x2=All_segment(n,3);
    y2=All_segment(n,4);
    plot([x1,x2],[y1,y2],'b','linewidth',1);
    hold on;
end

%判断起点是否在建筑物上
TxOnBuilding = 0;
testpoint = [Tx(1,1:2), 0];
for indexFace = 1:FaceNum%逐面判断是否有穿透点
    if(roundn((FaceEquation(indexFace,1)*Tx(1,1)+FaceEquation(indexFace,2)*Tx(1,2)+FaceEquation(indexFace,3)*Tx(1,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*testpoint(1,1)+FaceEquation(indexFace,2)*testpoint(1,2)+FaceEquation(indexFace,3)*testpoint(1,3)+FaceEquation(indexFace,4)),-2) <0)
        pointPene = CrosspointLineFace(Tx(1,:),testpoint(1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
    %Judge Crosspoint in Face 如果交点在该面上
        if (CpInFace2(pointPene,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
            PeneFaceIndex = indexFace;
            TxOnBuilding = 1;
            break
        end
    end
end

if (TxOnBuilding == 1)
% 计算距离矩阵
startpoint = Tx(1,1:2);
coordinates = FaceCoordinates(PeneFaceIndex).Face(:,1:2);
unique_coordinates = coordinates;
for kk = 1:size(unique_coordinates,1)
    target_segment(kk,:) = [unique_coordinates(kk,:),unique_coordinates(mod(kk, size(unique_coordinates, 1)) + 1, :)];%存储线段的端点
end
points = [];
intersectionPoints = [];
%下面是判断起点与每个端点的连线是否有交点，如果有，求出交点，并返回离起点最近的交点坐标。如果没有，则返回的是该端点坐标
for k = 1:size(point,1)
    segments = struct('startPoint',[],'endPoint',[]); 
    segments.startPoint = startpoint(1,:);
    segments.endPoint = point(k,:);
    intersectionPoint = [];
    count = 0;
    dis=[];
    for i = 1:length(All_segment)
        othersegment = struct('startPoint',[],'endPoint',[]);
        othersegment.startPoint = All_segment(i,1:2);
        othersegment.endPoint = All_segment(i,3:4);
        intersection = [];
        intersection = calculateLineSegmentsIntersection(segments, othersegment);
        if ~isempty(intersection)
            logical1 = isPointOnSegment(othersegment, intersection);%判断点是否在线段上
            logical2 = isPointOnSegment(segments, intersection);%判断点是否在另一条线段上
            logical3 = 1;
            for j = 1:size(point,1)
                if isequal(intersection,point(j,:))%判断交点是否是端点
                    logical3 = 0;
                    break
                end
            end
            if logical1 && logical2 && logical3
                intersectionPoint = [intersectionPoint;intersection];
            end
        end
    end
    intersectionPoint = unique(intersectionPoint,'row');
    count = size(intersectionPoint, 1);
    if (count >= 1)%如果交点不止一个，需要求出离起点最近的交点
        for kk = 1:count
            logical = 0;
            intersection = intersectionPoint(kk,:);
            for jj = 1:size(target_segment,1)
                othersegment.startPoint = target_segment(jj,1:2);
                othersegment.endPoint = target_segment(jj,3:4);
                logical = isPointOnSegment(othersegment, intersection);%判断点是否在线段上
                if logical == 1
                    break
                end
            end
            if logical == 1
                break
            end
        end
        for ll = 1:count
             dis(ll) = (intersectionPoint(ll,1)-startpoint(1,1))^2+(intersectionPoint(ll,2)-startpoint(1,2))^2;
        end
        if logical == 1
            [~, min_index] = min(dis);
            dis(min_index) = Inf;
            mindis = min(dis);
        else
            mindis = min(dis);
        end
        index = find(dis == mindis, 1);
        intersectionPoint1 =intersectionPoint(index,:);
        intersectionPoint = intersectionPoint1;
    end
    if isempty(intersectionPoint)
         points = [points;point(k,:)];
    else
        intersectionPoints = [intersectionPoints;intersectionPoint];
    end
end
%下面是为了避免重复的点出现
points = unique(points,'row');
intersectionPoints = unique(intersectionPoints,'row');
All_points = [points;intersectionPoints];

else
% 起点坐标
startpoint = Tx(1,1:2);
points = [];
intersectionPoints = [];
%下面是判断起点与每个端点的连线是否有交点，如果有，求出交点，并返回离起点最近的交点坐标。如果没有，则返回的是该端点坐标
for k = 1:size(point,1)
    segments = struct('startPoint',[],'endPoint',[]); 
    segments.startPoint = startpoint(1,:);
    segments.endPoint = point(k,:);
    intersectionPoint = [];
    count = 0;
    dis=[];
    for i = 1:length(All_segment)
        othersegment = struct('startPoint',[],'endPoint',[]);
        othersegment.startPoint = All_segment(i,1:2);
        othersegment.endPoint = All_segment(i,3:4);
        intersection = [];
        intersection = calculateLineSegmentsIntersection(segments, othersegment);
        if ~isempty(intersection)
            logical1 = isPointOnSegment(othersegment, intersection);%判断点是否在线段上
            logical2 = isPointOnSegment(segments, intersection);%判断点是否在另一条线段上
            logical3 = 1;
            for j = 1:size(point,1)
                if isequal(intersection,point(j,:))%判断交点是否是端点
                    logical3 = 0;
                    break
                end
            end
            if logical1 && logical2 && logical3
                intersectionPoint = [intersectionPoint;intersection];
            end
        end
    end
    intersectionPoint = unique(intersectionPoint,'row');
    count = size(intersectionPoint, 1);
    if (count>1)%如果交点不止一个，需要求出离起点最近的交点
        for ll = 1:count
             dis(ll) = (intersectionPoint(ll,1)-startpoint(1,1))^2+(intersectionPoint(ll,2)-startpoint(1,2))^2;
        end
        mindis = min(dis);
        index = find(dis == mindis, 1);
        intersectionPoint1 =intersectionPoint(index,:);
        intersectionPoint = intersectionPoint1;
    end
    if isempty(intersectionPoint)
         points = [points;point(k,:)];
    else
        intersectionPoints = [intersectionPoints;intersectionPoint];
    end
end
%下面是为了避免重复的点出现
points = unique(points,'row');
intersectionPoints = unique(intersectionPoints,'row');
All_points = [points;intersectionPoints];
end
%按角度对点进行排序（逆时针）
angles = atan2(All_points(:, 2) - startpoint(2), All_points(:, 1) - startpoint(1));
[sortedAngles, sortOrder] = sort(angles);%逆时针
% 获取排序后的点坐标
All_sorted_points = All_points(sortOrder, :);
%下面画图是画出起点与端点，或离起点最近交点的连线
for m = 1:size(All_points,1)
    plot([startpoint(1,1),All_points(m,1)],[startpoint(1,2),All_points(m,2)],'r','linewidth',1);
    hold on
end
hold off
figure;
for l = 1:size(All_sorted_points, 1)-1
    plot([All_sorted_points(l, 1), All_sorted_points(l+1, 1)], [All_sorted_points(l, 2),All_sorted_points(l+1, 2)], 'r','linewidth',1);
    hold on
end
plot([All_sorted_points(end, 1), All_sorted_points(1, 1)], [All_sorted_points(end, 2), All_sorted_points(1, 2)], 'r','linewidth',1);
hold off

%%
%每个面逐一判断是否在可见区域内或者上，生成可见面的索引  
visable_Faceindex = [];
disable_Faceindex = [];
for i = 1:FaceNum
    vertexs = FaceCoordinates(i).Face(:,1:2);
    judge = [];
    for j = 1:size(vertexs,1)
        in = inpolygon(vertexs(j,1), vertexs(j,2), All_sorted_points(:,1), All_sorted_points(:,2));%判断点是否在区域内
        on = isPointOnBoundary(vertexs(j,1), vertexs(j,2), All_sorted_points);%判断点是否在边界线上
        if in || on 
            judge(j) = 1;
        else
            judge(j) = 0;
        end
    end
    %if all(judge(1,:) == 1)
    if any(judge(1,:) == 1)%只要有一个点满足条件，就将该面是为可见的
        visable_Faceindex = [visable_Faceindex; i];
    end
end

%为了避免出现面找的太少这种情况，所以交点所在的面也判断为可见面
index = [];
for i = 1:size(intersectionPoints,1)
    for j = 1:length(All_segment)
        judge = 0;
        othersegment = struct('startPoint',[],'endPoint',[]);
        othersegment.startPoint = All_segment(j,1:2);
        othersegment.endPoint = All_segment(j,3:4);
        intersection = intersectionPoints(i,:);
        judge = isPointOnSegment(othersegment, intersection);%判断点是否在线段上
        if judge == 1
            segment1 = [All_segment(j,1:2);All_segment(j,3:4)];
            for k = 1:FaceNum
                judge1 = 0; judge2 = 0;
                vertexs = FaceCoordinates(k).Face(:,1:2);
                for m = 1:size(vertexs,1)
                    if (segment1(1,:) == vertexs(m,:)) 
                        judge1 = 1;
                    end
                end
                for n = 1:size(vertexs,1)
                    if (segment1(2,:) == vertexs(n,:)) 
                        judge2 = 1;
                    end
                end
                if (judge1 == 1) && (judge2 == 1)
                    index = [index;k];
                end
            end
        end
    end
end
index = unique(index,'row');
visable_Faceindex = [visable_Faceindex;index];
end


%         tolerance = 1e-2;
%         ground_vector = [0,0,1];
%         visable_index1 = [];
%         for ii = 1:FaceNum
%             if ((abs((dot(FaceEquation(ii,1:3),ground_vector))-1))<tolerance)
%                 visable_index1 = [visable_index1;ii]; 
%             end
%         end
%         Visable_Faceindex = [visable_Faceindex;visable_index1];
%         Visable_Faceindex = unique(Visable_Faceindex,'row');
        
function [crossPoint, crossFace, t] = IntersectAll(ray, face)

t = inf; %初始化射线相交最短时间
crossPoint = []; %初始化交点
crossFace = 0; %初始化交点平面

faceCount = size(face,2);
for i = 1:faceCount %遍历所有平面

    [crossPoint0, t0] = IntersectFace(ray, face(i)); %相交测试，可能不相交

    if t0 < t %若相交且为当前最短相交时间
        t = t0; %更新最短相交时间
        crossFace = i; %更新相交平面索引
        crossPoint = crossPoint0; %更新交点坐标

    end

end
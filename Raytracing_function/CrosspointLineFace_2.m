function [crossPoint, t] = CrosspointLineFace_2(startPoint, direction, normalVector, pointOnFace)
%输入：射线的起点、方向向量；平面的法向量、面上一点
%输出：交点坐标，相交时间

vpt = dot(direction, normalVector);
if vpt == 0 %射线与平面平行
    t = inf;
    crossPoint = [inf, inf, inf];
else
    t = dot(pointOnFace - startPoint, normalVector) / vpt;
    crossPoint = startPoint + direction * t;
    if t <= 0 %射线反向与平面相交，或射线起点在平面上
        t = inf;
        crossPoint = [inf, inf, inf];
    end
end

end
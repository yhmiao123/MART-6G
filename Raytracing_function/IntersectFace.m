function [crossPoint, t] = IntersectFace(ray, face)
%射线与多边形平面进行相交测试

%射线与平面的交点
[crossPoint, t] = CrosspointLineFace_2(ray.startPoint, ray.direction, face.normalVector, face.coordinate(1,:));

if t ~= inf %若射线不与平面平行
    %判断交点是否在多边形内部
    if ~CpInFace1(crossPoint, face.coordinate) %交点不在内部
        t = inf;
        crossPoint = [];
    end

else %射线与平面平行
    crossPoint = [];
end

end
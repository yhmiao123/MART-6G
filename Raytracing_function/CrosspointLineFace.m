%The crosspoint of line and face线与面的交点


function [r] = CrosspointLineFace(a,b,F,InitialF)%A coordinate,B coordinate,Face Direction Vector,A point's coordinate from face
%A坐标，B坐标，面方向向量，A点到面的坐标（面的一个点）
vpt = (a(1,1)-b(1,1)) * F(1,1) + (a(1,2)-b(1,2)) * F(1,2) + (a(1,3)-b(1,3)) * F(1,3);
Result = [];
t = ((InitialF(1,1) - a(1,1)) * F(1,1) + (InitialF(1,2) - a(1,2)) * F(1,2) + (InitialF(1,3) - a(1,3)) *F(1,3))./ vpt;
Result(1) = a(1,1) + (a(1,1)-b(1,1)) * t;
Result(2) = a(1,2) + (a(1,2)-b(1,2)) * t;
Result(3) = a(1,3) + (a(1,3)-b(1,3)) * t;
r = [Result(1),Result(2),Result(3)];%ReflectionPoint反射点
r = roundn(r,-4);%Avoid the problem because of operating precision of MATLAB!!!!!!!

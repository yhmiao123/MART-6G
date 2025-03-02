function [Verpoint] = VerpointOfLine(begPoint,EndPoint,Rx)
%VERPOINTOFLINE 此处显示有关此函数的摘要
%   输入线段的起始点、终止点、直线外的一点;
dx=begPoint(1)-EndPoint(1);
dy=begPoint(2)-EndPoint(2);
dz=begPoint(3)-EndPoint(3);
u=(Rx(1)-begPoint(1))*(begPoint(1)-EndPoint(1))+(Rx(2)-begPoint(2))*(begPoint(2)-EndPoint(2))+(Rx(3)-begPoint(3))*(begPoint(3)-EndPoint(3));
u=u/(dx^2+dy^2+dz^2);
Verpoint=[begPoint(1)+u*dx,begPoint(2)+u*dy,begPoint(3)+u*dz];
end


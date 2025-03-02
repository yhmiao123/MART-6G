%Judge point in Face  判断点是否在面内，减少CpInFace调用roundn次数
function logical = CpInFace1(r,Face,P)
%交点坐标，面的参数方程，面上所有点的坐标
% P = [0,0,0;11,0,0;11,6.60000000000000,0;0,6.60000000000000,0];
% r = [6.685000000000001,3.260000000000000,0];
% Face = [0,0,1,0];
m = P(1,1:3) - r;
s = Face(1,1:3);
judge1 = dot(m,s);%可能会有误差
min1 = min(P(:,1));
min2 = min(P(:,2));
min3 = min(P(:,3));
max1 = max(P(:,1));
max2 = max(P(:,2));
max3 = max(P(:,3));
judge3 = 0;
l1 = min1<=r(1,1) && r(1,1)<=max1;
l2 = min2<=r(1,2) && r(1,2)<=max2;
l3 = min3<=r(1,3) && r(1,3)<=max3;
if (l1 && l2 && l3)
    judge3 = 1;
end
if ((abs(judge1)<=1e-3)&&(judge3==1))
    logical = 1;
else
    logical = 0;
end
end






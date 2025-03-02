function [logical,on_edge] = CpInFace2(r,Face,P)
%交点坐标，面的参数方程，面上边界点的坐标
%返回：logical：点是否在面上；on_edge：点是否在面的棱边缘上
%先判断点是否在面上：
judge1= r(1)*Face(1)+r(2)*Face(2)+r(3)*Face(3)+Face(4) <1e-3;

%再判断是否在封闭区域内：
x_points = P(:, 1);
y_points = P(:, 2);
z_points = P(:, 3);

% 定义两个面上的基向量 v1 和 v2
N=size(P,1);
v1 = P(1,:)-P(2,:);
v2 = P(1,:)-P(N,:);

% 检查基向量是否共线
if norm(cross(v1, v2)) < 1e-5
    v1 = P(1,:)-P(2,:);
    v2 = P(1,:)-P(N-1,:);
end

% 将封闭区域的点转换到局部坐标系中
proj_points = arrayfun(@(x, y, z) [dot([x y z], v1), dot([x y z], v2)], x_points, y_points, z_points, 'UniformOutput', false);
proj_points = cell2mat(proj_points);

% 将点A转换到局部坐标系中
proj_A = [dot([r(1) r(2) r(3)], v1), dot([r(1) r(2) r(3)], v2)];

% 使用 inpolygon 函数判断点A是否在封闭区域内
[judge2,on_edge] = inpolygon(proj_A(1), proj_A(2), proj_points(:,1), proj_points(:,2));

if judge1 && judge2
    logical = 1;
else
    logical = 0;
end








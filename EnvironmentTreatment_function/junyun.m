function points = junyun

% 定义x和y的范围
x = -600:10:600;
y = -400:10:400;

% 创建网格
[X, Y] = meshgrid(x, y);

% 定义z坐标
Z = ones(size(X)) * 1.5;

% 将三维坐标存储在一个数组中
points = [X(:), Y(:), Z(:)];

end


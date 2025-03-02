function coordinates= line_equation(point1, point2)
    % point1 和 point2 分别是两个点的坐标，每个点是一个长度为2的向量 [x, y]
    
    % 从点中提取坐标
    x1 = point1(1);
    y1 = point1(2);
    x2 = point2(1);
    y2 = point2(2);
    
    % 计算直线方程的系数
    A = y2 - y1;
    B = x1 - x2;
    C = x2 * y1 - x1 * y2;
    coordinates=[A,B,C];
end

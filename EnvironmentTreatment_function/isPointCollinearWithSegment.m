function isCollinear = isPointCollinearWithSegment(point, segment)
    % point是一个1x3的向量，表示三维空间中的一个点，例如[px py pz]
    % segment是一个1x6的向量，表示三维线段的两个端点坐标，例如[x1 y1 z1 x2 y2 z2]

    % 提取点的坐标
    px = point(1);
    py = point(2);
    pz = point(3);

    % 提取线段端点坐标
    x1 = segment(1);
    y1 = segment(2);
    z1 = segment(3);
    x2 = segment(4);
    y2 = segment(5);
    z2 = segment(6);

    % 计算向量AP和AB
    AP = [px - x1, py - y1, pz - z1];
    AB = [x2 - x1, y2 - y1, z2 - z1];

    % 计算叉积
    crossProduct = cross(AP, AB);

    % 判断叉积的模长是否接近零（考虑浮点数精度）
    isCollinear = norm(crossProduct) < 1e-4;
end


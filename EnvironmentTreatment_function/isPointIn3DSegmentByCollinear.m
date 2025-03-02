function isPointOnSegment = isPointIn3DSegmentByCollinear(point, segment)
    isCollinear = isPointCollinearWithSegment(point, segment);
    if ~isCollinear
        isPointOnSegment = false;
        return;
    end

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

    % 判断点的坐标是否在线段端点坐标范围内
    isXInRange = (px >= min(x1,x2)) && (px <= max(x1,x2));
    isYInRange = (py >= min(y1,y2)) && (py <= max(y1,y2));
    isZInRange = (pz >= min(z1,z2)) && (pz <= max(z1,z2));

    isPointOnSegment = isXInRange && isYInRange && isZInRange;
end


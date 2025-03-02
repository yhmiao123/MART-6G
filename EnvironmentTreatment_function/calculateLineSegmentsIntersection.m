function intersection = calculateLineSegmentsIntersection(segment1, segment2)%计算两个线段的交点
% 定义线段的端点
    p1 = segment1.startPoint;
    q1 = segment1.endPoint;
    p2 = segment2.startPoint;
    q2 = segment2.endPoint;
    % 计算方向向量
    r = q1 - p1;
    s = q2 - p2;
    % 叉乘
    d = crossProduct(r, s); 
    % 如果d为0，线段平行或共线
    if d == 0
        intersection = [];
        return;
    end 
    % 交点参数
    t = crossProduct(q2 - p1, s) / d;
    u = crossProduct(r, q2 - p1) / d; 
    % 交点
    intersection = p1 + t * r;
    % 如果交点在两线段的范围内
    if (0 <= t && t <= 1) && (0 <= u && u <= 1)
        intersection = roundn(intersection,-3);
    else
        intersection = []; % 交点不在两线段的范围内
    end
 end
function c = crossProduct(a, b)
    c = a(1) * b(2) - a(2) * b(1);
end
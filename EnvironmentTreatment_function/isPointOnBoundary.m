function isOnBoundary = isPointOnBoundary(x, y, regionBoundary)%判断点是否在边界线上
    threshold = 1e-5;%点是否接近边界线的阈值
    point = [x,y];
    for i = 1:size(regionBoundary, 1)%看多边形每两个点之间的线段与point的关系
        p1 = regionBoundary(i, :);
        p2 = regionBoundary(mod(i, size(regionBoundary, 1)) + 1, :);
        l1 = p2 - p1;
        l2 = point - p1;
        judge = l1(1) * l2(2) - l1(2) * l2(1);
        if abs(judge) < threshold%点是否在线段上
            dotProduct = dot(l2, l1);
            AB_squared = dot(l1, l1); 
            if (dotProduct >= 0) && (dotProduct <= AB_squared)
                 isOnBoundary = true;
                 break;
            else
                 isOnBoundary = false;
            end
        else
             isOnBoundary = false;
        end
     end 
end



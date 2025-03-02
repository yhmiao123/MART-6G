function onSegment = isPointOnSegment(lineSegment, point)
%判断点是否在线段上
   xmin = min(lineSegment.startPoint(1), lineSegment.endPoint(1));
   xmax = max(lineSegment.startPoint(1), lineSegment.endPoint(1));
   ymin = min(lineSegment.startPoint(2), lineSegment.endPoint(2));
   ymax = max(lineSegment.startPoint(2), lineSegment.endPoint(2));
   if (point(1) >= xmin)&&(point(1) <= xmax)&&(point(2) >= ymin)&& (point(2) <= ymax)
       onSegment = 1;
   else
       onSegment = 0;
end
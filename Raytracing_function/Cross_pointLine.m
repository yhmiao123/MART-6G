function  pointCross  = Cross_pointLine(A,B,C,D)


  % 判断线段AB和CD是否相交
    
    % 确保A在左边，B在右边
    if A(1) > B(1)
        temp = A;
        A = B;
        B = temp;
    end
    
    % 确保C在左边，D在右边
    if C(1) > D(1)
        temp = C;
        C = D;
        D = temp;
    end
    
   
    
    % 计算AB和CD的斜率
    slope_AB = (B(2) - A(2)) / (B(1) - A(1));
    slope_CD = (D(2) - C(2)) / (D(1) - C(1));
    
    % 如果AB和CD平行
    if abs(slope_AB - slope_CD) < eps
      
         pointCross = NaN;
        return;
    end
    
    % 计算交点的x坐标
    if isinf(slope_CD)
    x_intersection=C(1);

    else
    x_intersection = (slope_AB * A(1) - A(2) - slope_CD * C(1) + C(2)) / (slope_AB - slope_CD);
    end
    % 如果交点不在AB和CD之间
    

    % 计算交点的y坐标
    y_intersection = slope_AB * (x_intersection - A(1)) + A(2);
    
   

    intersection_point= [x_intersection, y_intersection];
        pointCross= intersection_point;

    
   
end
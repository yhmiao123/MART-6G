function M = line3D_intersection(A, D, E, F)
    % 初始化交点M为空
    M = zeros(1,3);
    
    % 计算线段AD和EF的方向向量
    AD = D - A;AD_normal=bsxfun(@rdivide,AD,sqrt(sum(AD.^2,2)));
    EF = F - E;EF_normal=bsxfun(@rdivide,EF,sqrt(sum(EF.^2,2)));
    
    % 计算线段AD和EF的法向量
    N = cross(AD, EF);
    
    % 判断两线段是否共面
    if abs(dot((E - A), N)) < 0.1
        % 利用线性方程组求解
        MatrixA=[AD(1),-EF(1);AD(2),-EF(2);AD(3),-EF(3);];
        b=[E(1)-A(1);E(2)-A(2);E(3)-A(3)];
        t=MatrixA\b;
        if t(1)<1&& t(1)>0 && t(2)<1&& t(2)>0
            M1=A+AD.*t(1);M2=E+EF.*t(2);
            if abs(M1-M2)<[1e-2,1e-2,1e-2]
                M=roundn(M1,-4);
            end
        end
    end
end

function [alpha1,alpha2] = solve_equations(point_Intsect,Tx,Rx)
                        syms alpha1 alpha2;%用来判断绕射点的位置
                        point_Pro=[];%存储投影点
                        PointDif_sym = sym(zeros(2,3)); % 初始化为零矩阵（符号矩阵）
                        PointDif_sym(1,:) = point_Intsect(1,:) + alpha1*(point_Intsect(2,:) - point_Intsect(1,:));
                        PointDif_sym(2,:) = point_Intsect(3,:) + alpha2*(point_Intsect(4,:) - point_Intsect(3,:));
                        %求起点和第二个绕射点到棱1的投影
                        p1 = point_Intsect(2,:) - point_Intsect(1,:);
                        p2 = Tx - PointDif_sym(1,:);
                        p3 = PointDif_sym(2,:) - PointDif_sym(1,:);
                        a1 = dot(p1,p2) / (norm(p1)*norm(p2));
                        a2 = dot(p1,p3) / (norm(p1)*norm(p3));
                        %求终点和第一个绕射点到棱2的投影
                        p4 = point_Intsect(4,:) - point_Intsect(3,:);
                        p5 = Rx - PointDif_sym(2,:);
                        a3 = dot(p4,p3) / (norm(p3)*norm(p4));
                        a4 = dot(p4,p5) / (norm(p4)*norm(p5));
                        %利用相似三角形的角度关系和边的关系分别列出两个方程，并解方程
                        p1 = point_Intsect(2,:) - point_Intsect(1,:);
                        pt1 = Tx-point_Intsect(1,:);
                        t1 = dot(pt1,p1)/dot(p1,p1);
                        point_Pro(1,:) = point_Intsect(1,:)+t1*p1;
                        pt2 = PointDif_sym(2,:)-point_Intsect(1,:); 
                        t2 = dot(pt2,p1)/dot(p1,p1);
                        point_Pro1 = @(alpha1, alpha2)point_Intsect(1,:)+t2*p1;
                        p2 = point_Intsect(4,:) - point_Intsect(3,:);
                        pt3 = Rx-point_Intsect(3,:);
                        t3 = dot(pt3,p2)/dot(p2,p2);
                        point_Pro(3,:) = point_Intsect(3,:)+t3*p2;
                        pt4 = PointDif_sym(1,:)-point_Intsect(3,:);
                        t4 = dot(pt4,p2)/dot(p2,p2);
                        point_Pro2 = @(alpha1, alpha2) point_Intsect(3,:)+t4*p2;
                        b1 = norm((Tx-point_Pro(1,:)))/norm((PointDif_sym(2,:)-point_Pro1));
                        b2 = norm((Tx-PointDif_sym(1,:)))/norm((PointDif_sym(2,:)-PointDif_sym(1,:)));
                        b3 = norm((PointDif_sym(2,:)-PointDif_sym(1,:)))/norm((PointDif_sym(2,:)-Rx));
                        b4 = norm((PointDif_sym(1,:)-point_Pro2))/norm((Rx-point_Pro(3,:)));
                        F_sym =@(alpha1,alpha2) abs(a1) - abs(a2) + abs(a3) - abs(a4) == 0;%角度关系方程
                        G_sym =@(alpha1,alpha2) b1 - b2 + b3 - b4 == 0;%对应边关系的方程
                        equations = [sym(F_sym), sym(G_sym)];
                        [sol_1,sol_2] = vpasolve(equations, [alpha1,alpha2]);%使用vpasolve解方程
                        alpha1 = double(sol_1);   %将结果转换成double类型，否则下面没法计算
                        alpha2 = double(sol_2);
end

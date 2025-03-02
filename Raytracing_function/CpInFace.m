%Judge point in Face  判断点是否在面上
function logical = CpInFace(r,Face)
k = size(Face(:,:),1);%Avoid selecting 2 vectors in face are in a line
Vector = cross ( Face(1,:) - Face(k-1,:) , Face(2,:) -Face(k,:) );%平面法向量
Vector0 = [0,0,1;1,0,0;0,1,0] ;%xoy,yoz,xoz三个平面的法向量

if sum(Vector.*Vector0(1,:))==0%该平面垂直于xoy平面（两个平面的法向量垂直）
    Face1(1,:) = Face(1,:);
    Face1(2,:) = Face(2,:);
    r1 = r;
    Face1(1,3) = 0;Face1(2,3) = 0;%将形成这个面的前两个点投影到xoy平面上
    r1(1,3) = 0;%将穿透点投影到xoy平面上
    
    d11 = sqrt((Face1(1,1) - Face1(2,1))^2 + (Face1(1,2) - Face1(2,2))^2 + (Face1(1,3) - Face1(2,3))^2);%两投影点间距离
    d12 = sqrt((r1(1,1) - Face1(1,1))^2 + (r1(1,2) - Face1(1,2))^2 + (r1(1,3) - Face1(1,3))^2) + sqrt((r1(1,1) - Face1(2,1))^2 + (r1(1,2) - Face1(2,2))^2 + (r1(1,3) - Face1(2,3))^2);%穿透点投影到面上两点投影点的距离和
    d13 = abs(sqrt((r1(1,1) - Face1(1,1))^2 + (r1(1,2) - Face1(1,2))^2 + (r1(1,3) - Face1(1,3))^2) - sqrt((r1(1,1) - Face1(2,1))^2 + (r1(1,2) - Face1(2,2))^2 + (r1(1,3) - Face1(2,3))^2));%穿透点投影到面上两点投影点的距离差的绝对值
    d11 = roundn(d11,-4);d12 = roundn(d12,-4);d13 = roundn(d13,-4);%防止因为运算精度问题判断不准
    if (d11==d12)||(d11==d13)
        in_1 =1;
        if sum(Vector.*Vector0(2,:))==0%该平面垂直于yoz平面（两个平面的法向量垂直）
            Face2(1,:) = Face(1,:);
            Face2(2,:) = Face(2,:);
            r2 = r;
            Face2(1,1) = 0;Face2(2,1) = 0;%将形成这个面的前两个点投影到yoz平面上
            r2(1,1) = 0;%将穿透点投影到yoz平面上
            d21 = sqrt((Face2(1,1) - Face2(2,1))^2 + (Face2(1,2) - Face2(2,2))^2 + (Face2(1,3) - Face2(2,3))^2);%两投影点间距离
            d22 = sqrt((r2(1,1) - Face2(1,1))^2 + (r2(1,2) - Face2(1,2))^2 + (r2(1,3) - Face2(1,3))^2) + sqrt((r2(1,1) - Face2(2,1))^2 + (r2(1,2) - Face2(2,2))^2 + (r2(1,3) - Face2(2,3))^2);%穿透点投影到面上两点投影点的距离和
            d23 = abs(sqrt((r2(1,1) - Face2(1,1))^2 + (r2(1,2) - Face2(1,2))^2 + (r2(1,3) - Face2(1,3))^2) - sqrt((r2(1,1) - Face2(2,1))^2 + (r2(1,2) - Face2(2,2))^2 + (r2(1,3) - Face2(2,3))^2));%穿透点投影到面上两点投影点的距离差的绝对值
            d21 = roundn(d21,-4);d22 = roundn(d22,-4);d23 = roundn(d23,-4);%防止因为运算精度问题判断不准
            if (d21==d22)||(d21==d23)
                in_2 =1;
                in_3 = inpolygon(r(1,1) , r(1,3) , Face(:,1) , Face(:,3));
                logical = (( in_1 == 1 )&&( in_2 == 1 )&&( in_3 == 1));
            else
                logical = 0;
            end
            
        elseif sum(Vector.*Vector0(3,:))==0%该平面垂直于xoz平面（两个平面的法向量垂直）
            Face3(1,:) = Face(1,:);
            Face3(2,:) = Face(2,:);
            r3 = r;
            Face3(1,2) = 0;Face3(2,2) = 0;%将形成这个面的前两个点投影到xoz平面上
            r3(1,2) = 0;%将穿透点投影到xoz平面上
            
            d31 = sqrt((Face3(1,1) - Face3(2,1))^2 + (Face3(1,2) - Face3(2,2))^2 + (Face3(1,3) - Face3(2,3))^2);%两投影点间距离
            d32 = sqrt((r3(1,1) - Face3(1,1))^2 + (r3(1,2) - Face3(1,2))^2 + (r3(1,3) - Face3(1,3))^2) + sqrt((r3(1,1) - Face3(2,1))^2 + (r3(1,2) - Face3(2,2))^2 + (r3(1,3) - Face3(2,3))^2);%穿透点投影到面上两点投影点的距离和
            d33 = abs(sqrt((r3(1,1) - Face3(1,1))^2 + (r3(1,2) - Face3(1,2))^2 + (r3(1,3) - Face3(1,3))^2) - sqrt((r3(1,1) - Face3(2,1))^2 + (r3(1,2) - Face3(2,2))^2 + (r3(1,3) - Face3(2,3))^2));%穿透点投影到面上两点投影点的距离差的绝对值
            d31 = roundn(d31,-4);d32 = roundn(d32,-4);d33 = roundn(d33,-4);%防止因为运算精度问题判断不准
            if (d31==d32)||(d31==d33)
                in_3 =1;
                in_2 = inpolygon(r(1,2) , r(1,3) , Face(:,2) , Face(:,3));
                logical = (( in_1 == 1 )&&( in_2 == 1 )&&( in_3 == 1));
            else
                logical = 0;
            end
        else%该平面只垂直于xoy平面
            in_2 = inpolygon(r(1,2) , r(1,3) , Face(:,2) , Face(:,3));
            in_3 = inpolygon(r(1,1) , r(1,3) , Face(:,1) , Face(:,3));
            logical = (( in_1 == 1 )&&( in_2 == 1 )&&( in_3 == 1));
        end
    else
        logical = 0;
    end
    
elseif sum(Vector.*Vector0(2,:))==0%该平面垂直于yoz平面（两个平面的法向量垂直）
    Face2(1,:) = Face(1,:);
    Face2(2,:) = Face(2,:);
    r2 = r;
    Face2(1,1) = 0;Face2(2,1) = 0;%将形成这个面的前两个点投影到yoz平面上
    r2(1,1) = 0;%将穿透点投影到yoz平面上
    d21 = sqrt((Face2(1,1) - Face2(2,1))^2 + (Face2(1,2) - Face2(2,2))^2 + (Face2(1,3) - Face2(2,3))^2);%两投影点间距离
    d22 = sqrt((r2(1,1) - Face2(1,1))^2 + (r2(1,2) - Face2(1,2))^2 + (r2(1,3) - Face2(1,3))^2) + sqrt((r2(1,1) - Face2(2,1))^2 + (r2(1,2) - Face2(2,2))^2 + (r2(1,3) - Face2(2,3))^2);%穿透点投影到面上两点投影点的距离和
    d23 = abs(sqrt((r2(1,1) - Face2(1,1))^2 + (r2(1,2) - Face2(1,2))^2 + (r2(1,3) - Face2(1,3))^2) - sqrt((r2(1,1) - Face2(2,1))^2 + (r2(1,2) - Face2(2,2))^2 + (r2(1,3) - Face2(2,3))^2));%穿透点投影到面上两点投影点的距离差的绝对值
    d21 = roundn(d21,-4);d22 = roundn(d22,-4);d23 = roundn(d23,-4);%防止因为运算精度问题判断不准
    if (d21==d22)||(d21==d23)
        in_2 =1;
        if sum(Vector.*Vector0(3,:))==0%该平面垂直于xoz平面（两个平面的法向量垂直）
            Face3(1,:) = Face(1,:);
            Face3(2,:) = Face(2,:);
            r3 = r;
            Face3(1,2) = 0;Face3(2,2) = 0;%将形成这个面的前两个点投影到xoz平面上
            r3(1,2) = 0;%将穿透点投影到xoz平面上
            d31 = sqrt((Face3(1,1) - Face3(2,1))^2 + (Face3(1,2) - Face3(2,2))^2 + (Face3(1,3) - Face3(2,3))^2);%两投影点间距离
            d32 = sqrt((r3(1,1) - Face3(1,1))^2 + (r3(1,2) - Face3(1,2))^2 + (r3(1,3) - Face3(1,3))^2) + sqrt((r3(1,1) - Face3(2,1))^2 + (r3(1,2) - Face3(2,2))^2 + (r3(1,3) - Face3(2,3))^2);%穿透点投影到面上两点投影点的距离和
            d33 = abs(sqrt((r3(1,1) - Face3(1,1))^2 + (r3(1,2) - Face3(1,2))^2 + (r3(1,3) - Face3(1,3))^2) - sqrt((r3(1,1) - Face3(2,1))^2 + (r3(1,2) - Face3(2,2))^2 + (r3(1,3) - Face3(2,3))^2));%穿透点投影到面上两点投影点的距离差的绝对值
            d31 = roundn(d31,-4);d32 = roundn(d32,-4);d33 = roundn(d33,-4);%防止因为运算精度问题判断不准
            if (d31==d32)||(d31==d33)
                in_3 =1;
                in_1 = inpolygon(r(1,1) , r(1,2) , Face(:,1) , Face(:,2));
                logical = (( in_1 == 1 )&&( in_2 == 1 )&&( in_3 == 1));
            else
                logical = 0;
            end
        else%该平面只垂直于yoz平面
            in_1 = inpolygon(r(1,1) , r(1,2) , Face(:,1) , Face(:,2));
            in_3 = inpolygon(r(1,1) , r(1,3) , Face(:,1) , Face(:,3));
            logical = (( in_1 == 1 )&&( in_2 == 1 )&&( in_3 == 1));
        end
    else
        logical = 0;
    end
    
else%该面不垂直于xoy,yoz,xoz任意平面
    in_xy = inpolygon(r(1,1) , r(1,2) , Face(:,1) , Face(:,2));
    in_xz = inpolygon(r(1,1) , r(1,3) , Face(:,1) , Face(:,3));
    in_zy = inpolygon(r(1,3) , r(1,2) , Face(:,3) , Face(:,2));
    logical = (( in_xy == 1 )&&( in_xz == 1 )&&( in_zy == 1));
end







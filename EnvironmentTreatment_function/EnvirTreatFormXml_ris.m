function FaceNum =  EnvirTreatFormXml_ris(Inputpath,params)
%ENVIRTREATFORMXML 此处显示有关此函数的摘要
%   此处显示详细说明

BuildsInfo = BuildingFromxml([Inputpath '\Building_data.xml']);%读取xml文件
% 进行面的信息处理：
% FaceCoordinates：边界点坐标，保留三维小数；FaceEquation：面的方程，未保留小数目前；
FaceNum=size(BuildsInfo.tFace,1);%FaceNumAkll面的个数
for i = 1:FaceNum
    pointNuminEachFace = size(BuildsInfo.tFace(i,1).fPointPos,2);%pointNuminEachFace是每个面上所拥有的点数，即12
    for k = 1:(pointNuminEachFace/3)%3个点为一个坐标点，1个面有4个点
        FaceCoordinates(i).Face(k,1:3) = round([BuildsInfo.tFace(i,1).fPointPos(1,(3*k-2):(3*k))],3);%得到每一个面的四个坐标点
        %更新：不一定是四个点的坐标，xml文件中有几个点，就是几个点，一般来说是四个点
    end
end
%FromPointsToFaceEquation通过FaceCoordinates求每个面的面方程参数ABCD  Ax+By+Cz+D=0，ABC为法向量，D为-法向量乘以第一个面坐标
for i = 1:FaceNum
    k = size(FaceCoordinates(i).Face(:,:),1);%k：有几个点
    FaceNormalVector = cross ( FaceCoordinates(i).Face(1,:) - FaceCoordinates(i).Face(k-1,:) , FaceCoordinates(i).Face(2,:) - FaceCoordinates(i).Face(k,:) );%Avoid selecting 2 vectors in face are in a line
    FaceNormalVector = FaceNormalVector./norm(FaceNormalVector);%法向量就是：两个面上的向量叉乘的结果；法向量归一化
    D = -FaceNormalVector*FaceCoordinates(i).Face(1,:)';%D为-法向量乘以第一个面坐标，就是普通方程的D，由点法式直接计算而来
    FaceEquation(i,:) = [FaceNormalVector , D];%FaceEquation  FOriginal存储面方程信息
end

%建筑物信息：发射点，接收点，面
BuildingInfo = struct('TXInfo',[],'RXInfo',[],'Face',[]);
%面的具体信息：面标号，形成面的坐标，面方程的A,B,C,D参数（A,B,C为法向量），面的材料，面的厚度
BuildingInfo.Face = struct('Index',[],'Coordinate',[],'Vector',[],'Material',[],'Thickness',[]);
if isequal(params.diffscatting,1)
    for i= 1:FaceNum
        BuildingInfo.Face(i).Index = i;
        BuildingInfo.Face(i).Coordinate = FaceCoordinates(i).Face;
        BuildingInfo.Face(i).Vector = FaceEquation(i,:);
        BuildingInfo.Face(i).Material = BuildsInfo.tFace(i,1).material;
        BuildingInfo.Face(i).Thickness = BuildsInfo.tFace(i,1).thickness;
        BuildingInfo.Face(i).Ifscatting = BuildsInfo.tFace(i,1).ifscatting;
        BuildingInfo.Face(i).S = BuildsInfo.tFace(i,1).S;
        BuildingInfo.Face(i).alpha_R = BuildsInfo.tFace(i,1).alpha_R;
        BuildingInfo.Face(i).model_type = BuildsInfo.tFace(i,1).model_type;
    end
else%用户不开启散射
    for i= 1:FaceNum
        BuildingInfo.Face(i).Index = i;
        BuildingInfo.Face(i).Coordinate = FaceCoordinates(i).Face;
        BuildingInfo.Face(i).Vector = FaceEquation(i,:);
        BuildingInfo.Face(i).Material = BuildsInfo.tFace(i,1).material;
        BuildingInfo.Face(i).Thickness = BuildsInfo.tFace(i,1).thickness;
        BuildingInfo.Face(i).Ifscatting = BuildsInfo.tFace(i,1).ifscatting;
    end

end

save([Inputpath '\EnvirormentData.mat'],'BuildingInfo','FaceCoordinates','FaceEquation','FaceNum');

% 画图看下场景
% 设置灰色
grayColor = [0.7, 0.7, 0.7];
FaceNum = size(BuildingInfo.Face, 2);

for i = 1:FaceNum
    % 画面
    face = BuildingInfo.Face(i).Coordinate;
    
    % 判断是否为屋顶
    if i == 29 || i == 30
        faceAlpha = 0.3; % 屋顶透明度
    else
        faceAlpha = 0.7; % 其他面片透明度
    end
    
    % 绘制面片
    patch('Vertices', face, 'Faces', 1:size(face, 1), ...
        'FaceColor', grayColor, 'EdgeColor', 'k', ...
        'FaceAlpha', faceAlpha, 'LineWidth', 0.5);
end

axis equal;
view(3);

% 添加主光源
mainLight = light('Position', [1 3 2], 'Style', 'infinite');

% 添加辅助光源
auxLight1 = light('Position', [-3 -1 3], 'Style', 'infinite');
auxLight2 = light('Position', [3 -1 2], 'Style', 'infinite');

% 设置光照类型
lighting phong;
grid on; % 添加网线格

%进行面面组合计算与存储
RefNum=params.RT_RefNum;
fp = struct('f',[]);%存储N次反射的组合数，fp是1*numRef的struct
for m = 1:RefNum%对不同的反射次数进行遍历
    %实现遍历
    if m==1
        matAll=struct('Detail',[]);
        mat=[1:FaceNum]';
        index3=find(mat(:,1)~=0);
        matAll.Detail=mat(index3,:);
        fp(m).f=matAll;
    elseif m==2
        matAll=struct('Detail',[]);
        for matnum=1:FaceNum
            mat=zeros(FaceNum-1,2);%[40,2]
            mat(:,1)=matnum;%第一列都等于固定值
            AAA=1:1:FaceNum;
            for i=1:FaceNum
                if AAA(i)==matnum
                    AAA(i)=0;
                    break;
                end
            end
            AAA_1=find(AAA~=0);
            mat(:,2)=AAA_1;
            matAll(matnum,1).Detail=mat;
        end
        fp(m).f=matAll;
    end
end
%%Select_DifNumFacesFromNFaces%从N个面中选出绕射面
num1 = 1;
for i = 1:FaceNum-1
    for j = i+1:FaceNum
        % i和j就是面组合索引；
        numsCoorEqualtoTwoFace = 0;%两个面具有相同点的个数
        %找到要绕射的两个面
        FaceDifEquation(1,:) = FaceEquation(i,:) ;
        FaceDifEquation(2,:) = FaceEquation(j,:) ;
        %下面判断两个面是否平行，利用： |a||b|=|ab|
        t_1 = abs(FaceDifEquation(1,1:3) * FaceDifEquation(2,1:3)');
        t_2 = norm(FaceDifEquation(1,1:3))*norm(FaceDifEquation(2,1:3));
        if ( t_1 == t_2 )%
        else
            size1 = size(FaceCoordinates(i).Face(:,:),1);%面的边沿点有几个
            size2 = size(FaceCoordinates(j).Face(:,:),1);
            for m = 1:size1
                for n = 1:size2
                    %%判断两个面上是否有相同的点 即两个面上的边沿点是否存在相同的
                    if(FaceCoordinates(i).Face(m,:)==FaceCoordinates(j).Face(n,:))
                        numsCoorEqualtoTwoFace = numsCoorEqualtoTwoFace+1;%相同沿边点的个数+1
                        if numsCoorEqualtoTwoFace==2
                            break;
                        end
                    end
                end
                if numsCoorEqualtoTwoFace==2%有两个沿边点是相同的，就直接跳出循环
                    break;
                end
            end
        end
        if numsCoorEqualtoTwoFace==2%有两个沿边点是相同的，就直接跳出循环
            fpDif(1).CombinNuminDif.Detail(num1,1)=i;
            fpDif(1).CombinNuminDif.Detail(num1,2)=j;
            num1  = num1 + 1;
        end

    end
end
%进行二阶绕射面索引：
num2 = size(fpDif(1).CombinNuminDif.Detail,1);
for k = 1:num2
    matDif = [];
    matDif(:,1:2) = repmat(fpDif(1).CombinNuminDif.Detail(k,:),num2,1);
    matDif(:,3:4) = fpDif(1).CombinNuminDif.Detail;
    for i = 1:size(matDif,1)
        x1 = matDif(i,1);
        x2 = matDif(i,2);
        x3 = matDif(i,3);
        x4 = matDif(i,4);
        if (x1 == x3) && (x2 == x4)
            matDif(i,1:4) = 0;
            break;
        end
    end
    nonZeroRows = ~all(matDif == 0, 2);
    matDif = matDif(nonZeroRows, :);
    fpDif(2).CombinNuminDif(k).Detail = matDif;
end
%CombinNuminDif = nchoosek( 1:FaceNum,2 );%此处为组合数(二项式系数)而不是排列数，目的是对每两个面找刃，这两个面没有先后顺序，若为排列数则找了两遍
save([Inputpath '\FaceCombination.mat'],'fp','fpDif');

%--------------处理下ris--------------%
ris_Info = BuildingFromxml([Inputpath '\RIS_data.xml']);
risNum=size(ris_Info.tFace,1);%FaceNumAkll面的个数
for i = 1:risNum
    pointNuminEachFace = size(ris_Info.tFace(i,1).fPointPos,2);%pointNuminEachFace是每个面上所拥有的点数，即12
    for k = 1:(pointNuminEachFace./3)%3个点为一个坐标点，1个面有4个点
        risCoordinates(i).Face(k,1:3) = [ris_Info.tFace(i,1).fPointPos(1,(3*k-2):(3*k))];%得到每一个面的四个坐标点
    end
     risCenterPoint(i,:) = sum(risCoordinates(i).Face) /  pointNuminEachFace * 3;
end
%FromPointsToFaceEquation通过FaceCoordinates求每个面的面方程参数ABCD  Ax+By+Cz+D=0，ABC为法向量，D为-法向量乘以第一个面坐标
for i = 1:risNum
    k = size(risCoordinates(i).Face(:,:),1);%k：有几个点
    risNormalVector = cross ( risCoordinates(i).Face(1,:) - risCoordinates(i).Face(k-1,:) , risCoordinates(i).Face(2,:) - risCoordinates(i).Face(k,:) );%Avoid selecting 2 vectors in face are in a line
    risNormalVector = risNormalVector./norm(risNormalVector);%法向量就是：两个面上的向量叉乘的结果；法向量归一化
    D1(i) = -risNormalVector*risCoordinates(i).Face(1,:)';%D为-法向量乘以第一个面坐标，就是普通方程的D，由点法式直接计算而来
    risEquation(i,:) = [risNormalVector , D1(i)];%FaceEquation  FOriginal存储面方程信息
end
%RIS信息
risInfo =  struct('Face',[]);
risInfo.Face = struct('Index',[],'Coordinate',[],'Vector',[],'Material',[],'Thickness',[],'CenterPoint',[]);
for i= 1:risNum
    risInfo.Face(i).Index = i;
    risInfo.Face(i).Coordinate = risCoordinates(i).Face;
    risInfo.Face(i).Vector = risEquation(i,:);
    risInfo.Face(i).CenterPoint = risCenterPoint(i,:);
    risInfo.Face(i).Material = ris_Info.tFace(i,1).material;
    risInfo.Face(i).Thickness = ris_Info.tFace(i,1).thickness;
end
save([Inputpath '\risData.mat'],'risInfo','risEquation','risCoordinates');

end


function FaceNum =  EnvirTreatFormXml(Inputpath,params)
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
if isfield(BuildsInfo.tFace(1,1), 'S')
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
else
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

%画图看下场景
% 设置灰色
grayColor = [0.7, 0.7, 0.7];
FaceNum=size(BuildingInfo.Face,2);
for i = 1:FaceNum
    %画面
    face = BuildingInfo.Face(i).Coordinate;
    patch('Vertices', face, 'Faces', 1:size(face, 1), ...
        'FaceColor', grayColor, 'EdgeColor', 'k', ...
        'FaceAlpha', 0.8, 'LineWidth', 0.5);
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
%grid on;%添加网线格

%进行面面组合计算与存储
% RefNum=params.RT_RefNum;
% fp = struct('f',[]);%存储N次反射的组合数，fp是1*numRef的struct
% for m = 1:RefNum%对不同的反射次数进行遍历
%     %实现遍历
%     if m==1
%         matAll=struct('Detail',[]);
%         mat=[1:FaceNum]';
%         index3=find(mat(:,1)~=0);
%         matAll.Detail=mat(index3,:);
%         fp(m).f=matAll;
%     elseif m==2
%         matAll=struct('Detail',[]);
%         for matnum=1:FaceNum
%             mat=zeros(FaceNum-1,2);
%             mat(:,1)=matnum;%第一列都等于固定值
%             AAA=1:1:FaceNum;
%             for i=1:FaceNum
%                 if AAA(i)==matnum
%                     AAA(i)=0;
%                     break;
%                 end
%             end
%             AAA_1=find(AAA~=0);
%             mat(:,2)=AAA_1;
%             matAll(matnum,1).Detail=mat;
%         end
%         fp(m).f=matAll;
%     end
% end
% 进行面面组合计算与存储
RefNum = params.RT_RefNum;
fp = struct('f', []);  % 存储N次反射的组合数，fp是1*numRef的struct

for m = 1:RefNum  % 对不同的反射次数进行遍历
    matAll = struct('Detail', []);  % 用于存储每个反射次数的组合
    
    if m == 1
        % 1次反射
        mat = (1:FaceNum)';  % 1次反射，所有面
        matAll.Detail = mat;
        
    elseif m == 2
        % 2次反射
        for matnum = 1:FaceNum
            mat = zeros(FaceNum - 1, 2);  % 每个面对应的二次反射组合
            mat(:, 1) = matnum;  % 第一列固定值为 matnum
            AAA = 1:FaceNum;
            AAA(AAA == matnum) = 0;  % 排除固定的面
            AAA_1 = find(AAA ~= 0);  % 其他可选的面
            mat(:, 2) = AAA_1;  % 第二列为组合的面
            matAll(matnum, 1).Detail = mat;  % 存储组合
        end
        
    elseif m == 3
        % 3次反射
        for matnum = 1:FaceNum
            mat = zeros((FaceNum - 1) * (FaceNum - 2), 3);  % 每个面对应的三次反射组合
            mat(:, 1) = matnum;  % 第一列固定值为 matnum
            AAA = 1:FaceNum;
            AAA(AAA == matnum) = 0;  % 排除固定的面
            AAA_1 = find(AAA ~= 0);  % 其他可选的面
            idx = 1;
            
            for i = 1:length(AAA_1)
                AAA_2 = setdiff(1:FaceNum, [matnum, AAA_1(i)]);  % 排除已选择的面
                for j = 1:length(AAA_2)
                    mat(idx, 2) = AAA_1(i);  % 第二列为第一层选择的面
                    mat(idx, 3) = AAA_2(j);  % 第三列为第二层选择的面
                    idx = idx + 1;
                end
            end
            
            matAll(matnum, 1).Detail = mat;  % 存储组合
        end
        
    elseif m == 4
        % 4次反射
        for matnum = 1:FaceNum
            mat = zeros((FaceNum - 1) * (FaceNum - 2) * (FaceNum - 3), 4);  % 每个面对应的四次反射组合
            mat(:, 1) = matnum;  % 第一列固定值为 matnum
            AAA = 1:FaceNum;
            AAA(AAA == matnum) = 0;  % 排除固定的面
            AAA_1 = find(AAA ~= 0);  % 其他可选的面
            idx = 1;
            
            for i = 1:length(AAA_1)
                AAA_2 = setdiff(1:FaceNum, [matnum, AAA_1(i)]);  % 排除已选择的面
                for j = 1:length(AAA_2)
                    AAA_3 = setdiff(1:FaceNum, [matnum, AAA_1(i), AAA_2(j)]);  % 排除已选择的面
                    for k = 1:length(AAA_3)
                        mat(idx, 2) = AAA_1(i);  % 第二列为第一层选择的面
                        mat(idx, 3) = AAA_2(j);  % 第三列为第二层选择的面
                        mat(idx, 4) = AAA_3(k);  % 第四列为第三层选择的面
                        idx = idx + 1;
                    end
                end
            end
            
            matAll(matnum, 1).Detail = mat;  % 存储组合
        end
        
    elseif m == 5
        % 5次反射
        for matnum = 1:FaceNum
            mat = zeros((FaceNum - 1) * (FaceNum - 2) * (FaceNum - 3) * (FaceNum - 4), 5);  % 每个面对应的五次反射组合
            mat(:, 1) = matnum;  % 第一列固定值为 matnum
            AAA = 1:FaceNum;
            AAA(AAA == matnum) = 0;  % 排除固定的面
            AAA_1 = find(AAA ~= 0);  % 其他可选的面
            idx = 1;
            
            for i = 1:length(AAA_1)
                AAA_2 = setdiff(1:FaceNum, [matnum, AAA_1(i)]);  % 排除已选择的面
                for j = 1:length(AAA_2)
                    AAA_3 = setdiff(1:FaceNum, [matnum, AAA_1(i), AAA_2(j)]);  % 排除已选择的面
                    for k = 1:length(AAA_3)
                        AAA_4 = setdiff(1:FaceNum, [matnum, AAA_1(i), AAA_2(j), AAA_3(k)]);  % 排除已选择的面
                        for l = 1:length(AAA_4)
                            mat(idx, 2) = AAA_1(i);  % 第二列为第一层选择的面
                            mat(idx, 3) = AAA_2(j);  % 第三列为第二层选择的面
                            mat(idx, 4) = AAA_3(k);  % 第四列为第三层选择的面
                            mat(idx, 5) = AAA_4(l);  % 第五列为第四层选择的面
                            idx = idx + 1;
                        end
                    end
                end
            end
            
            matAll(matnum, 1).Detail = mat;  % 存储组合
        end
        
    end
    fp(m).f = matAll;  % 存储每次反射的结果
end

%%Select_DifNumFacesFromNFaces%从N个面中选出绕射面：加入了判断是否能形成棱的前提
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
if params.RT_DifNum ==2
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
end
%CombinNuminDif = nchoosek( 1:FaceNum,2 );%此处为组合数(二项式系数)而不是排列数，目的是对每两个面找刃，这两个面没有先后顺序，若为排列数则找了两遍
save([Inputpath '\FaceCombination.mat'],'fp','fpDif');

end



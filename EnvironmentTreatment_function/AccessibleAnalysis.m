function [fp_avis,fD_avis]= AccessibleAnalysis(Inputpath,TxPoint, params)

if nargin==0 %如果没有输入，即进行初始化
    clc;clear;
    Inputpath='E:\matlab_code\Raytracing_2024_V5_ris\Input\NorthtaipingzhuangCommunity\Rx_1';
    %TxPoint=[115,-214,50];
    TxPoint=[107,-61,50];
end

%导入环境数据
load([Inputpath '\EnvirormentData.mat'],'FaceCoordinates','FaceEquation','FaceNum');
%可见面分析
ground_vector = [0,0,1];%地面的法向量
tolerance = 1e-2; %判断面是否与地面平行时阈值
visable_index1 = [];%与地面平行面的索引
for ii = 1:FaceNum
    if ((abs(abs(dot(FaceEquation(ii,1:3),ground_vector))-1))<tolerance)
        visable_index1 = [visable_index1;ii];
    end
end
visable_Faceindex1 = test_2D_1(TxPoint, FaceNum, FaceCoordinates,FaceEquation);%可见面的判断
Visable_Faceindex1 = [visable_Faceindex1;visable_index1];%将平行于地面的面与可见面的结果合并
Visable_Faceindex1 = unique(Visable_Faceindex1,'row');%删去重复的
FaceNum=size(Visable_Faceindex1,1);
%进行可见面的面组合索引：
RefNum=params.RT_RefNum;
fp_avis = struct('f',[]);%存储N次反射的组合数，fp是1*numRef的struct
for m = 1:RefNum%对不同的反射次数进行遍历
    if m==1
        matAll=struct('Detail',[]);
        matAll.Detail=Visable_Faceindex1;
        fp_avis(m).f=matAll;
    elseif m==2
        matAll=struct('Detail',[]);
        for matnum=1:FaceNum
            mat=zeros(FaceNum-1,2);
            mat(:,1)=Visable_Faceindex1(matnum,1);%第一列都等于固定值
            Visable_Faceindex1_1=Visable_Faceindex1;
            for i=1:FaceNum
                if Visable_Faceindex1_1(i,1)==Visable_Faceindex1(matnum,1)
                    Visable_Faceindex1_1(i,1)=0;
                    break;
                end
            end
            Visable_Faceindex1_2=find(Visable_Faceindex1_1~=0);
            mat(:,2)=Visable_Faceindex1_1(Visable_Faceindex1_2);
            matAll(matnum,1).Detail=mat;
        end
        fp_avis(m).f=matAll;
    end        
end
%进行绕射可见面索引：
fD_avis=struct('CombinNuminDif',[]);
num1 = 1;
CombinNuminDif = nchoosek(Visable_Faceindex1,2);
for numDifIndex=1:nchoosek(FaceNum,2)%对面面组合进行索引，找可能发生绕射的棱
    numsCoorEqualtoTwoFace = 0;%两个面具有相同点的个数
    %找到要绕射的两个面
    FaceDifEquation(1,:) = FaceEquation(CombinNuminDif(numDifIndex,1),:) ;
    FaceDifEquation(2,:) = FaceEquation(CombinNuminDif(numDifIndex,2),:) ;
    %下面判断两个面是否平行，利用： |a||b|=|ab|
    t_1 = abs(FaceDifEquation(1,1:3) * FaceDifEquation(2,1:3)');
    t_2 = norm(FaceDifEquation(1,1:3))*norm(FaceDifEquation(2,1:3));
    if ( t_1 == t_2 )%
    else%如果不平行，即两个面相交，则找两平面交线
    %FaceCoordinates是个变量，是面的沿边点
        size1 = size(FaceCoordinates(CombinNuminDif(numDifIndex,1)).Face(:,:),1);%面的边沿点有几个
        size2 = size(FaceCoordinates(CombinNuminDif(numDifIndex,2)).Face(:,:),1);
        indexFace1 = [];indexFace2 = [];%为了存储面的顺序，分辨面1、面2
         for m = 1:size1
             for n = 1:size2
              %%判断两个面上是否有相同的点 即两个面上的边沿点是否存在相同的
                 if(FaceCoordinates(CombinNuminDif(numDifIndex,1)).Face(m,:)==FaceCoordinates(CombinNuminDif(numDifIndex,2)).Face(n,:))
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
        fD_avis(1).CombinNuminDif.Detail(num1,1)=CombinNuminDif(numDifIndex,1);
        fD_avis(1).CombinNuminDif.Detail(num1,2)=CombinNuminDif(numDifIndex,2);
        num1  = num1 + 1;
    end
end%单核绕射计算面面组合
num2 = size(fD_avis(1).CombinNuminDif.Detail,1);
for k = 1:num2
    matDif = [];
    matDif(:,1:2) = repmat(fD_avis(1).CombinNuminDif.Detail(k,:),num2,1);
    matDif(:,3:4) = fD_avis(1).CombinNuminDif.Detail;
    for i = 1:size(matDif,1)
        x1 = matDif(i,1);
        x2 = matDif(i,2);
        x3 = matDif(i,3);
        x4 = matDif(i,4);
        if (x1 == x3) && (x2 == x4)
            matDif(i,1:4) = 0;
        end
    end
    nonZeroRows = ~all(matDif == 0, 2);
    matDif = matDif(nonZeroRows, :);
    fD_avis(2).CombinNuminDif(k).Detail = matDif;
end
%save([Inputpath '\VisableFaceCombination.mat'],'fp_avis','fD_avis');
end


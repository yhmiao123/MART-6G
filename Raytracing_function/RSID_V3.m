function RSID_Info= RSID_V3 (Inputpath,Output,SearchPathSet)

%参数设置
LOS = SearchPathSet(1,1);%直射=1/0，是/否需要直射
RefNum = SearchPathSet(2,1);%反射次数=Any，可调
DifNum = SearchPathSet(3,1);%绕射次数=1/0
PeneNum = SearchPathSet(4,1);%穿透次数限制，可调
load([Inputpath '\daeinfo.mat'],'buildingArray');%
load([Inputpath '\EnvirormentData.mat'],'BuildingInfo','fp','fpDif','FaceEquation','FaceNum','FaceCoordinates','CombinNuminDif');
load([Inputpath '\TxRxData.mat'],'TxCAl','RxCal');
%保存mat位置

if ~exist([Output '\Los',num2str(LOS),'Ref',num2str(RefNum),'Dif',num2str(DifNum),'Pe',num2str(PeneNum)])%将最大反射数和最大穿透数放进文件夹名
    mkdir([Output '\Los',num2str(LOS),'Ref',num2str(RefNum),'Dif',num2str(DifNum),'Pe',num2str(PeneNum)]);
end
Outputpath = [Output  '\Los',num2str(LOS),'Ref',num2str(RefNum),'Dif',num2str(DifNum),'Pe',num2str(PeneNum)];
%E:\matlab_code\Rrytracing_new\Raytracing\Output\test_2\PeNum\Los1Ref2Dif1Pe2
%%
%光程限制
F = 28000;%频率(MHz)，可调
PL = 100;%损耗pathloss(dB)，可调
dmax = 10^( ( PL-32.4-20*log10(F) )./20 );%(单位km)
% TR38.900 InH-Office LOS：PL=32.4+17.3*log10(D)+20*log10(F) 对高频不一定准确
dmax = dmax*1000;%(单位m)最大光程程
% dmax = 50;%可调

%数据存储格式说明
%建筑物信息：发射点，接收点，面
BuildingInfo = struct('TXInfo',[],'RXInfo',[],'Face',[]);
%面的具体信息：面标号，形成面的坐标，面方程的A,B,C,D参数（A,B,C为法向量），面的材料，面的厚度
BuildingInfo.Face = struct('Index',[],'Coordinate',[],'Vector',[],'Material',[],'Thickness',[]);
%仿真设置信息：收端点个数，反射次数设置，绕射次数，最大穿透次数设置，最大光程设置
SetInfo = struct('RXNum',[],'RefNum',[],'DifNum',[],'PeneNum',[],'DisLimit',[]);
%RT几何计算结果信息：发端点坐标，收端点坐标，直射信息，反射信息，绕射信息
GeoInfo = struct('Startpoint',[],'Finishpoint',[],'LosInfo',[],'RefInfo',[],'DifInfo',[]);
load([Inputpath '\EnvirormentData.mat'],'BuildingInfo','FaceNum','FaceCoordinates','fp','CombinNuminDif');%
%%
%xmlreadBuilding从xml文件中读取信息，调用函数

%%
%将属于相同建筑的面归类
building_index=zeros(FaceNum,1);
builcount=0;
build_serial=0;
%FromPointsToFaceEquation通过FaceCoordinates求每个面的面方程参数ABCD  Ax+By+Cz+D=0，ABC为法向量，D为-法向量乘以第一个面坐标
for i = 1:FaceNum
    k = size(FaceCoordinates(i).Face(:,:),1);%k：有几个点
    FaceNormalVector = cross ( FaceCoordinates(i).Face(1,:) - FaceCoordinates(i).Face(k-1,:) , FaceCoordinates(i).Face(2,:) - FaceCoordinates(i).Face(k,:) );%Avoid selecting 2 vectors in face are in a line
    FaceNormalVector = FaceNormalVector./norm(FaceNormalVector);%法向量就是：两个面上的向量叉乘的结果；法向量归一化
    D(i) = -FaceNormalVector*FaceCoordinates(i).Face(1,:)';%D为-法向量乘以第一个面坐标，就是普通方程的D，由点法式直接计算而来
    FaceEquation(i,:) = [FaceNormalVector , D(i)];%FaceEquation  FOriginal存储面方程信息
    
    if i==1
        build_serial=1;
        
    else
        if  strcmp(buildingArray(i).buildingName,buildingArray(i-1).buildingName) %说明属于一个建筑

        else
            build_serial=build_serial+1;
        end
        
       
    end
    building_index(i,:)= build_serial;

end





%%
%读取收发端信息


Tx =TxCAl;
Rx = RxCal;


pointTx(1,:) = Tx;
%%
%二维化所有的散射体面

serialcount = 0;
under_num=0;

for i = 1:FaceNum
    c=1;
    if all(FaceCoordinates(i).Face(:,3) <= 0.3)
        serialcount = serialcount + 1;
        for j=1:size(FaceCoordinates(i).Face,1)
            buliding_under(serialcount).coordinates(j,:) = FaceCoordinates(i).Face(j,:);


        end
        buliding_under(serialcount).serial = serialcount;


    end
end

for i=1:FaceNum

    for jj=1:serialcount
           c=1;

        if all(abs(sort(FaceCoordinates(i).Face(:,1))-sort(buliding_under(jj).coordinates(:,1)))<0.5)...
           && all(abs(sort(FaceCoordinates(i).Face(:,2))-sort(buliding_under(jj).coordinates(:,2)))<0.5) &&FaceCoordinates(i).Face(1,3)~=0 &&...
           FaceCoordinates(i).Face(1,3)>=1
          
            buliding_under(jj).highet=FaceCoordinates(i).Face(1,3);
        end

    end

end

line_count=0;
for i=1:serialcount
    
    for j=1:size(buliding_under(i).coordinates,1)
       
        if j~=size(buliding_under(i).coordinates,1)
            y2=buliding_under(i).coordinates(j+1,2);
            y1=buliding_under(i).coordinates(j,2);
            x2=buliding_under(i).coordinates(j+1,1);
            x1=buliding_under(i).coordinates(j,1);

        else
            y2=buliding_under(i).coordinates(j,2);
            y1=buliding_under(i).coordinates(1,2);
            x2=buliding_under(i).coordinates(j,1);
            x1=buliding_under(i).coordinates(1,1);
        end
        if (x2-x1)==0

            face_line(i).equation(j,1)=inf;
            face_line(i).equation(j,2)=x1;
        else

            face_line(i).equation(j,1)=(y2-y1)/(x2-x1);
            face_line(i).equation(j,2)=y1-((y2-y1)/(x2-x1))*x1;

        end
        face_line(i).equation(j,3)=buliding_under(i).serial;
           P1=[x1,y1];
           P2=[x2,y2];
           if P2(2)>P1(2)|| P2(1)>P1(1)
            term=P1;
            P1=P2;
            P2=term;
            end

        face_line(i).ter_point(j,1:2)=P1;
        face_line(i).ter_point(j,3:4)=P2;


        line_count=line_count+1;
        tot_line_inf(line_count).equation=face_line(i).equation(j,:);
        tot_line_inf(line_count).ter_point=face_line(i).ter_point(j,:);
        if isempty(buliding_under(tot_line_inf(line_count).equation(3)).highet)
            tot_line_inf(line_count).equation(4)=0;
        else
        tot_line_inf(line_count).equation(4)=buliding_under(tot_line_inf(line_count).equation(3)).highet;
        end
    end
end
for ii=1:size(buliding_under,2)
    if isempty(buliding_under(ii).highet)
        groundIndex=ii;
    end
end
for i=1:FaceNum
    if size(FaceCoordinates(i).Face,1)~=size(buliding_under(groundIndex).coordinates)
    else
if FaceCoordinates(i).Face==buliding_under(groundIndex).coordinates
    ground_index=i;
end
    end
end


for i=1:size(tot_line_inf,2)
      c=1;
    
    for j=1:FaceNum
        point_to_check1=[tot_line_inf(i).ter_point(1:2)];
        point_to_check2=[tot_line_inf(i).ter_point(3:4)];

    if tot_line_inf(i).equation(3)==building_index(j,:)
        c=1;

if any(ismember(FaceCoordinates(j).Face(:,1:2), point_to_check1, 'rows'))&&any(ismember(FaceCoordinates(j).Face(:,1:2), point_to_check2, 'rows'))
    if all(FaceCoordinates(j).Face(:,3)==0)
    else
   tot_line_inf(i).fullfaceIndex=j;
   break;
    end
end
    end
    end

   if isempty(tot_line_inf(i).fullfaceIndex)
       tot_line_inf(i).fullfaceIndex=ground_index;
   end

end


%这里建立RefNum+1次的面面组合的索引，
%建立反射面之间的可见数据库
face_comb = struct('f',[]);%存储N次反射的组合数，fp是1*numRef的struct
line_num=size(tot_line_inf,2);
for m = 2:RefNum+1%对不同的反射次数进行遍历
    %实现遍历
    mat2=zeros(line_num^m,m);%中间变量，储存的是没有删除重复的，行就是一个面组合，列为这个面组合有几个面
    array2=1:line_num;
    for numRefIndex2=1:m
        mat2(:,numRefIndex2)=reshape(repmat(array2,line_num^(m-numRefIndex2),line_num^(numRefIndex2-1)),line_num^m,1);
    end
    %删除与前一个相同的行
    for index_1=1:line_num^m%在m次反射中不同面的组合数
        for index_2=2:m
            if mat2(index_1,index_2)==mat2(index_1,index_2-1)
                mat2(index_1,:)=0;
                break;
            end
        end
    end
    index_3=find(mat2(:,1)~=0);
    face_comb(m).f=mat2(index_3,:);
end
bb=1;
face_comb(1).f=0;
for ref_index=2:RefNum+1
    for comb_index=1:size(face_comb(ref_index).f,1)-1
        A=zeros(1,ref_index-1);

         for i=1:ref_index-1
            B=face_comb(ref_index).f(comb_index,ref_index-1);
            A(1,ref_index-1)=tot_line_inf(B).equation(3);
         end
         C=tot_line_inf(face_comb(ref_index).f(comb_index,ref_index)).equation(3);
        unique_ele=unique(A);
        if ref_index==2
            if (ismember(C,A))
                face_comb(ref_index).f(comb_index,1)=0;
            end
        elseif (ismember(C,A))||(numel(unique_ele)==1)
            face_comb(ref_index).f(comb_index,1)=0;
        end

    end

    index_valide=find(face_comb(ref_index).f(:,1)~=0);
    face_comb(ref_index).f=face_comb(ref_index).f(index_valide,:);
end

for ref_index=3:RefNum+1
    for comb_index=1:size(face_comb(ref_index).f,1)-1

        A=face_comb(ref_index).f(comb_index,3);
        B=face_comb(ref_index).f(comb_index+1,3);

        face_comb(ref_index).f(comb_index,3)=tot_line_inf(A).equation(3);

        face_comb(ref_index).f(size(face_comb(ref_index).f,1),3)=face_comb(ref_index).f(size(face_comb(ref_index).f,1)-1,3);

    end
    face_comb(ref_index).f= unique( face_comb(ref_index).f, 'rows', 'stable');
end



%下面对面面之间的可见性进行遍历，假设反射上限设为2，n次反射只需不断重复上述过程。
%1次反射的逻辑比较特殊，所以单独拿出来
buildingcount=1;
blockflag=0;
for i=1: size(face_comb(2).f,1)

    pointA=Rx(1,1:2);
    pointB=tot_line_inf(face_comb(2).f(i,1)).ter_point(1:2);%索引中第一列（想要反射的面）的一个端点
    pointB2=tot_line_inf(face_comb(2).f(i,1)).ter_point(3:4);
    pointC=tot_line_inf(face_comb(2).f(i,2)).ter_point(1:2);%索引中第二列（可能产生阻挡的面）的一个端点
    pointD=tot_line_inf(face_comb(2).f(i,2)).ter_point(3:4);%索引中第二列（可能产生阻挡的面的另一个端点
    if pointD(1)>pointC(1)||pointD(2)>pointC(2)
     term=pointC;
     pointC=pointD;
     pointD=term;
    end
    if pointB2(1)>pointB(1)||pointB2(2)>pointB(2)
     term=pointB;
     pointB=pointB2;
     pointB2=term;
    end
    [flag1,inter_point1]=CrossPointLine(pointA,pointB,pointC,pointD);

    [flag2,inter_point2]=CrossPointLine(pointA,pointB2,pointC,pointD);
    [flag3,inter_point3]=CrossPointLine(pointB,pointB2,pointC,pointD);
    if ((flag1==0)&&(flag2==0))%说明Rx和欲反射的面之间没有遮挡
        ain=angle_trans(pointA,pointB);
        bout=angle_trans(pointA,pointB2);
        terPoint=[pointB,pointB2];
    elseif((flag1==0)&&(flag2~=0))%有一个端点被遮挡
        disC=pdist([inter_point2;pointC],"euclidean");
        disD=pdist([inter_point2;pointD],"euclidean");
        if disC<disD
            
            newter=Cross_pointLine(pointA,pointC,pointB,pointB2);
        else
            newter=Cross_pointLine(pointA,pointD,pointB,pointB2);
        end
        if flag1==1
        terPoint=[newter,pointB2];
        ain=angle_trans(pointA,newter);
        bout=angle_trans(pointA,pointB2);
        elseif flag2==2
           
        terPoint=[pointB,newter];
        ain=angle_trans(pointA,pointB);
        bout=angle_trans(pointA,newter);
        end
    elseif flag3==1
        disB=pdist([inter_point3;pointB],"euclidean");
        disB2=pdist([inter_point3;pointB2],"euclidean");
        newter=inter_point3;
        if disB<disB2
            terPoint=[newter,pointB2];
            ain=angle_trans(pointA,newter);
            bout=angle_trans(pointA,pointB2);
        else
            terPoint=[pointB,newter];
            ain=angle_trans(pointA,pointB);
            bout=angle_trans(pointA,newter);
        end


   elseif((flag1==1)&&(flag2==1))
        blockflag=1;


    end

    if i==1
        if blockflag==1
            ain=0;
            bout=0;
            terPoint=zeros(1,4);
            RSID_database(1).deviation(1,:)=[ain,bout];

            RSID_database(1).terPoint(1,:)=terPoint;
        end
        RSID_database(1).deviation(1,:)=[ain,bout];

        RSID_database(1).terPoint(1,:)=terPoint;

    end

    if i>1
        if (face_comb(2).f(i,1)==face_comb(2).f(i-1,1))%一阶面没有变化

            if blockflag==1
                RSID_database(1).blockflag(buildingcount,1)=1;


            else
                RSID_database(1).blockflag(buildingcount,1)=0;
            end
            if isnan(inter_point1)
            else
                if (dot((pointA-pointB),(inter_point1-pointB))>0) %说明交点和Rx在同侧
                    if abs(ain)<abs(RSID_database(1).deviation(buildingcount,1))


                        RSID_database(1).deviation(buildingcount,1)=ain;
                        RSID_database(1).terPoint(buildingcount,1:2)=pointC;
                    end
                end
            end


            if isnan(inter_point2)
            else
                if (dot((pointA-pointB2),(inter_point2-pointB2))>0)
                    if bout>RSID_database(1).deviation(buildingcount,2)
                        RSID_database(1).deviation(buildingcount,2)=bout;
                        RSID_database(1).terPoint(buildingcount,3:4)=pointD;
                    end
                end
            end



        elseif (face_comb(2).f(i,1)==face_comb(2).f(i-1,1)+1)



            buildingcount=buildingcount+1;
            RSID_database(1).deviation(buildingcount,:)=[ain,bout];

            RSID_database(1).terPoint(buildingcount,:)=terPoint;
            blockflag=0;

        end
    end
end
%建立面面之间可见性的数据库


face_comb_index=1;
face_Rx_comb_index=1;

for i=1:size(face_comb(3).f,1)
    face_block_flag=0;

    pointA=Rx(1,1:2);
    face1Point1=tot_line_inf(face_comb(3).f(i,1)).ter_point(1:2);%一阶面的端点坐标，下同
    face1Point2=tot_line_inf(face_comb(3).f(i,1)).ter_point(3:4);
    if face1Point2(2)>face1Point1(2)||face1Point2(1)>face1Point1(1)
        term=face1Point1;
        face1Point1=face1Point2;
        face1Point2=term;
    end
    face2Point1=tot_line_inf(face_comb(3).f(i,2)).ter_point(1:2);%二阶面的端点坐标，下同
    face2Point2=tot_line_inf(face_comb(3).f(i,2)).ter_point(3:4);
    if face2Point2(2)>face2Point1(2)||face2Point2(1)>face2Point1(1)
        term=face2Point1;
        face2Point1=face2Point2;
        face2Point2=term;
    end



    %先计算没有遮挡的数据


    ain=angle_trans(face2Point1,face1Point1);
    aout=angle_trans(face2Point2,face1Point1);
    bin=angle_trans(face2Point1,face1Point2);
    bout=angle_trans(face2Point2,face1Point2);
    if (ain>aout&&ain<pi)||(ain<aout&&ain>pi)
      term=aout;
      aout=ain;
      ain=term;
    end
    if (bin>bout&&bin<pi)||(bin<bout&&bin>pi)
      term=bout;
      bout=bin;
      bin=term;
    end
    terminal_point=tot_line_inf(face_comb(3).f(i,1)).ter_point;
    block_build_index = face_comb(3).f(i,3);
    block_build_equation=buliding_under(block_build_index).coordinates(:,1:2);

    if  i>1
if  (face_comb(3).f(i,2)==face_comb(3).f(i-1,2))
    ain_ini=RSID_database(1).face_1st(face_Rx_comb_index).deviation(face_comb_index).ain;
    aout_ini=RSID_database(1).face_1st(face_Rx_comb_index).deviation(face_comb_index).aout;
    bin_ini=RSID_database(1).face_1st(face_Rx_comb_index).deviation(face_comb_index).bin;
    bout_ini=RSID_database(1).face_1st(face_Rx_comb_index).deviation(face_comb_index).bout;
else
    ain_ini=ain;
    aout_ini=aout;
    bin_ini=bin;
    bout_ini=bout;
end
    else
     ain_ini=ain;
    aout_ini=aout;
    bin_ini=bin;
    bout_ini=bout;

    end
    %修正可见参数
    for j=1:size(block_build_equation,1)
        if j~=size(block_build_equation,1)
            P1=block_build_equation(j,1:2);
            P2=block_build_equation(j+1,1:2);
            if P2(2)>P1(2)||P2(1)>P1(1)
            term=P2;
            P2=P1;
            P1=term;


            end

            a_in=angle_trans(P1,face1Point1);
            b_in=angle_trans(P1,face1Point2);
            a_out=angle_trans(P2,face1Point1);
            b_out=angle_trans(P2,face1Point2);
            blockPoint1=P1;%遮挡面的端点坐标，下同
            blockPoint2=P2;




        else
            P1=block_build_equation(j,1:2);
            P2=block_build_equation(1,1:2);
            if P1(2)>P2(2)||P1(1)>P2(1)
            term=P2;
            P2=P1;
            P1=term;


            end
            a_in=angle_trans(P1,face1Point1);
            b_in=angle_trans(P1,face1Point2);
            a_out=angle_trans(P2,face1Point1);
            b_out=angle_trans(P2,face1Point2);
            
            blockPoint1=P1;
            blockPoint2=block_build_equation(1,1:2);


        end
        amin=min(a_in,a_out);
            amax=max(a_in,a_out);
            bmin=min(b_in,b_out);
            bmax=max(b_in,b_out);

        [ain_flag,~]=CrossPointLine( face1Point1, face2Point1,blockPoint1,blockPoint2);
        [aout_flag,~]=CrossPointLine( face1Point1, face2Point2,blockPoint1,blockPoint2);
        [bin_flag,~]=CrossPointLine( face1Point2, face2Point1,blockPoint1,blockPoint2);
        [bout_flag,~]=CrossPointLine( face1Point2, face2Point2,blockPoint1,blockPoint2);
        a=0;
        b=0;
        terminal_point=[face1Point1;face1Point2];
        if ((bin_flag&&bout_flag)&&(ain_flag&&aout_flag)) %说明这个面面组合被完全遮挡，不可能产生反射径
            face_block_flag=1;


        elseif (ain_flag&&aout_flag)%说明有一个端点完全被遮挡，需要重新计算端点，下同
            new_ain=angle_trans(P1,face2Point1);
            if abs(new_ain)>abs(a)
                a=new_ain;
                if new_ain>=0
                    ka=tan(pi/2-new_ain);
                else
                    ka=tan(abs(new_ain)-pi/2);
                end
                ha=face2Point2(2)-ka*face2Point2(1);
                AA=[-ka,1;-tot_line_inf(face_comb(3).f(i,1)).equation(1),1];
                BB=[ha;-tot_line_inf(face_comb(3).f(i,1)).equation(2)];
                warning('off', 'all'); % 关闭所有警告
                solution = linsolve(AA, BB);
                new_ter=[solution(1),solution(2)];
                if new_ain<ain
                    terminal_point=[face1Point1;new_ter];
                else
                    terminal_point=[new_ter;face1Point2];
                end

            end




        elseif (bin_flag&&bout_flag)
            if j~=size(block_build_equation,1)
                new_bout=angle_trans(P2,face2Point1);
            else
                new_bout=angle_trans(block_build_equation(1,1:2),face2Point1);
            end
            if abs(new_bout)<abs(b)
                b=new_bout;
                if new_bout>=0
                    kb=tan(pi/2-new_bout);
                else
                    kb=tan(abs(new_bout)-pi/2);
                end
                hb=face1Point1(2)-kb*face1Point1(1);
                AA=[-kb,1;-tot_line_inf(face_comb(3).f(i,1)).equation(1),1];
                BB=[hb;-tot_line_inf(face_comb(3).f(i,1)).equation(2)];
                solution = linsolve(AA, BB);
                new_ter=[solution(1),solution(2)];
                if new_bout>bout
                    terminal_point=[face1Point1;new_ter];
                else
                    terminal_point=[new_ter;face1Point2];
                end
            end


        end
        if ain_flag
            if ain<pi
                if amax>ain_ini
                    ain=a_in;
                end
            else
                if amin<ain_ini
                    ain=a_in;
                end
            end

        end

        if bin_flag
            if bin<pi
                if bmax>bin_ini
                    bin=b_in;
                end
            else
                if bmin<bin_ini
                    bin=b_in;
                end


            end
        end

        if aout_flag
            if aout<pi
                if amin<aout_ini
                    aout=a_out;
                end

            else
                if amax>aout_ini
                    aout=a_out;
                end

            end
        end



        if bout_flag
            if bout<pi
                if bmin<bout_ini
                    bout=b_out;
                end

            else
                if bmax>bout_ini
                    bout=b_out;
                end
            end

        end


    end

    if j==size(block_build_equation,1)
        if a~=0
            ain=a;
        end
        if b~=0
            bout=b;
        end
    end

    if i>1


        if  (face_comb(3).f(i,1)~=face_comb(3).f(i-1,1))%说明1阶面发生了变化
            face_Rx_comb_index=face_Rx_comb_index+1;
            face_comb_index=1;
        end

        if  (face_comb(3).f(i,2)~=face_comb(3).f(i-1,2))&&(face_comb(3).f(i,1)==face_comb(3).f(i-1,1))%说明2阶面发生了变化
            face_comb_index=face_comb_index+1;
        end


    end

    RSID_database(1).face_1st(face_Rx_comb_index).deviation(face_comb_index).ain=ain;
    RSID_database(1).face_1st(face_Rx_comb_index).deviation(face_comb_index).aout=aout;
    RSID_database(1).face_1st(face_Rx_comb_index).deviation(face_comb_index).bin=bin;
    RSID_database(1).face_1st(face_Rx_comb_index).deviation(face_comb_index).bout=bout;

    RSID_database(1).face_1st(face_Rx_comb_index).ter_point(face_comb_index).point1=terminal_point(1,:);
    RSID_database(1).face_1st(face_Rx_comb_index).ter_point(face_comb_index).point2=terminal_point(2,:);
    RSID_database(1).face_1st(face_Rx_comb_index).block_flag(face_comb_index)=face_block_flag;

    RSID_database(1).face_1st(face_Rx_comb_index).comb(face_comb_index,1)=face_comb(3).f(i,1);
    RSID_database(1).face_1st(face_Rx_comb_index).comb(face_comb_index,2)=face_comb(3).f(i,2);

end
%%
%%计算移动的Rx与固定的Rx下，可以形成反射径的Rx的坐标范围
%假设Rx的x坐标范围
X_Rx=[10.000,12.000];
for refIndex=2:RefNum+1
    if refIndex==2
        for faceLineIndex=1:size(tot_line_inf,2)


            % 直线的垂直斜率
            m=tot_line_inf(faceLineIndex).equation(1);
            h=tot_line_inf(faceLineIndex).equation(2);
            m_perpendicular = -1 /m;

            % 计算点到直线的距离
            d = abs(Rx(2) - m * Rx(1) - h) / sqrt(m^2 + 1);

            mirror_point=mirrorPoint(m_perpendicular,Rx(1:2),tot_line_inf(faceLineIndex).ter_point(1:2),d);
           
            valideBoundary(refIndex-1).index(faceLineIndex).comb(1).equation(1,:)=line_equation(mirror_point,RSID_database(1).terPoint(faceLineIndex,1:2));
            valideBoundary(refIndex-1).index(faceLineIndex).comb(1).equation(2,:)=line_equation(mirror_point,RSID_database(1).terPoint(faceLineIndex,3:4));
            count=0;
          




        end


    else%二次及以上反射
        for faceIndex =1:size(tot_line_inf,2)
            for combIndex=1:size(RSID_database(1).face_1st(1).comb,1)
                
                aaa=1;
                if RSID_database(1).face_1st(faceIndex).block_flag(combIndex)==1
                    
                valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).valideflag=0;

                    
                else
                    comb=RSID_database(1).face_1st(faceIndex).comb(combIndex,:);
                    ini_highet=tot_line_inf(comb(2)).equation(4);
                    ter_highet=tot_line_inf(comb(1)).equation(4);
                    limited_flag=0;
                    if  ini_highet> ter_highet
                        ter_point=(RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1+RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1)./2;
                        ini_point=(tot_line_inf(comb(2)).ter_point(1:2)+tot_line_inf(comb(2)).ter_point(3:4))./2;
                        x_ter=ter_point(1);
                        x_ini=ini_point(1);
                        if Rx(1)<=x_ter||Rx(1)>=x_ini%被遮挡，不可能产生反射线
                            % valideBoundary(refIndex-1).index(faceIndex).comb(refIndex).boun_point=NaN;
                            % valideBoundary(refIndex-1).index(faceIndex).comb(refIndex).valideflag=0;
                        else%计算建筑高度约带来的边界条件
                            limited_flag=1;
                            top_linEquation=line_equation(ter_point,ini_point);
                            A= top_linEquation(1);

                            C=top_linEquation(3);
                            underPoint_x=-A/C;
                            middleEquation=line_equation([x_ter,0],[x_ini,0]);
                            AA=middleEquation(1);
                            BB=middleEquation(2);
                            CC=middleEquation(3);

                            underPoint_y=-(AA*underPoint_x+CC)/BB;
                            underPoint=[underPoint_x,underPoint_y];
                            deviation_angle=pi/2-abs(angle_trans([x_ter,0],underPoint));
                            valideDistance=pdist([underPoint;[x_ter,0]],"euclidean")*sin(deviation_angle);

                            lm=tot_line_inf(comb(1)).equation(1);
                            lh=tot_line_inf(comb(1)).equation(2);
                            lm_perpendicular = -1 /lm;
                            ld = abs(underPoint(2) - lm * underPoint(1) - lh) / sqrt(lm^2 + 1);

                            mirror_point=mirrorPoint(lm_perpendicular,underPoint,...
                                RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1,ld);
                            bh= mirror_point(2)-lm_perpendicular* mirror_point(1);

                            limitedEquation=[lm_perpendicular,-1,bh];

                        end%%%%%%%%%%%%%%%%%%%%%%%%%%end if Rx(1)<=x_ter||Rx(1)>=x_ini
                    end %if  ini_highet> ter_highet
                    %%
                    m1=tot_line_inf(comb(2)).equation(1);
                    h1=tot_line_inf(comb(2)).equation(2);
                    m1_perpendicular = -1 /m1;
                    d1 = abs(Rx(2) - m1 * Rx(1) - h1) / sqrt(m1^2 + 1);
                    mirror_point1=mirrorPoint(m1_perpendicular,Rx(1:2),tot_line_inf(comb(2)).ter_point(1:2),d1);

                    a=angle_trans(mirror_point1,RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1);
                    b=angle_trans(mirror_point1,RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2);
                    Ain=RSID_database(1).face_1st(faceIndex).deviation(combIndex).ain;
                    Aout=RSID_database(1).face_1st(faceIndex).deviation(combIndex).aout;
                    Bin=RSID_database(1).face_1st(faceIndex).deviation(combIndex).bin;
                    Bout=RSID_database(1).face_1st(faceIndex).deviation(combIndex).bout;
                    
                   
                    flag1=((a<Aout||abs(a-Aout)<0.087)&&Aout<pi)&&((b>Bin||abs(b-Bin)<0.087)&&Bin<pi);
                    flag2=((a<Aout||abs(a-Aout)<0.087)&&Aout<pi)&&((b<Bin||abs(b-Bin)<0.087)&&Bin>pi);
                    flag3=((a>Aout||abs(a-Aout)<0.087)&&Aout>pi)&&((b>Bin||abs(b-Bin)<0.087)&&Bin<pi);
                    flag4=((a>Aout||abs(a-Aout)<0.087)&&Aout>pi)&&((b<Bin||abs(b-Bin)<0.087)&&Bin>pi);
                   
                    if flag1||flag2||flag3||flag4%能够形成面面反射径的充要条件
                        


                        m2=tot_line_inf(comb(1)).equation(1);
                        h2=tot_line_inf(comb(1)).equation(2);
                        m2_perpendicular = -1 /m2;
                        d2 = abs(mirror_point1(2) - m2 * mirror_point1(1) - h2) / sqrt(m2^2 + 1);
                        mirror_point2=mirrorPoint(m2_perpendicular,mirror_point1,...
                            RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1,d2);

                        flagA=(Ain>a && a<pi)|| (Ain<a && a>pi);
                        flagB=(Bout<b && b<pi)|| (Bout>b && b>pi);
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %%%求边界线方程和边界点坐标
                        
                        if  flagA
                          newter=Cross_pointLine(mirror_point1,tot_line_inf(comb(2)).ter_point(1:2),...
                                RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1,RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2);
                            if isnan(newter)
                                newline=[RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1;RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2];
                            else
                                dis1=pdist([newter;RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1],"euclidean");
                                dis2=pdist([newter;RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2],"euclidean");
                                if dis1<dis2
                                    newline=[newter;RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2];
                                else
                                    newline=[RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1;newter];
                                end
                            end
                            valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).equation(1,:)=line_equation(mirror_point2,newline(1,:));
                            valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).equation(2,:)=line_equation(mirror_point2,newline(2,:));
                             valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).valideflag=1;
                        elseif flagB
                           newter=Cross_pointLine(mirror_point1,tot_line_inf(comb(2)).ter_point(3:4),...
                                RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1,RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2);
                            if isnan(newter)
                                newline=[RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1;RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2];
                            else
                                dis1=pdist([newter;RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1],"euclidean");
                                dis2=pdist([newter;RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2],"euclidean");
                                if dis1<dis2
                                    newline=[newter;RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2];
                                else
                                    newline=[RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1;newter];
                                end
                            end

                            valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).equation(1,:)=line_equation(mirror_point2,newline(1,:));
                            valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).equation(2,:)=line_equation(mirror_point2,newline(2,:));
                             valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).valideflag=1;
                        else
                         valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).equation(1,:)=...
                             line_equation(mirror_point2,RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point1);
                         valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).equation(2,:)=...
                             line_equation(mirror_point2,RSID_database(1).face_1st(faceIndex).ter_point(combIndex).point2);
                          valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).valideflag=1;
                     
                       
                        end
                if limited_flag==1
                    valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).equation(1,:)=limitedEquation;
                end

                   
                       else
                        valideBoundary(refIndex-1).index(faceIndex).comb(combIndex).valideflag=0;
                      end
                    
                   
                    end
                
            end% end combIndex
        end%end faceIndex
    end
end




RSID_Info.valideBoundary=valideBoundary;
RSID_Info.tot_line_inf=tot_line_inf;
RSID_Info.RSID_database=RSID_database;
RSID_Info.buliding_under=buliding_under;
RSID_Info.building_index=building_index;
save([Outputpath '\RSIDdata.mat'],'valideBoundary','RSID_database','building_index','buliding_under','tot_line_inf') ;
function [BuildingInfo,SetInfo,GeoInfo,Outputpath] = Search_path_Image1(Inputpath,Output,SearchPathSet)
%   反向单核寻径单核函数，包含画图，将寻径结果Geo存储在对应路径下，加入二阶绕射
LOS = SearchPathSet(1,1);%直射=1/0，是/否需要直射
RefNum = SearchPathSet(2,1);%反射次数=Any，可调
DifNum = SearchPathSet(3,1);%绕射次数=1/0
PeneNum = SearchPathSet(4,1);%穿透次数限制，可调
%xml文件位置
load([Inputpath '\EnvirormentData.mat'],'BuildingInfo','FaceCoordinates','FaceEquation','FaceNum');
load([Inputpath '\FaceCombination.mat'],'fp','fpDif');
load([Inputpath '\TxRxData.mat'],'TxCAl','RxCal');
Tx = TxCAl;
posInRx=RxCal;
RxNum=size(posInRx,1);

SetInfo = struct('RXNum',[],'RefNum',[],'DifNum',[],'PeneNum',[],'DisLimit',[]);
%RT几何计算结果信息：发端点坐标，收端点坐标，直射信息，反射信息，绕射信息
GeoInfo = struct('Startpoint',[],'Finishpoint',[],'LosInfo',[],'RefInfo',[],'DifInfo',[],'Ray_sum',[]);

%保存mat位置
if ~exist([Output '\Los',num2str(LOS),'Ref',num2str(RefNum),'Dif',num2str(DifNum),'Pe',num2str(PeneNum)])%将最大反射数和最大穿透数放进文件夹名
    mkdir([Output '\Los',num2str(LOS),'Ref',num2str(RefNum),'Dif',num2str(DifNum),'Pe',num2str(PeneNum)]);
end
Outputpath = [Output  '\Los',num2str(LOS),'Ref',num2str(RefNum),'Dif',num2str(DifNum),'Pe',num2str(PeneNum)];
%光程限制
f =SearchPathSet(5,1)/1000;%频率(GHz)，可调
PL = 120;%损耗pathloss(dB)，可调
dmax = 10^( ( PL-32.4-20*log10(f) )./20 );%(单位m)
% TR38.900 InH-Office LOS：PL=32.4+17.3*log10(D)+20*log10(F) 对高频不一定准确

BuildingInfo.TXInfo = Tx;%发端
BuildingInfo.RXInfo = posInRx;%收端
%存储仿真设置信息
SetInfo.RXNum = RxNum;
SetInfo.RefNum = RefNum;
SetInfo.DifNum = DifNum;
SetInfo.PeneNum = PeneNum;
SetInfo.DisLimit = dmax;

for index_Rx = 1:RxNum%每个接收点分别运行
    RaySum=0;
    difnum1=1;
    Rx = posInRx(index_Rx,:);%接收端坐标
    Tx=TxCAl(index_Rx,:);
    pointTx(1,:) = Tx(1,:);
    %%
    %Los
    %收发端信息用Tx,Rx
    LosInfo(index_Rx) = struct('Pe',[]);%这个就是Ge信息里的LOSInfor
    %Penetration穿透信息变量，后面Penetration要给Pe赋值用： Tx、Rx、面序号、面坐标、穿透点
    TemPeneRef0 = struct('Startpoint',[],'Finishpoint',[],'IndexFace',[],'Face',[],'PenePoint',[]);%避免存储错误，穿透信息
    PeneNumInOnePath = 0;%PeneNumInOnePath代表某1条径发生了几次穿透，LOS情况下t1的含义与t2相同
    %PeneNumInOnePath：也就是LOS有几次透射
    for indexFace = 1:FaceNum
        %判断收发是否在面两侧
        if(roundn((FaceEquation(indexFace,1)*Tx(1,1)+FaceEquation(indexFace,2)*Tx(1,2)+FaceEquation(indexFace,3)*Tx(1,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*Rx(1,1)+FaceEquation(indexFace,2)*Rx(1,2)+FaceEquation(indexFace,3)*Rx(1,3)+FaceEquation(indexFace,4)),-2) <0)
            %The purpose of "roundn" is avoiding mistake because of decimal digits in calculating process
            %Crosspoint，计算线与面的交点
            pointCross = CrosspointLineFace(Tx(1,:),Rx(1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));%计算透射点
            %Judge Crosspoint in Face 如果算出的交点在面上的话，则该路径上的穿透数+1
            if (CpInFace2(pointCross,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))%该函数判断点是否在面上
                PeneNumInOnePath = PeneNumInOnePath+1;
                PointAllPene(PeneNumInOnePath,:)=pointCross;%储存要画的点，即穿透点，与PenePoint一样
                TemPeneRef0(PeneNumInOnePath,1)=Penetration(Tx(1,:),Rx(1,:),FaceCoordinates(indexFace).Face(:,:),indexFace,FaceEquation(indexFace,:));
            end
        end
    end
    if LOS==1 %RT设置LOS存在
        %Distance limit
        d_pq = sqrt( (Tx(1,1)-Rx(1,1))^2+(Tx(1,2)-Rx(1,2))^2+(Tx(1,3)-Rx(1,3))^2 );%pq距离
        if d_pq<=dmax%<=极限距离时才能存在LOS
            if (PeneNumInOnePath<=PeneNum)&&(PeneNumInOnePath~=0)%保证发生了穿透且小于规定次数
                %储存数据
                d=[];%起点到穿透点的距离
                for i = 1:PeneNumInOnePath
                    d(i)=sum((TemPeneRef0(i).PenePoint-TemPeneRef0(i).Startpoint).^2);
                end
                [d_srot,d_right]=sort(d);%排序
                sym_pe=0;
                for i = 1:PeneNumInOnePath%储存pe信息
                    LosInfo(index_Rx).Pe(i,1)=1;%直射径只有一条，径标号为1
                    LosInfo(index_Rx).Pe(i,2)=1;%透射，所以赋值为1
                    LosInfo(index_Rx).Pe(i,3:5)=TemPeneRef0(d_right(i)).PenePoint;%赋值穿透点坐标
                    LosInfo(index_Rx).Pe(i,6)=TemPeneRef0(d_right(i)).IndexFace;%赋值面的编号
                    sym_pe=sym_pe+1;
                    if sym_pe==PeneNumInOnePath
                        LosInfo(index_Rx).Pe(i,7)=0;
                    else
                        LosInfo(index_Rx).Pe(i,7)=1;
                    end

                end
            elseif PeneNumInOnePath==0
                LosInfo(index_Rx).Pe(1,1) = 1;%第几段中的穿透，直射中只有一段路径，所以直接赋1
                LosInfo(index_Rx).Pe(1,2) = 0;%无透射，赋值为0

            end
            if (PeneNumInOnePath<=PeneNum)%判断是否满足条件 穿透次数的要求
                RaySum=RaySum+1;
            end
        end
    end
    %%
    %反射
    RefInfo(index_Rx).Ref = struct('Detail',[]);
    refnum = 0;
    %结构就是：
    %RefInfo为index_Rx*1的struct，内部字段为Ref，是RefNum*1的struct，内部字段为Detail，维度是可以发生的反射径的个数，ii
    for numRefIndex = 1:RefNum%f几次反射
        RefInfo(index_Rx).Ref(numRefIndex) = struct('Detail',[]);%Detail的维度为可通反射径的数量ii
        ii = 0;%可通反射径的数量，即下面的面面组合的径通不通就是ii
        %         F = struct('Fany',[]);%储存面方程
        %         Polygon = struct('Poly',[]);%储存面的四个点坐标
        for arryIndex=1:size(fp(numRefIndex).f,1)
            %arryIndex是此反射数下的面面数组数
            for combinFaceIndex = 1:size(fp(numRefIndex).f(arryIndex,1).Detail,1)%索引N次反射面的组合数  kk 组合的索引
                %这是一个很大的循环，就是对所有的面面组合进行遍历，看看能不能满足镜面反射径的要求
                F = struct('Fany',[]);%储存面方程
                Polygon = struct('Poly',[]);%储存面的四个点坐标
                F(numRefIndex).Fany = [];%初始化
                Polygon(numRefIndex).Poly =struct('Inter',[]);
                for i = 1:numRefIndex%f是N次反射
                    %从面的数据库中取出反射面组合的index对应的面的信息存在两个变量中，面方程，面点坐标
                    F(numRefIndex).Fany(i,:) = FaceEquation(fp(numRefIndex).f(arryIndex,1).Detail(combinFaceIndex,i),:);
                    Polygon(numRefIndex).Poly(i,:).Inter(:,:) = FaceCoordinates(fp(numRefIndex).f(arryIndex,1).Detail(combinFaceIndex,i)).Face(:,:);
                end
                %p存储反射点%利用镜像法寻找反射点
                %MirrorPoint
                for i=1:numRefIndex
                    d(i)=(F(numRefIndex).Fany(i,1)*pointTx(i,1)+F(numRefIndex).Fany(i,2)*pointTx(i,2)+F(numRefIndex).Fany(i,3)*pointTx(i,3)+F(numRefIndex).Fany(i,4))/(F(numRefIndex).Fany(i,1)^2+F(numRefIndex).Fany(i,2)^2+F(numRefIndex).Fany(i,3)^2);
                    s(i,:) = [pointTx(i,1)-F(numRefIndex).Fany(i,1)*d(i),pointTx(i,2)-F(numRefIndex).Fany(i,2)*d(i),pointTx(i,3)-F(numRefIndex).Fany(i,3)*d(i)];
                    pointTx(i+1,:)  = [pointTx(i,1)-2*F(numRefIndex).Fany(i,1)*d(i),pointTx(i,2)-2*F(numRefIndex).Fany(i,2)*d(i),pointTx(i,3)-2*F(numRefIndex).Fany(i,3)*d(i)];
                end
                pointTx(numRefIndex+2,:) = Rx;%将收端放到p(end,:)  pointTx：不是反射点，是发端镜像点

                InPolygon = [];%判断反射点是否在面上
                InPolygon1 = [];
                eq = [];%判断相邻反射点是否相同（对于一次反射来说，没用）
                pointCross = [];%存储反射点，一个路径的反射点，N次反射的维度为N*3
                %CrosspointLineFace 穿过面的线的交点，计算反射点坐标，只计算了最后的
                pointCross(numRefIndex,:) = CrosspointLineFace(pointTx(numRefIndex+1,:),pointTx(numRefIndex+2,:),F(numRefIndex).Fany(numRefIndex,:),s(numRefIndex,:));
                %pointCross(numRefIndex,:) = roundn(pointCross(numRefIndex,:),-5);%四舍五入

                %，计算Pointcross里除最后一个外前面的反射点
                for i=(numRefIndex-1):-1:1
                    pointCross(i,:) = CrosspointLineFace(pointCross(i+1,:),pointTx(i+1,:),F(numRefIndex).Fany(i,:),s(i,:));
                    %pointCross(i,:) = roundn(pointCross(i,:),-5);
                end
                %over
                %这时候，Pointcross便是N维的了，每一维是一个反射点

                %判断反射点是否在对应面上

                for i = 1:numRefIndex%判断反射点是否在对应面上
                    %InPolygon(i) = CpInFace(pointCross(i,:),Polygon(numRefIndex).Poly(i,:).Inter(:,:));
                    [InPolygon1(i),on_edge(i)]=CpInFace2(pointCross(i,:),F(numRefIndex).Fany(i,:),Polygon(numRefIndex).Poly(i,:).Inter(:,:));
                end
                if numRefIndex==1%如果是一次反射，
                    eq = 1;
                else
                    for i = 2:numRefIndex
                        eq(i-1) = ~isequal(pointCross(i-1,:),pointCross(i,:));%判断相邻反射点是否为相同，相同0，不同1
                    end
                end
                %disp((prod(InPolygon) ))%有的面（面组合）没进下边的判断语句
                if (prod(InPolygon1) == 1)&&(prod(eq) == 1)&&(~(sum(on_edge) == 1))%能保证相邻反射点不为同一点，即排除了相临反射点在两面交线上（类似于绕射）
                    %                     &&(r1(1,1)~=r2(1,1))&&(r1(1,2)~=r2(1,2))&&(r1(1,3)~=r2(1,3))  %r1和r2不能为同一点（若为同一点，则为两面交线上的一点）
                    %disp()
                    %判断发端与 2号反射点必须在1号反射面的同侧，1号反射点与3号反射点必须在2号反射面的同侧，以此类推~
                    Judge2Sides1 = [];
                    if numRefIndex==1
                        Judge2Sides1(1,1) = roundn((F(numRefIndex).Fany(1,1)*pointTx(1,1)+F(numRefIndex).Fany(1,2)*pointTx(1,2)+F(numRefIndex).Fany(1,3)*pointTx(1,3)+F(numRefIndex).Fany(1,4))*(F(numRefIndex).Fany(1,1)*pointTx(end,1)+F(numRefIndex).Fany(1,2)*pointTx(end,2)+F(numRefIndex).Fany(1,3)*pointTx(end,3)+F(numRefIndex).Fany(1,4)),-2) ;%一次反射判断收发段是否在反射面两侧
                    else
                        Judge2Sides1(1,1) = roundn((F(numRefIndex).Fany(1,1)*pointTx(1,1)+F(numRefIndex).Fany(1,2)*pointTx(1,2)+F(numRefIndex).Fany(1,3)*pointTx(1,3)+F(numRefIndex).Fany(1,4))*(F(numRefIndex).Fany(1,1)*pointCross(2,1)+F(numRefIndex).Fany(1,2)*pointCross(2,2)+F(numRefIndex).Fany(1,3)*pointCross(2,3)+F(numRefIndex).Fany(1,4)),-2) ;
                        for i = 2:(numRefIndex-1)
                            Judge2Sides1(1,i) = roundn((F(numRefIndex).Fany(i,1)*pointCross(i-1,1)+F(numRefIndex).Fany(i,2)*pointCross(i-1,2)+F(numRefIndex).Fany(i,3)*pointCross(i-1,3)+F(numRefIndex).Fany(i,4))*(F(numRefIndex).Fany(i,1)*pointCross(i+1,1)+F(numRefIndex).Fany(i,2)*pointCross(i+1,2)+F(numRefIndex).Fany(i,3)*pointCross(i+1,3)+F(numRefIndex).Fany(i,4)),-2) ;
                        end
                        Judge2Sides1(1,end+1) = roundn((F(numRefIndex).Fany(end,1)*pointTx(end,1)+F(numRefIndex).Fany(end,2)*pointTx(end,2)+F(numRefIndex).Fany(end,3)*pointTx(end,3)+F(numRefIndex).Fany(end,4))*(F(numRefIndex).Fany(end,1)*pointCross(end-1,1)+F(numRefIndex).Fany(end,2)*pointCross(end-1,2)+F(numRefIndex).Fany(end,3)*pointCross(end-1,3)+F(numRefIndex).Fany(end,4)),-2) ;
                    end
                    %zzf修改
                    %judgeFlag为判断此路径是否通路
                    judgeFlag = 1;
                    for judgeIndex = 1 : length(Judge2Sides1)
                        if(Judge2Sides1(judgeIndex) < 0)
                            judgeFlag = 0;
                        end
                    end
                    %disp(judgeFlag)
                    if(judgeFlag == 1)
                        %修改结束
                        %Distance limit
                        d(1) = sqrt( (pointTx(1,1)-pointCross(1,1))^2+(pointTx(1,2)-pointCross(1,2))^2+(pointTx(1,3)-pointCross(1,3))^2 );%第一段距离
                        for i =1:numRefIndex-1
                            d(i+1) = sqrt( (pointCross(i,1)-pointCross(i+1,1))^2+(pointCross(i,2)-pointCross(i+1,2))^2+(pointCross(i,3)-pointCross(i+1,3))^2 );%中间段距离
                        end
                        d(numRefIndex+1) = sqrt( (pointTx(numRefIndex+2,1)-pointCross(numRefIndex,1))^2+(pointTx(numRefIndex+2,2)-pointCross(numRefIndex,2))^2+(pointTx(numRefIndex+2,3)-pointCross(numRefIndex,3))^2 );%最后一段距离
                        dd = roundn(sum(d),-4);
                        if dd<=dmax%距离限制
                            %disp('********下进行穿透限制计算*************')

                            % 目前思路：不能分q1-r2，r2-r1等这些段了，用一种综合的办法来判断，p(1)-r(1)-...-r(n)-p(2)，每一小段的穿透信息存储，以及加起来总的穿透次数限制
                            %Penetration下面进行穿透计算
                            %这个变量就是储存穿透信息的，前后俩就一维结构体，中间多维结构体
                            TemPeneRef_rnq=struct('Startpoint',[],'Finishpoint',[],'IndexFace',[],'Face',[],'PenePoint',[]);%Qn到Rx子径的穿透信息
                            TemPeneRef=struct('rr',[]);
                            TemPeneRef.rr=struct('Startpoint',[],'Finishpoint',[],'IndexFace',[],'Face',[],'PenePoint',[]); %Q1-Qn子径的穿透信息，N-1
                            TemPeneRef_prl=struct('Startpoint',[],'Finishpoint',[],'IndexFace',[],'Face',[],'PenePoint',[]);%Tx-Q1子径的穿透信息
                            pe = struct('rr',[]);%避免存储错误

                            %p-r1 Tx到Q1
                            peneNum = 0;%穿透点的序号（个数），指的是Tx与Q1的穿透点
                            for indexFace = 1:FaceNum%逐面判断是否有穿透点
                                if(roundn((FaceEquation(indexFace,1)*pointTx(1,1)+FaceEquation(indexFace,2)*pointTx(1,2)+FaceEquation(indexFace,3)*pointTx(1,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*pointCross(1,1)+FaceEquation(indexFace,2)*pointCross(1,2)+FaceEquation(indexFace,3)*pointCross(1,3)+FaceEquation(indexFace,4)),-2) <0)
                                    %The purpose of "ceil" is avoiding mistake because of decimal digits in calculating process
                                    %%%%%
                                    %%%=======================================
                                    %%%
                                    %Penepoint为TX与Q1这条路径与该面的穿透交点
                                    pointPene = CrosspointLineFace(pointTx(1,:),pointCross(1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                    %Judge Crosspoint in Face 如果交点在该面上
                                    if (CpInFace2(pointPene,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                        peneNum = peneNum+1;%穿透点的个数
                                        pe_prl(peneNum,:)=pointPene;%穿透点
                                        %穿透信息中间变量，感觉是为了不影响原始穿透信息变量的值才存在的东西？
                                        TTPeneRef_prl(peneNum,1)=Penetration(pointTx(1,:),pointCross(1,:),FaceCoordinates(indexFace).Face(:,:),indexFace,FaceEquation(indexFace,:));
                                    end
                                end
                            end
                            %对穿透点排序
                            d33=[];
                            for i = 1:peneNum
                                d33(i)=sum((TTPeneRef_prl(i).PenePoint-TTPeneRef_prl(i).Startpoint).^2);
                            end
                            [d_srot,d33_right]=sort(d33);%排序
                            for i = 1:peneNum
                                TemPeneRef_prl(i)=TTPeneRef_prl(d33_right(i));
                            end
                            if peneNum==0
                                TemPeneRef_prl=[];
                            end


                            %r(n-1)-rn  判断pointRef(n-1)到pointRef(n)间的穿透点
                            t32 = 0;%子径穿透数
                            for i = 1:(numRefIndex-1)%反射点-1个中间子径
                                t32(i) = 0;
                                for indexFace = 1:FaceNum
                                    if(roundn((FaceEquation(indexFace,1)*pointCross(i,1)+FaceEquation(indexFace,2)*pointCross(i,2)+...
                                            FaceEquation(indexFace,3)*pointCross(i,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*pointCross(i+1,1)+...
                                            FaceEquation(indexFace,2)*pointCross(i+1,2)+FaceEquation(indexFace,3)*pointCross(i+1,3)+FaceEquation(indexFace,4)),-2) <0)
                                        %The purpose of "ceil" is avoiding mistake because of decimal digits in calculating process
                                        %Penepoint
                                        pointCrossInPene = CrosspointLineFace(pointCross(i,:),pointCross(i+1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                        %Judge Crosspoint in Face如果交点在面上
                                        if (CpInFace2(pointCrossInPene,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                            t32(i) = t32(i)+1;%储存相应反射径的穿透数
                                            pe(i).rr(t32(i),:)= pointCrossInPene;%穿透点 疑问：pe.rr没有初始化
                                            %TTPeneRef.rr(t32(i),1)=Penetration(pointCross(i,:),pointCross(i+1,:),FaceCoordinates(indexFace).Face(:,:),indexFace);
                                            TTPeneRef(i).rr(t32(i),1)=Penetration(pointCross(i,:),pointCross(i+1,:),FaceCoordinates(indexFace).Face(:,:) ,indexFace,FaceEquation(indexFace,:));
                                        end
                                    end
                                end
                                %对穿透点排序
                                d32=[];
                                for k = 1:t32(i)
                                    d32(k)=sum((TTPeneRef(i).rr(k,1).PenePoint-TTPeneRef(i).rr(k,1).Startpoint).^2);
                                end
                                %%%%%%%%%%%%%9月1日
                                [~,d32_right]=sort(d32);%排序
                                for k = 1:t32(i)
                                    TemPeneRef(i).rr(k,1)=TTPeneRef(i).rr(d32_right(k),1);
                                end
                                if t32(i)==0
                                    pe(i).rr = [];
                                    TemPeneRef(i).rr=[];
                                end

                            end
                            %rn-q 计算Qn到Rx的穿透
                            t31 = 0;
                            for indexFace = 1:FaceNum
                                if(roundn((FaceEquation(indexFace,1)*pointCross(numRefIndex,1)+FaceEquation(indexFace,2)*pointCross(numRefIndex,2)+FaceEquation(indexFace,3)*pointCross(numRefIndex,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*pointTx(numRefIndex+2,1)+FaceEquation(indexFace,2)*pointTx(numRefIndex+2,2)+FaceEquation(indexFace,3)*pointTx(numRefIndex+2,3)+FaceEquation(indexFace,4)),-2) <0)
                                    %The purpose of "roundn" is avoiding mistake because of decimal digits in calculating process
                                    %Penepoint
                                    r31 = CrosspointLineFace(pointCross(numRefIndex,:),pointTx(numRefIndex+2,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                    %Judge Crosspoint in Face判断点是否在面上
                                    if (CpInFace2(r31,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                        t31 = t31+1;
                                        pe_rnq(t31,:)=r31;
                                        %TTPeneRef_rnq=Penetration(pointTx(1,:),pointCross(1,:),FaceCoordinates(indexFace).Face(:,:),indexFace);
                                        TTPeneRef_rnq(t31,1)=Penetration(pointCross(numRefIndex,:),pointTx(numRefIndex+2,:),FaceCoordinates(indexFace).Face(:,:),indexFace,FaceEquation(indexFace,:));
                                    end
                                end
                            end
                            %对穿透点排序
                            d31=[];
                            for i =1:t31
                                d31(i)=sum((TTPeneRef_rnq(i).PenePoint-TTPeneRef_rnq(i).Startpoint).^2);
                            end
                            [~,d31_right]=sort(d31);
                            for i =1:t31
                                TemPeneRef_rnq(i)=TTPeneRef_rnq(d31_right(i));
                            end
                            if t31==0
                                TemPeneRef_rnq=[];
                            end
                            %至此，所有的穿透信息计算完毕，下面进行信息的保存
                            t32_ = sum(t32);
                            t30 = t31+t32_+peneNum;%总的穿透数
                            %disp(t30);
                            if (t30<=PeneNum)%穿透限制，有的没用通过穿透限制
                                refnum = refnum+1;%穿透路径数
                                RaySum=RaySum+1;
                                ii = ii+1;%可以进行储存，画图的面组合,即反射径的序号
                                RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Refpoint = pointCross;%储存反射点坐标
                                for iii = 1:numRefIndex%储存反射面序号
                                    RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Refpoint(iii,4) = fp(numRefIndex).f(arryIndex,1).Detail(combinFaceIndex,iii);%每个反射点在的面标号，存在反射坐标后
                                end
                                %===============================================
                                %保存穿透信息：给Pe赋值
                                %pr1段，
                                if (peneNum~=0)
                                    sym_pe=0;
                                    for i = 1:peneNum%储存pe信息
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(i,1)=1;%该反射径的第一条段径
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(i,2)=1;%有透射
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(i,3:5)=TemPeneRef_prl(i).PenePoint;%穿透坐标
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(i,6)=TemPeneRef_prl(i).IndexFace;%面的编号
                                        sym_pe=sym_pe+1;
                                        if sym_pe==peneNum
                                            RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(i,7)=0;
                                        else
                                            RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(i,7)=1;
                                        end
                                    end
                                elseif peneNum==0
                                    RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(1,1) = 1;
                                    RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(1,2) = 0;
                                    peneNum = 1;%方便下一段存储   这里才变成1了
                                end
                                %Q1-Qn即中间反射径段
                                if (t32_~=0)
                                    for k = 1:(numRefIndex-1)%对每一个中间段进行索引
                                        if t32(k)==0%若次段没有穿透，则设置pe(K+1,0)
                                            RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end+1,1) = k+1;
                                            RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,2) = 0;
                                        else%否则，进行pe的具体赋值
                                            sym_pe = 0;
                                            for i = 1:t32(k)
                                                RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end+1,1) = k+1;%该反射径的
                                                RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,2) = 1;
                                                RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,3:5) = TemPeneRef(k).rr(i).PenePoint;
                                                RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,6) = TemPeneRef(k).rr(i).IndexFace;%面的标号指的是FOringal里面的行数，这指定了一个唯一的面，并且每个面有一个唯一的标号
                                                sym_pe = sym_pe+1;
                                                if sym_pe==t32(k)
                                                    RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,7) = 0;
                                                else
                                                    RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,7) = 1;
                                                end
                                            end
                                        end
                                    end
                                elseif t32_==0%如果整条路径都没有穿透，则以此赋值Pe
                                    for i = 1:(numRefIndex-1)
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end+1,1) = peneNum+i;
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,2) = 0;
                                    end
                                end

                                %rnq段
                                if (t31~=0)%保证发生了穿透并且穿透次数少于规定次数
                                    sym_pe = 0;
                                    for i = 1:t31
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end+1,1) = numRefIndex+1;
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,2) = 1;
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,3:5) = TemPeneRef_rnq(i).PenePoint;
                                        RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,6) = TemPeneRef_rnq(i).IndexFace;%面的标号指的是FOringal里面的行数，这指定了一个唯一的面，并且每个面有一个唯一的标号
                                        sym_pe = sym_pe+1;
                                        if sym_pe==t31
                                            RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,7) = 0;
                                        else
                                            RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,7) = 1;
                                        end
                                    end
                                elseif t31==0
                                    RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end+1,1) = numRefIndex+1;
                                    RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).Pe(end,2) = 0;
                                end
                                %尝试储存一下pointTx
                                RefInfo(index_Rx).Ref(numRefIndex).Detail(ii).PointTx=pointTx;
                            end
                        end
                    end
                end
            end
        end
    end
    %%
    %绕射
    %收发段信息用p1,q1
    DifInfo(index_Rx) = struct('Dif',[]);
    DifInfo(index_Rx).Dif = struct('Detail',[]);
    Difnum = DifNum;
    if (DifNum~=0) %如果需要计算绕射，无论几次绕射都需要先计算一阶绕射
        pointDif = [];
        CombinNuminDif1 = fpDif(1).CombinNuminDif.Detail;
        for numDifIndex=1:size(CombinNuminDif1,1)%找到面的两两组合，只需找两个面即可
            numsCoorEqualtoTwoFace = 0;%判断两个面上有多少个相同的沿边点
            %找到要绕射的两个面
            FaceDifEquation(1,:) = FaceEquation(CombinNuminDif1(numDifIndex,1),:);
            FaceDifEquation(2,:) = FaceEquation(CombinNuminDif1(numDifIndex,2),:);
            size1 = size(FaceCoordinates(CombinNuminDif1(numDifIndex,1)).Face(:,:),1);%面的边沿点有几个
            size2 = size(FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(:,:),1);
            for m = 1:size1
                for n = 1:size2
                    %判断两个面上是否有相同的点 即两个面上的边沿点是否存在相同的
                    if(FaceCoordinates(CombinNuminDif1(numDifIndex,1)).Face(m,:)==FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(n,:))
                        numsCoorEqualtoTwoFace = numsCoorEqualtoTwoFace+1;%相同沿边点的个数+1
                        point_Intsect(numsCoorEqualtoTwoFace,:) = FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(n,:);
                        if numsCoorEqualtoTwoFace==2
                            break;
                        end
                    end
                end
                if numsCoorEqualtoTwoFace==2%有两个沿边点是相同的，就直接跳出循环
                    break;
                end
            end
            if numsCoorEqualtoTwoFace==2
                x3(1) = Tx(1,1);y3(1) = Tx(1,2);z3(1) = Tx(1,3);%Tx
                x3(2) = Rx(1,1);y3(2) = Rx(1,2);z3(2) = Rx(1,3);%Rx
                point_Pro = [];
                %求出可能的绕射点坐标，利用相似三角形
                for i = 1:2
                    x1 = point_Intsect(1,1);y1 = point_Intsect(1,2);z1 = point_Intsect(1,3);
                    x2 = point_Intsect(2,1);y2 = point_Intsect(2,2);z2 = point_Intsect(2,3);
                    t(i) = ((x1 - x2)*(x1 - x3(i)) + (y1 - y2)*(y1 - y3(i)) + (z1 - z2)*(z1 - z3(i)))/((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2);
                    x = x1+(x2-x1)*t(i);
                    y=y1+(y2-y1)*t(i);
                    z=z1+(z2-z1)*t(i);
                    point_Pro(i,:) = [x y z];%point_Intsect到棱上的投影
                    dq(i) = sqrt((point_Pro(i,1)-x3(i))^2+(point_Pro(i,2)-y3(i))^2+(point_Pro(i,3)-z3(i))^2);
                end
                pointDif(:,:) = (dq(1)*point_Pro(2,:)/(dq(1)+dq(2)))+(dq(2)*point_Pro(1,:)/(dq(1)+dq(2)));%求出可能的绕射点坐标
                pointDif(:,:) = roundn(pointDif(:,:),-4);
                condition = 0;% 这个变量来去除Tx,Rx一内一外，绕射点正好在棱的端点这种情况
                if (all(pointDif == point_Intsect(1,:)) || all(pointDif == point_Intsect(2,:))) && (PeneNumInOnePath ~= 0)
                       condition = 1;
                end
                if ~condition %避免Tx,Rx一内一外，绕射点正好在棱的端点这种情况
                    %判断起点和终点与两个面的位置关系，如果是同侧且绕射点在棱上，一定会发生绕射，否则需要进行降维判断
                    for i = 1:2
                        %收发点到两个面的距离
                        m01(i) = FaceDifEquation(i,1)*Tx(1,1)+FaceDifEquation(i,2)*Tx(1,2)+FaceDifEquation(i,3)*Tx(1,3)+FaceDifEquation(i,4);%Tx到第一个面的向量距离
                        m02(i) = FaceDifEquation(i,1)*Rx(1,1)+FaceDifEquation(i,2)*Rx(1,2)+FaceDifEquation(i,3)*Rx(1,3)+FaceDifEquation(i,4);%Rx到第一个面的向量距离
                        %点到面的距离之乘积
                        %m(i)=d(Tx,Fi)*d(Rx,Fi)
                    end
                    judge = 0;
                    if (((m01(1)>0)&&(m02(1)>0)) || ((m01(1)<0)&&(m02(1)<0))) && (((m01(2)>0)&&(m02(2)>0)) || ((m01(2)<0)&&(m02(2)<0)))%同侧需要满足的条件
                        l1 = (min(point_Intsect(:,1)) <= pointDif(1,1)) && (pointDif(1,1)<= max(point_Intsect(:,1)));%下面是判断绕射点是否在棱上
                        l2 = (min(point_Intsect(:,2)) <= pointDif(1,2)) && (pointDif(1,2)<= max(point_Intsect(:,2)));
                        l3 = (min(point_Intsect(:,3)) <= pointDif(1,3)) && (pointDif(1,3)<= max(point_Intsect(:,3)));
                        if (l1 && l2 && l3)
                            judge = 1;%如果满足同侧且绕射点在棱上，judge赋值为1
                        end
                    else
                        pointCross = [];ifPointOnFace=[];
                        %判断起点与终点的连线是不是与两个面有交点？有交点则不能发生绕射
                        for i = 1:2
                            pointCross(i,:) = CrosspointLineFace(Rx(1,:),Tx(1,:),FaceDifEquation(i,:),point_Intsect(1,:));
                            ifPointOnFace(i) = CpInFace2(pointCross(i,:),FaceDifEquation(i,:),FaceCoordinates(CombinNuminDif1(numDifIndex,i)).Face(:,:));
                        end
                        if all(ifPointOnFace == 0)
                            %进行降维判断，只要l1,l2,l3有一个满足就可以发生绕射，judge赋值为1
                            Q=[];
                            s_in=sqrt((pointDif(1,1)-x3(1))^2+(pointDif(1,2)-y3(1))^2 );
                            s_out=sqrt((pointDif(1,1)-x3(2))^2+(pointDif(1,2)-y3(2))^2 );
                            Q(1,3)=z3(1)+(z3(2)-z3(1))*(s_in/(s_in+s_out));
                            s_in=sqrt((pointDif(1,2)-y3(1))^2+(pointDif(1,3)-z3(1))^2 );
                            s_out=sqrt((pointDif(1,2)-y3(2))^2+(pointDif(1,3)-z3(2))^2 );
                            Q(1,1)= x3(1)+(x3(2)-x3(1))*(s_in/(s_in+s_out));
                            s_in=sqrt((pointDif(1,1)-x3(1))^2+(pointDif(1,3)-z3(1))^2 );
                            s_out=sqrt((pointDif(1,1)-x3(2))^2+(pointDif(1,3)-z3(2))^2 );
                            Q(1,2)= y3(1)+(y3(2)-y3(1))*(s_in/(s_in+s_out));
                            l1 = (min(point_Intsect(:,1)) <= Q(1,1)) && (Q(1,1)<= max(point_Intsect(:,1)));
                            l2 = (min(point_Intsect(:,2)) <= Q(1,2)) && (Q(1,2)<= max(point_Intsect(:,2)));
                            l3 = (min(point_Intsect(:,3)) <= Q(1,3)) && (Q(1,3)<= max(point_Intsect(:,3)));
                            l4 = (min(point_Intsect(:,1)) <= pointDif(1,1)) && (pointDif(1,1)<= max(point_Intsect(:,1)));%下面是判断绕射点是否在棱上
                            l5 = (min(point_Intsect(:,2)) <= pointDif(1,2)) && (pointDif(1,2)<= max(point_Intsect(:,2)));
                            l6 = (min(point_Intsect(:,3)) <= pointDif(1,3)) && (pointDif(1,3)<= max(point_Intsect(:,3)));
                            if (l1 || l2 || l3) && (l4 && l5 && l6)
                                judge = 1;
                            end
                        end
                    end
                    if (judge == 1)
                        %距离限制
                        d_pr = sqrt( (Tx(1,1)-pointDif(1,1))^2+(Tx(1,2)-pointDif(1,2))^2+(Tx(1,3)-pointDif(1,3))^2 );%pr距离
                        d_rq = sqrt( (Rx(1,1)-pointDif(1,1))^2+(Rx(1,2)-pointDif(1,2))^2+(Rx(1,3)-pointDif(1,3))^2 );%rq距离
                        if (d_pr+d_rq)<=dmax%距离控制
                            %Penetration
                            %为了存储数据重置Tem
                            TemPeneDif_rq = struct('Startpoint',[],'Finishpoint',[],'IndexFace',[],'Face',[],'PenePoint',[]);
                            TemPeneDif_pr = struct('Startpoint',[],'Finishpoint',[],'IndexFace',[],'Face',[],'PenePoint',[]);
                            t22 = 0;
                            for indexFace = 1:FaceNum
                                %如果该面在起点和绕射点的中间
                                if(roundn((FaceEquation(indexFace,1)*Tx(1,1)+FaceEquation(indexFace,2)*Tx(1,2)+FaceEquation(indexFace,3)*Tx(1,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*pointDif(1,1)+FaceEquation(indexFace,2)*pointDif(1,2)+FaceEquation(indexFace,3)*pointDif(1,3)+FaceEquation(indexFace,4)),-2) <0)
                                    %The purpose of "ceil" is avoiding mistake because of decimal digits in calculating process
                                    %Penepoint求R-T与面的交点
                                    pointCross = CrosspointLineFace(Tx(1,:),pointDif(1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                    %Judge Crosspoint in Face判断交点是否在面上
                                    if (CpInFace2(pointCross,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                        t22 = t22+1;%穿透数+1
                                        r_pd(t22,:) = pointCross;%储存穿透点，应该是要画的
                                        TTPeneDif_pr(t22,1) = Penetration(Tx(1,:),pointDif(1,:),FaceCoordinates(indexFace).Face(:,:),indexFace,FaceEquation(indexFace,:));%储存穿透信息
                                    end
                                end

                            end
                            %排序
                            d22 = [];
                            for i = 1:t22
                                d22(i) =  sum((TTPeneDif_pr(i).PenePoint-TTPeneDif_pr(i).Startpoint).^2);
                            end
                            [~,d22_right] = sort(d22);
                            for i = 1:t22
                                TemPeneDif_pr(i) = TTPeneDif_pr(d22_right(i));
                            end
                            t21 = 0;
                            for indexFace = 1:FaceNum
                                if(roundn((FaceEquation(indexFace,1)*Rx(1,1)+FaceEquation(indexFace,2)*Rx(1,2)+FaceEquation(indexFace,3)*Rx(1,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*pointDif(1,1)+FaceEquation(indexFace,2)*pointDif(1,2)+FaceEquation(indexFace,3)*pointDif(1,3)+FaceEquation(indexFace,4)),-2) <0)
                                    %The purpose of "ceil" is avoiding mistake because of decimal digits in calculating process
                                    %Penepoint
                                    pointCross = CrosspointLineFace(Rx(1,:),pointDif(1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                    %Judge Crosspoint in Face
                                    if (CpInFace2(pointCross,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                        t21 = t21+1;
                                        r_qd(t21,:) = pointCross;
                                        %TTPeneDif_rq(t21,1) = Penetration(Rx(1,:),pointDif(1,:),FaceCoordinates(indexFace).Face(:,:) ,indexFace);
                                        TTPeneDif_rq(t21,1) = Penetration(pointDif(1,:),Rx(1,:),FaceCoordinates(indexFace).Face(:,:) ,indexFace,FaceEquation(indexFace,:));
                                    end
                                end
                            end
                            d21 = [];
                            for i = 1:t21
                                d21(i) = sum((TTPeneDif_rq(i).PenePoint-TTPeneDif_rq(i).Startpoint).^2);
                            end
                            [~,d21_right] = sort(d21);
                            for i = 1:t21
                                TemPeneDif_rq(i) = TTPeneDif_rq(d21_right(i));
                            end

                            t20 = t21+t22;
                            if (t20<=PeneNum)%穿透次数限制
                                %接下来，就开始存储绕射信息喽
                                RaySum=RaySum+1;%总路径数
                                DifInfo(index_Rx).Dif(1).Detail(difnum1).EdgeStartpoint =point_Intsect(1,:) ;%存Dif数据，形成刃的第1个坐标
                                DifInfo(index_Rx).Dif(1).Detail(difnum1).EdgeFinishpoint =point_Intsect(2,:) ;%存Dif数据，形成刃的第2个坐标
                                DifInfo(index_Rx).Dif(1).Detail(difnum1).Difpoint = pointDif(1,:);%存绕射点
                                %存面的信息（面1、面2有顺序要求，可定义面1是入射面，面2是出射面）
                                %p1和刃形成一个面，求这个面分别与第一个面和第二个面的‘二面角’，角度小的为面1（入射面）
                                %先计算一遍，再排序
                                VectorFace1 = [];VectorFace2 = [];%面法向量
                                Vectorp = [];Vectorq = [];%T(R)-刃面的法向量
                                %求两个面与棱上的两个点不共线的点坐标
                                for mk = 1:size1
                                    if ~isequal(FaceCoordinates(CombinNuminDif1(numDifIndex,1)).Face(mk,:),point_Intsect(1,:))&&~isequal(FaceCoordinates(CombinNuminDif1(numDifIndex,1)).Face(mk,:),point_Intsect(2,:))
                                        NotInLine = dot(FaceCoordinates(CombinNuminDif1(numDifIndex,1)).Face(mk,:)-point_Intsect(1,:),FaceCoordinates(CombinNuminDif1(numDifIndex,1)).Face(mk,:)-point_Intsect(2,:))/(norm(FaceCoordinates(CombinNuminDif1(numDifIndex,1)).Face(mk,:)-point_Intsect(1,:))*norm(FaceCoordinates(CombinNuminDif1(numDifIndex,1)).Face(mk,:)-point_Intsect(2,:)));%保证取的点跟刃不共线
                                        if (NotInLine~=1)&&(NotInLine~=-1)
                                            break;
                                        end
                                    end
                                end
                                x1 = point_Intsect(1,1);y1 = point_Intsect(1,2);z1 = point_Intsect(1,3);
                                x2 = point_Intsect(2,1);y2 = point_Intsect(2,2);z2 = point_Intsect(2,3);
                                xyz = FaceCoordinates(CombinNuminDif1(numDifIndex,1)).Face(mk,:);
                                t = ((x1 - x2)*(x1 - xyz(1,1)) + (y1 - y2)*(y1 - xyz(1,2)) + (z1 - z2)*(z1 - xyz(1,3)))/((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2);
                                Pro_Face1 = [x1+(x2-x1)*t y1+(y2-y1)*t z1+(z2-z1)*t];
                                VectorFace1 = xyz-Pro_Face1;%求面的方向向量

                                for nk = 1:size2
                                    if ~isequal(FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(nk,:),point_Intsect(1,:))&&~isequal(FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(nk,:),point_Intsect(2,:))
                                        NotInLine = dot(FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(nk,:)-point_Intsect(1,:),FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(nk,:)-point_Intsect(2,:))/(norm(FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(nk,:)-point_Intsect(1,:))*norm(FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(nk,:)-point_Intsect(2,:)));%保证取的点跟刃不共线
                                        if (NotInLine~=1)&&(NotInLine~=-1)
                                            break;
                                        end
                                    end
                                end
                                x1 = point_Intsect(1,1);y1 = point_Intsect(1,2);z1 = point_Intsect(1,3);
                                x2 = point_Intsect(2,1);y2 = point_Intsect(2,2);z2 = point_Intsect(2,3);
                                xyz = FaceCoordinates(CombinNuminDif1(numDifIndex,2)).Face(nk,:);
                                t = ((x1 - x2)*(x1 - xyz(1,1)) + (y1 - y2)*(y1 - xyz(1,2)) + (z1 - z2)*(z1 - xyz(1,3)))/((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2);
                                Pro_Face2 = [x1+(x2-x1)*t y1+(y2-y1)*t z1+(z2-z1)*t];
                                VectorFace2 = xyz-Pro_Face2;

                                Vectorp = Tx-point_Pro(1,:);%起点与起点在棱上投影点的方向向量
                                Vectorq = Rx-point_Pro(2,:);

                                %计算‘绕射点指向发端的向量’分别与第一个面和第二个面上向量的角度，角度小的为面1（即入射面）
                                %错了，是p-刃与两个面的二面角
                                AngleFace1p = acos(dot(VectorFace1,Vectorp)/(norm(VectorFace1)*norm(Vectorp)));
                                AngleFace2p = acos(dot(VectorFace2,Vectorp)/(norm(VectorFace2)*norm(Vectorp)));
                                if AngleFace1p<=AngleFace2p
                                    DifInfo(index_Rx).Dif(1).Detail(difnum1).Face1 = CombinNuminDif1(numDifIndex,1);
                                    DifInfo(index_Rx).Dif(1).Detail(difnum1).Face2 = CombinNuminDif1(numDifIndex,2);
                                    AngleFace1_p = AngleFace1p;%为下面计算棱的系数做准备
                                    AngleFace2_p = AngleFace2p;
                                    AngleFace1_q = acos(dot(VectorFace1,Vectorq)/(norm(VectorFace1)*norm(Vectorq)));
                                    AngleFace2_q = acos(dot(VectorFace2,Vectorq)/(norm(VectorFace2)*norm(Vectorq)));
                                else
                                    DifInfo(index_Rx).Dif(1).Detail(difnum1).Face1 = CombinNuminDif1(numDifIndex,2);
                                    DifInfo(index_Rx).Dif(1).Detail(difnum1).Face2 = CombinNuminDif1(numDifIndex,1);
                                    AngleFace1_p = AngleFace2p;
                                    AngleFace2_p = AngleFace1p;
                                    AngleFace1_q = acos(dot(VectorFace2,Vectorq)/(norm(VectorFace2)*norm(Vectorq)));
                                    AngleFace2_q = acos(dot(VectorFace1,Vectorq)/(norm(VectorFace1)*norm(Vectorq)));
                                end

                                %存棱的系数（形成刃的劈的角度）
                                Angle_pDifq = acos(dot(Vectorp,Vectorq)/(norm(Vectorp)*norm(Vectorq)));%计算p-刃面与q-刃面形成的二面角
                                Angle_edge = acos(dot(VectorFace1,VectorFace2)/(norm(VectorFace1)*norm(VectorFace2)));
                                if Angle_pDifq>=Angle_edge
                                    DifInfo(index_Rx).Dif(1).Detail(difnum1).EdgeFactor = Angle_edge;
                                else
                                    if (AngleFace1_p+AngleFace2_q+Angle_pDifq)<pi
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).EdgeFactor = 2*pi-Angle_edge;
                                    else
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).EdgeFactor = Angle_edge;
                                    end
                                end
                                %存p-刃平面与入射面的二面角以及q-刃平面与入射面的二面角，这行注释是对的，下面的角错了
                                DifInfo(index_Rx).Dif(1).Detail(difnum1).Phi = AngleFace1_q;%p-刃平面与入射面（面1，角度小的）的二面角
                                %DifInfo(index_Rx).Dif1(difnum).Phi = AngleFace1_p+Angle_pDifq;
                                DifInfo(index_Rx).Dif(1).Detail(difnum1).PhiNext = AngleFace1_p;%q-刃平面与入射面的二面角
                                %应该要q-刃平面与入射面的二面角
                                %DifInfo(index_Rx).Dif1(difnum).PhiNext = AngleFace1_q;%q-刃平面与入射面的二面角

                                %存储绕射的穿透信息
                                %pr段
                                if (t22~=0)
                                    sym_pe = 0;
                                    for i = 1:t22
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(i,1) = 1;
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(i,2) = 1;
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(i,3:5) = TemPeneDif_pr(i).PenePoint;
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(i,6) = TemPeneDif_pr(i).IndexFace;%面的标号指的是FOringal里面的行数，这指定了一个唯一的面，并且每个面有一个唯一的标号
                                        sym_pe = sym_pe+1;
                                        if sym_pe==t22
                                            DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(i,7) = 0;
                                        else
                                            DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(i,7) = 1;
                                        end
                                    end
                                else
                                    DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(1,1) = 1;
                                    DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(1,2) = 0;
                                end

                                %rq段
                                if (t21~=0)%保证发生了穿透
                                    sym_pe = 0;
                                    for i = 1:t21
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(end+1,1) = 2;
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(end,2) = 1;
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(end,3:5) = TemPeneDif_rq(i).PenePoint;
                                        DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(end,6) = TemPeneDif_rq(i).IndexFace;%面的标号指的是FOringal里面的行数，这指定了一个唯一的面，并且每个面有一个唯一的标号
                                        sym_pe = sym_pe+1;
                                        if sym_pe==t21
                                            DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(end,7) = 0;
                                        else
                                            DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(end,7) = 1;
                                        end
                                    end
                                else
                                    DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(end+1,1) = 2;
                                    DifInfo(index_Rx).Dif(1).Detail(difnum1).Pe(end,2) = 0;
                                end
                                %%%%%%%%%很重要的变量！
                                difnum1 = difnum1+1;%就是最初两面组合可以发生绕射（当然，需要满足好多好多条件），则总的绕射径+1，即difnum是该收发端场景下的总绕射数
                            end
                        end
                    end
                end
            end
        end
        %下面是计算二阶绕射
        if Difnum == 2
            difnum2 = 1;%为了下面存储绕射信息
            for ArryIndex=1:size(fpDif(Difnum).CombinNuminDif,2) %两个for循环对绕射的两对面面组合进行索引
                for CombinNuminDif2 = 1:size(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail,1)
                    numsCoorEqualtoTwoFace = 0;%判断两个面上有多少个相同的沿边点
                    %找到要绕射的两个面
                    FaceDifEquation(1,:) = FaceEquation(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,1),:) ;%存储可能发生绕射面的参数方程
                    FaceDifEquation(2,:) = FaceEquation(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,2),:) ;
                    FaceDifEquation(3,:) = FaceEquation(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,3),:) ;
                    FaceDifEquation(4,:) = FaceEquation(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,4),:) ;
                    FaceCoordinates1 = FaceCoordinates(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,1)).Face(:,:);%存储可能发生绕射面的点坐标
                    FaceCoordinates2 = FaceCoordinates(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,2)).Face(:,:);
                    FaceCoordinates3 = FaceCoordinates(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,3)).Face(:,:);
                    FaceCoordinates4 = FaceCoordinates(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,4)).Face(:,:);
                    size1 = size(FaceCoordinates1,1);%面由几个点组成
                    size2 = size(FaceCoordinates2,1);
                    size3 = size(FaceCoordinates3,1);
                    size4 = size(FaceCoordinates4,1);
                    for m = 1:size1
                        for n = 1:size2
                            %判断两个面上是否有相同的点 即两个面上的边沿点是否存在相同的
                            if(FaceCoordinates1(m,:)==FaceCoordinates2(n,:))
                                numsCoorEqualtoTwoFace = numsCoorEqualtoTwoFace+1;%相同沿边点的个数+1
                                point_Intsect(numsCoorEqualtoTwoFace,:) = FaceCoordinates2(n,:);
                                if numsCoorEqualtoTwoFace==2
                                    break;
                                end
                            end
                        end
                        if numsCoorEqualtoTwoFace==2%有两个沿边点是相同的，就直接跳出循环
                            break;
                        end
                    end
                    for m = 1:size3
                        for n = 1:size4
                            %判断两个面上是否有相同的点 即两个面上的边沿点是否存在相同的
                            if(FaceCoordinates3(m,:)==FaceCoordinates4(n,:))
                                numsCoorEqualtoTwoFace = numsCoorEqualtoTwoFace+1;%相同沿边点的个数+1
                                point_Intsect(numsCoorEqualtoTwoFace,:) = FaceCoordinates4(n,:);
                                if numsCoorEqualtoTwoFace==4
                                    break;
                                end
                            end
                        end
                        if numsCoorEqualtoTwoFace==4%有两个沿边点是相同的，就直接跳出循环(这里把两对面面组合合在一起判断相同的沿边点)
                            break;
                        end
                    end
                    if numsCoorEqualtoTwoFace==4
                        alpha1 =[];
                        alpha2 = [];
                        [alpha1,alpha2] = solve_equations(point_Intsect,Tx,Rx);%解方程
                        s1 = (alpha1 >= 0) & (alpha1 <= 1);%判断绕射点是否在棱上，其实下面也有判断，这里主要想判断alpha1和alpha2是否可以解出具体数值
                        s2 = (alpha2 >= 0) & (alpha2 <= 1);
                        if (s1 == 1)&(s2 == 1)
                            pointDif(1,:) = point_Intsect(1,:) + alpha1*(point_Intsect(2,:) - point_Intsect(1,:));%求出具体绕射点坐标
                            pointDif(1,:) = roundn(pointDif(1,:),-4);
                            pointDif(2,:) = point_Intsect(3,:) + alpha2*(point_Intsect(4,:) - point_Intsect(3,:));
                            pointDif(2,:) = roundn(pointDif(2,:),-4);
                            judge = 0;condition = 0;
                            if (all(pointDif(1,:) == point_Intsect(1,:)) || all(pointDif(1,:) == point_Intsect(2,:))) && (all(pointDif(2,:) == point_Intsect(3,:)) || all(pointDif(2,:) == point_Intsect(4,:)))
                                for indexFace = 1:FaceNum
                                    if(roundn((FaceEquation(indexFace,1)*pointDif(2,1)+FaceEquation(indexFace,2)*pointDif(2,2)+FaceEquation(indexFace,3)*pointDif(2,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*Tx(1,1)+FaceEquation(indexFace,2)*Tx(1,2)+FaceEquation(indexFace,3)*Tx(1,3)+FaceEquation(indexFace,4)),-2) <0)
                                        pointcross = CrosspointLineFace(pointDif(2,:),Tx(1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                        if (CpInFace2(pointcross,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                            condition = 1;
                                            break;
                                        end
                                    end
                                end
                                for indexFace = 1:FaceNum
                                    if(roundn((FaceEquation(indexFace,1)*pointDif(1,1)+FaceEquation(indexFace,2)*pointDif(1,2)+FaceEquation(indexFace,3)*pointDif(1,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*Rx(1,1)+FaceEquation(indexFace,2)*Rx(1,2)+FaceEquation(indexFace,3)*Rx(1,3)+FaceEquation(indexFace,4)),-2) <0)
                                        pointcross = CrosspointLineFace(pointDif(1,:),Rx(1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                        if (CpInFace2(pointcross,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                            condition = 1;
                                            break;
                                        end
                                    end
                                end
                            end
                            if ~condition
                                for i = 1:2%与一阶绕射相同，求出绕射点后需要判断能否发生绕射
                                    %收发点到两个面的距离，这里需要分别判断两个绕射点与面的关系，同侧则可以发生绕射
                                    m01(i) = FaceDifEquation(i,1)*Tx(1,1)+FaceDifEquation(i,2)*Tx(1,2)+FaceDifEquation(i,3)*Tx(1,3)+FaceDifEquation(i,4);%Tx到第一个面的向量距离
                                    m02(i) = FaceDifEquation(i,1)* pointDif(2,1)+FaceDifEquation(i,2)*pointDif(2,2)+FaceDifEquation(i,3)*pointDif(2,3)+FaceDifEquation(i,4);%
                                end
                                for i = 3:4
                                    m03(i-2) = FaceDifEquation(i,1)*pointDif(1,1)+FaceDifEquation(i,2)*pointDif(1,2)+FaceDifEquation(i,3)*pointDif(1,3)+FaceDifEquation(i,4);
                                    m04(i-2) = FaceDifEquation(i,1)* Rx(1,1)+FaceDifEquation(i,2)*Rx(1,2)+FaceDifEquation(i,3)*Rx(1,3)+FaceDifEquation(i,4);
                                end
                                Point_Same_Side = [];%分别判断两个绕射点是否满足同侧条件
                                judge1 = 0;%这里是为了判断两个绕射点是否都满足同侧的条件
                                judge2 = 0;%判断两个绕射点是否在棱上
                                Point_Same_Side(1) = ((((m01(1)>0)&&(m02(1)>0)) || ((m01(1)<0)&&(m02(1)<0)))) && ((((m01(2)>0)&&(m02(2)>0)) || ((m01(2)<0)&&(m02(2)<0))));
                                Point_Same_Side(2) = ((((m03(1)>0)&&(m04(1)>0)) || ((m03(1)<0)&&(m04(1)<0)))) && ((((m03(2)>0)&&(m04(2)>0)) || ((m03(2)<0)&&(m04(2)<0))));
                                if (Point_Same_Side(1) == 1) && (Point_Same_Side(2) == 1)%同侧需要满足的条件
                                    judge1 = 1;
                                    l1 = (min(point_Intsect(1:2,1)) <= pointDif(1,1)) && (pointDif(1,1)<= max(point_Intsect(1:2,1)));%下面是判断绕射点是否在棱上
                                    l2 = (min(point_Intsect(1:2,2)) <= pointDif(1,2)) && (pointDif(1,2)<= max(point_Intsect(1:2,2)));
                                    l3 = (min(point_Intsect(1:2,3)) <= pointDif(1,3)) && (pointDif(1,3)<= max(point_Intsect(1:2,3)));
                                    l4 = (min(point_Intsect(3:4,1)) <= pointDif(2,1)) && (pointDif(2,1)<= max(point_Intsect(3:4,1)));%下面是判断绕射点是否在棱上
                                    l5 = (min(point_Intsect(3:4,2)) <= pointDif(2,2)) && (pointDif(2,2)<= max(point_Intsect(3:4,2)));
                                    l6 = (min(point_Intsect(3:4,3)) <= pointDif(2,3)) && (pointDif(2,3)<= max(point_Intsect(3:4,3)));
                                    if (l1 && l2 && l3 && l4 && l5 && l6)
                                        judge2 = 1;
                                    end
                                    if (judge1 == 1) && (judge2 == 1)
                                        judge = 1;%如果满足同侧且绕射点在棱上，judge赋值为1
                                    end
                                else
                                    pointCross = [];ifPointOnFace=[];
                                    %判断起点与终点的连线是不是与两个面有交点？有交点则不能发生绕射
                                    for i = 1:2
                                        pointCross(i,:) = CrosspointLineFace(pointDif(2,:),Tx(1,:),FaceDifEquation(i,:),point_Intsect(1,:));
                                        ifPointOnFace(i) = CpInFace2(pointCross(i,:),FaceDifEquation(i,:),FaceCoordinates(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,i)).Face(:,:));
                                    end
                                    for j = 3:4
                                        pointCross(j,:) = CrosspointLineFace(pointDif(1,:),Rx(1,:),FaceDifEquation(j,:),point_Intsect(3,:));
                                        ifPointOnFace(j) = CpInFace2(pointCross(j,:),FaceDifEquation(j,:),FaceCoordinates(fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,j)).Face(:,:));
                                    end
                                    if all(ifPointOnFace == 0)
                                        %进行降维判断，只要l1,l2,l3有一个满足（l4,l5,l6有一个满足）就可以发生绕射
                                        Q=[];
                                        x3(1) = Tx(1,1); y3(1) = Tx(1,2); z3(1) = Tx(1,3);%Tx
                                        x3(2) = pointDif(2,1); y3(2) = pointDif(2,2); z3(2) = pointDif(2,3);
                                        x3(3) = pointDif(1,1); y3(3) = pointDif(1,2); z3(3) = pointDif(1,3);
                                        x3(4) = Rx(1,1); y3(4) = Rx(1,2); z3(4) = Rx(1,3);

                                        s_in=sqrt((pointDif(1,2)-y3(1))^2+(pointDif(1,3)-z3(1))^2 );
                                        s_out=sqrt((pointDif(1,2)-y3(2))^2+(pointDif(1,3)-z3(2))^2 );
                                        Q(1,1)= x3(1)+(x3(2)-x3(1))*(s_in/(s_in+s_out));
                                        s_in=sqrt((pointDif(1,1)-x3(1))^2+(pointDif(1,3)-z3(1))^2 );
                                        s_out=sqrt((pointDif(1,1)-x3(2))^2+(pointDif(1,3)-z3(2))^2 );
                                        Q(1,2)= y3(1)+(y3(2)-y3(1))*(s_in/(s_in+s_out));
                                        s_in=sqrt((pointDif(1,1)-x3(1))^2+(pointDif(1,2)-y3(1))^2 );
                                        s_out=sqrt((pointDif(1,1)-x3(2))^2+(pointDif(1,2)-y3(2))^2 );
                                        Q(1,3)=z3(1)+(z3(2)-z3(1))*(s_in/(s_in+s_out));

                                        s_in=sqrt((pointDif(2,2)-y3(3))^2+(pointDif(2,3)-z3(3))^2 );
                                        s_out=sqrt((pointDif(2,2)-y3(4))^2+(pointDif(2,3)-z3(4))^2 );
                                        Q(2,1)= x3(3)+(x3(4)-x3(3))*(s_in/(s_in+s_out));
                                        s_in=sqrt((pointDif(2,1)-x3(3))^2+(pointDif(2,3)-z3(3))^2 );
                                        s_out=sqrt((pointDif(2,1)-x3(4))^2+(pointDif(2,3)-z3(4))^2 );
                                        Q(2,2)= y3(3)+(y3(4)-y3(3))*(s_in/(s_in+s_out));
                                        s_in=sqrt((pointDif(2,1)-x3(3))^2+(pointDif(2,2)-y3(3))^2 );
                                        s_out=sqrt((pointDif(2,1)-x3(4))^2+(pointDif(2,2)-y3(4))^2 );
                                        Q(2,3)=z3(3)+(z3(4)-z3(3))*(s_in/(s_in+s_out));

                                        l1 = (min(point_Intsect(1:2,1)) <= Q(1,1)) && (Q(1,1)<= max(point_Intsect(1:2,1)));
                                        l2 = (min(point_Intsect(1:2,2)) <= Q(1,2)) && (Q(1,2)<= max(point_Intsect(1:2,2)));
                                        l3 = (min(point_Intsect(1:2,3)) <= Q(1,3)) && (Q(1,3)<= max(point_Intsect(1:2,3)));
                                        l4 = (min(point_Intsect(3:4,1)) <= Q(2,1)) && (Q(2,1)<= max(point_Intsect(3:4,1)));
                                        l5 = (min(point_Intsect(3:4,2)) <= Q(2,2)) && (Q(2,2)<= max(point_Intsect(3:4,2)));
                                        l6 = (min(point_Intsect(3:4,3)) <= Q(2,3)) && (Q(2,3)<= max(point_Intsect(3:4,3)));
                                        if (l1 || l2 || l3) && (l4 || l5 || l6)
                                            judge = 1;%如果上面满足，judge赋值为1
                                        end
                                    end
                                end
                                if (judge == 1)%两个绕射点都满足几何位置上的要求，进入下面距离的判断
                                    d_pr = sqrt( (Tx(1,1)-pointDif(1,1))^2+(Tx(1,2)-pointDif(1,2))^2+(Tx(1,3)-pointDif(1,3))^2 );%起点到第一个绕射点距离
                                    d_pq = sqrt( (pointDif(2,1)-pointDif(1,1))^2+(pointDif(2,2)-pointDif(1,2))^2+(pointDif(2,3)-pointDif(1,3))^2 );%第一个绕射点到第二个绕射点之间的距离
                                    d_rq = sqrt( (Rx(1,1)-pointDif(2,1))^2+(Rx(1,2)-pointDif(2,2))^2+(Rx(1,3)-pointDif(2,3))^2 );%第二个绕射点到终点的距离
                                    if (d_pr+d_rq+d_pq)<=dmax%距离控制
                                        TemPeneDif_rnq=struct('Startpoint',[],'Finishpoint',[],'IndexFace',[],'Face',[],'PenePoint',[]);%第二个绕射点到终点子径的穿透信息
                                        TemPeneDif=struct('rr',[]);
                                        TemPeneDif.rr=struct('Startpoint',[],'Finishpoint',[],'IndexFace',[],'Face',[],'PenePoint',[]); %第一个绕射点到第二个绕射点子径的穿透信息
                                        TemPeneDif_prl=struct('Startpoint',[],'Finishpoint',[],'IndexFace',[],'Face',[],'PenePoint',[]);%起点到第一个绕射点子径的穿透信息
                                        pe = struct('rr',[]);%避免存储错误

                                        %p-r1 Tx到D1
                                        peneNum = 0;%穿透点的序号（个数），指的是Tx与D1的穿透点
                                        for indexFace = 1:FaceNum%逐面判断是否有穿透点
                                            %Tx和D1是否在面的两侧
                                            if(roundn((FaceEquation(indexFace,1)*Tx(1,1)+FaceEquation(indexFace,2)*Tx(1,2)+FaceEquation(indexFace,3)*Tx(1,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*pointDif(1,1)+FaceEquation(indexFace,2)*pointDif(1,2)+FaceEquation(indexFace,3)*pointDif(1,3)+FaceEquation(indexFace,4)),-2) <0)
                                                %The purpose of "ceil" is avoiding mistake because of decimal digits in calculating process
                                                %%%%%
                                                %%%=======================================
                                                %%%
                                                %Penepoint为TX与D1这条路径与该面的穿透交点
                                                pointPene = CrosspointLineFace(Tx(1,:),pointDif(1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                                %Judge Crosspoint in Face 如果交点在该面上
                                                if (CpInFace2(pointPene,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                                    peneNum = peneNum+1;%穿透点的个数
                                                    pe_prl(peneNum,:)=pointPene;%穿透点
                                                    %穿透信息中间变量，感觉是为了不影响原始穿透信息变量的值才存在的东西？
                                                    TTPeneDif_prl(peneNum,1).Detail=Penetration(Tx(1,:),pointDif(1,:),FaceCoordinates(indexFace).Face(:,:),indexFace,FaceEquation(indexFace,:));
                                                end
                                            end
                                        end
                                        %对穿透点排序
                                        d33=[];
                                        for i = 1:peneNum
                                            d33(i)=sum((TTPeneDif_prl(i).Detail.PenePoint-TTPeneDif_prl(i).Detail.Startpoint).^2);
                                        end
                                        [~,d33_right]=sort(d33);%排序
                                        for i = 1:peneNum
                                            TemPeneDif_prl(i)=TTPeneDif_prl(d33_right(i)).Detail;
                                        end
                                        if peneNum==0
                                            TemPeneDif_prl=[];
                                        end

                                        %D(n-1)-Dn
                                        t32 = 0;%子径穿透数
                                        for i = 1:(Difnum-1)%绕射点-1个中间子径
                                            t32(i) = 0;
                                            for indexFace = 1:FaceNum
                                                if(roundn((FaceEquation(indexFace,1)*pointDif(i,1)+FaceEquation(indexFace,2)*pointDif(i,2)+...
                                                        FaceEquation(indexFace,3)*pointDif(i,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*pointDif(i+1,1)+...
                                                        FaceEquation(indexFace,2)*pointDif(i+1,2)+FaceEquation(indexFace,3)*pointDif(i+1,3)+FaceEquation(indexFace,4)),-2) <0)
                                                    %The purpose of "ceil" is avoiding mistake because of decimal digits in calculating process
                                                    %Penepoint
                                                    pointCrossInPene = CrosspointLineFace(pointDif(i,:),pointDif(i+1,:),FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                                    %Judge Crosspoint in Face如果交点在面上
                                                    if (CpInFace2(pointCrossInPene,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                                        t32(i) = t32(i)+1;%储存相应绕射径的穿透数
                                                        pe(i).rr(t32(i),:)= pointCrossInPene;%穿透点 疑问：pe.rr没有初始化
                                                        %TTPeneRef.rr(t32(i),1)=Penetration(pointCross(i,:),pointCross(i+1,:),FaceCoordinates(indexFace).Face(:,:),indexFace);
                                                        TTPeneDif(i).rr(t32(i),1)=Penetration(pointDif(i,:),pointDif(i+1,:),FaceCoordinates(indexFace).Face(:,:) ,indexFace,FaceEquation(indexFace,:));
                                                    end
                                                end
                                            end
                                            %对穿透点排序
                                            d32=[];
                                            for k = 1:t32(i)
                                                d32(k)=sum((TTPeneDif(i).rr(k,1).PenePoint-TTPeneDif(i).rr(k,1).Startpoint).^2);
                                            end
                                            %%%%%%%%%%%%%9月1日
                                            [~,d32_right]=sort(d32);%排序
                                            for k = 1:t32(i)
                                                TemPeneDif(i).rr(k,1)=TTPeneDif(i).rr(d32_right(k),1);
                                            end
                                            if t32(i)==0
                                                pe(i).rr = [];
                                                TemPeneDif(i).rr=[];
                                            end

                                        end
                                        %计算Dn到Rx的穿透
                                        t31 = 0;
                                        for indexFace = 1:FaceNum
                                            if(roundn((FaceEquation(indexFace,1)*pointDif(Difnum,1)+FaceEquation(indexFace,2)*pointDif(Difnum,2)+FaceEquation(indexFace,3)*pointDif(Difnum,3)+FaceEquation(indexFace,4))*(FaceEquation(indexFace,1)*Rx(1,1)+FaceEquation(indexFace,2)*Rx(1,2)+FaceEquation(indexFace,3)*Rx(1,3)+FaceEquation(indexFace,4)),-2) <0)
                                                %The purpose of "roundn" is avoiding mistake because of decimal digits in calculating process
                                                %Penepoint
                                                r31 = CrosspointLineFace(pointDif(Difnum,:),Rx,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(1,:));
                                                %Judge Crosspoint in Face判断点是否在面上
                                                if (CpInFace2(r31,FaceEquation(indexFace,:),FaceCoordinates(indexFace).Face(:,:)))
                                                    t31 = t31+1;
                                                    pe_rnq(t31,:)=r31;
                                                    %TTPeneRef_rnq=Penetration(pointTx(1,:),pointCross(1,:),FaceCoordinates(indexFace).Face(:,:),indexFace);
                                                    TTPeneDif_rnq(t31,1).Detail=Penetration(pointDif(Difnum,:),Rx,FaceCoordinates(indexFace).Face(:,:),indexFace,FaceEquation(indexFace,:));
                                                end
                                            end
                                        end
                                        %对穿透点排序
                                        d31=[];
                                        for i =1:t31
                                            d31(i)=sum((TTPeneDif_rnq(i).Detail.PenePoint-TTPeneDif_rnq(i).Detail.Startpoint).^2);
                                        end
                                        [~,d31_right]=sort(d31);
                                        for i =1:t31
                                            TemPeneDif_rnq(i)=TTPeneDif_rnq(d31_right(i)).Detail;
                                        end
                                        if t31==0
                                            TemPeneDif_rnq=[];
                                        end
                                        %至此，所有的穿透信息计算完毕，下面进行信息的保存
                                        t32_ = sum(t32);
                                        t30 = t31+t32_+peneNum;%总的穿透数
                                        %disp(t30);
                                        if (t30<=PeneNum)%穿透限制，有的没用通过穿透限制
                                            %下面是判断绕射点是否与前面的重复
                                            sign(1,:) = ones(1,100000);%100000只是取的一个较大的数值，为了重置sign
                                            if difnum2==1%此时如果是第一个绕射径就可以不进行判断
                                            else%检测是否存了两次，就是简单的看坐标与前面存储的是否相等
                                                signIndex = [];
                                                for i = 1:(difnum2-1)
                                                    signIndex = isequal(pointDif, DifInfo(index_Rx). Dif(Difnum). Detail (i).Difpoint);
                                                    if (signIndex==1)
                                                        sign(1,i) = 0;
                                                    else
                                                        sign(1,i) = 1;
                                                    end
                                                end
                                            end
                                            if prod(sign)==1
                                                RaySum=RaySum+1;%总路径数加1
                                                EdgeStartpoint = [point_Intsect(1,:);point_Intsect(3,:)];%存储棱的起点（不考虑方向）
                                                EdgeFinishpoint = [point_Intsect(2,:);point_Intsect(4,:)];%存储棱的终点
                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).EdgeStartpoint = EdgeStartpoint;%存Dif数据，形成刃的第1个坐标
                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).EdgeFinishpoint = EdgeFinishpoint;%存Dif数据，形成刃的第2个坐标
                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Difpoint = pointDif(:,:);%存绕射点
                                                %存面的信息（面1、面2有顺序要求，可定义面1是入射面，面2是出射面）
                                                %p1和刃形成一个面，求这个面分别与第一个面和第二个面的‘二面角’，角度小的为面1（入射面）
                                                %先计算一遍，再排序
                                                VectorFace1 = [];VectorFace2 = [];VectorFace3 = [];VectorFace4 = [];%面的方向向量
                                                Vectorp = [];Vectorq = []; Vectorm = [];Vectorn = [];%T(R，绕射点)与在棱上投影点的方向向量
                                                Face1 = []; Face2 = []; EdgeFactor  = []; Phi = []; PhiNext = [];%为后面电磁计算做准备
                                                for mk = 1:size1
                                                    if ~isequal(FaceCoordinates1(mk,:),point_Intsect(1,:))&&~isequal(FaceCoordinates1(mk,:),point_Intsect(2,:))%找出与边沿点不同的点
                                                        NotInLine = dot(FaceCoordinates1(mk,:)-point_Intsect(1,:),FaceCoordinates1(mk,:)-point_Intsect(2,:))/(norm(FaceCoordinates1(mk,:)-point_Intsect(1,:))*norm(FaceCoordinates1(mk,:)-point_Intsect(2,:)));%保证取的点跟刃不共线
                                                        if (NotInLine~=1)&&(NotInLine~=-1)
                                                            break;
                                                        end
                                                    end
                                                end
                                                xyz = FaceCoordinates1(mk,:);
                                                p1 = point_Intsect(2,:) - point_Intsect(1,:);
                                                pt1 = xyz-point_Intsect(1,:);
                                                t1 = dot(p1,pt1)/(norm(p1)*norm(pt1));
                                                Pro_Face1 = point_Intsect(1,:)+t1*p1;
                                                VectorFace1 = xyz-Pro_Face1;

                                                for nk = 1:size2
                                                    if ~isequal(FaceCoordinates2(nk,:),point_Intsect(1,:))&&~isequal(FaceCoordinates2(nk,:),point_Intsect(2,:))
                                                        NotInLine = dot(FaceCoordinates2(nk,:)-point_Intsect(1,:),FaceCoordinates2(nk,:)-point_Intsect(2,:))/(norm(FaceCoordinates2(nk,:)-point_Intsect(1,:))*norm(FaceCoordinates2(nk,:)-point_Intsect(2,:)));%保证取的点跟刃不共线
                                                        if (NotInLine~=1)&&(NotInLine~=-1)
                                                            break;
                                                        end
                                                    end
                                                end
                                                xyz = FaceCoordinates2(nk,:);
                                                p2 = point_Intsect(2,:) - point_Intsect(1,:);
                                                pt2 = xyz-point_Intsect(1,:);
                                                t2 = dot(p2,pt2)/(norm(p2)*norm(pt2));
                                                Pro_Face2 = point_Intsect(1,:)+t2*p2;
                                                VectorFace2 = xyz-Pro_Face2;

                                                for mk = 1:size3
                                                    if ~isequal(FaceCoordinates3(mk,:),point_Intsect(3,:))&&~isequal(FaceCoordinates3(mk,:),point_Intsect(4,:))
                                                        NotInLine = dot(FaceCoordinates3(mk,:)-point_Intsect(3,:),FaceCoordinates3(mk,:)-point_Intsect(4,:))/(norm(FaceCoordinates3(mk,:)-point_Intsect(3,:))*norm(FaceCoordinates3(mk,:)-point_Intsect(4,:)));%保证取的点跟刃不共线
                                                        if (NotInLine~=1)&&(NotInLine~=-1)
                                                            break;
                                                        end
                                                    end
                                                end
                                                xyz = FaceCoordinates3(mk,:);
                                                p3 = point_Intsect(4,:) - point_Intsect(3,:);
                                                pt3 = xyz-point_Intsect(3,:);
                                                t3 = dot(p3,pt3)/(norm(p3)*norm(pt3));
                                                Pro_Face3 = point_Intsect(3,:)+t3*p3;
                                                VectorFace3 = xyz-Pro_Face3;

                                                for nk = 1:size4
                                                    if ~isequal(FaceCoordinates4(nk,:),point_Intsect(3,:))&&~isequal(FaceCoordinates4(nk,:),point_Intsect(4,:))
                                                        NotInLine = dot(FaceCoordinates4(nk,:)-point_Intsect(3,:),FaceCoordinates4(nk,:)-point_Intsect(4,:))/(norm(FaceCoordinates4(nk,:)-point_Intsect(3,:))*norm(FaceCoordinates4(nk,:)-point_Intsect(4,:)));%保证取的点跟刃不共线
                                                        if (NotInLine~=1)&&(NotInLine~=-1)
                                                            break;
                                                        end
                                                    end
                                                end
                                                xyz = FaceCoordinates4(nk,:);
                                                p4 = point_Intsect(4,:) - point_Intsect(3,:);
                                                pt4 = xyz-point_Intsect(3,:);
                                                t4 = dot(p4,pt4)/(norm(p4)*norm(pt4));
                                                Pro_Face4 = point_Intsect(3,:)+t4*p4;
                                                VectorFace4 = xyz-Pro_Face4;
                                                %跟求解方程的思路时求投影点的思路一样
                                                q1 = point_Intsect(2,:) - point_Intsect(1,:);
                                                q2 = point_Intsect(4,:) - point_Intsect(3,:);
                                                qt1 = Tx - point_Intsect(1,:);
                                                s1 = dot(qt1,q1)/dot(q1,q1);
                                                point_Pro(1,:) = point_Intsect(1,:)+q1*s1;
                                                qt2 = pointDif(2,:) - point_Intsect(1,:);
                                                s2 = dot(qt2,q1)/dot(q1,q1);
                                                point_Pro(2,:) = point_Intsect(1,:)+q1*s2;
                                                qt3 = pointDif(1,:) - point_Intsect(3,:);
                                                s3 = dot(qt3,q2)/dot(q2,q2);
                                                point_Pro(3,:) = point_Intsect(3,:)+q2*s3;
                                                qt4 = Rx - point_Intsect(3,:);
                                                s4 = dot(qt4,q2)/dot(q2,q2);
                                                point_Pro(4,:) = point_Intsect(3,:)+q2*s4;
                                                %第一次绕射
                                                Vectorp = Tx-point_Pro(1,:);%发射点到发射点在棱上投影点的向量
                                                Vectorq = pointDif(2,:)-point_Pro(2,:);%第二个绕射点到第二个绕射点在棱上投影点的向量
                                                %第二次绕射
                                                Vectorm = pointDif(1,:)-point_Pro(3,:);%第一个绕射点到第一个绕射点在棱上投影点的向量
                                                Vectorn = Rx-point_Pro(4,:); % 接收点到接收点在棱上投影点的向量
                                                %计算‘绕射点指向发端的向量’分别与第一个面和第二个面上向量的角度，角度小的为面1（即入射面）
                                                AngleFace1p = acos(dot(VectorFace1,Vectorp)/(norm(VectorFace1)*norm(Vectorp)));
                                                AngleFace2p = acos(dot(VectorFace2,Vectorp)/(norm(VectorFace2)*norm(Vectorp)));
                                                if AngleFace1p<=AngleFace2p
                                                    Face1 = fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,1);
                                                    Face2 = fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,2);
                                                    AngleFace1_p = AngleFace1p;%为下面计算棱的系数做准备
                                                    AngleFace2_p = AngleFace2p;
                                                    AngleFace1_q = acos(dot(VectorFace1,Vectorq)/(norm(VectorFace1)*norm(Vectorq)));
                                                    AngleFace2_q = acos(dot(VectorFace2,Vectorq)/(norm(VectorFace2)*norm(Vectorq)));
                                                else
                                                    Face1 = fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,2);
                                                    Face2 = fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,1);
                                                    AngleFace1_p = AngleFace2p;
                                                    AngleFace2_p = AngleFace1p;
                                                    AngleFace1_q = acos(dot(VectorFace2,Vectorq)/(norm(VectorFace2)*norm(Vectorq)));
                                                    AngleFace2_q = acos(dot(VectorFace1,Vectorq)/(norm(VectorFace1)*norm(Vectorq)));
                                                end

                                                %存棱的系数（形成刃的劈的角度）
                                                Angle_pDifq1 = acos(dot(Vectorp,Vectorq)/(norm(Vectorp)*norm(Vectorq)));%计算p-刃面与q-刃面形成的二面角
                                                Angle_edge1 = acos(dot(VectorFace1,VectorFace2)/(norm(VectorFace1)*norm(VectorFace2)));
                                                if Angle_pDifq1>=Angle_edge1
                                                    EdgeFactor = Angle_edge1;
                                                else
                                                    if (AngleFace1_p+AngleFace2_q+Angle_pDifq1)<pi
                                                        EdgeFactor = 2*pi-Angle_edge1;
                                                    else
                                                        EdgeFactor = Angle_edge1;
                                                    end
                                                end
                                                %存p-刃平面与入射面的二面角以及q-刃平面与入射面的二面角，这行注释是对的，下面的角错了
                                                Phi = AngleFace1_q;%p-刃平面与入射面（面1，角度小的）的二面角
                                                PhiNext = AngleFace1_p;%q-刃平面与入射面的二面角
                                                %应该要q-刃平面与入射面的二面角

                                                AngleFace1p = acos(dot(VectorFace3,Vectorm)/(norm(VectorFace3)*norm(Vectorm)));
                                                AngleFace2p = acos(dot(VectorFace4,Vectorm)/(norm(VectorFace4)*norm(Vectorm)));

                                                if AngleFace1p<=AngleFace2p
                                                    Face1 = [Face1;fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,3)];
                                                    Face2 = [Face2;fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,4)];
                                                    AngleFace1_p = AngleFace1p;%为下面计算棱的系数做准备
                                                    AngleFace2_p = AngleFace2p;
                                                    AngleFace1_q = acos(dot(VectorFace3,Vectorn)/(norm(VectorFace3)*norm(Vectorn)));
                                                    AngleFace2_q = acos(dot(VectorFace4,Vectorn)/(norm(VectorFace4)*norm(Vectorn)));
                                                else
                                                    Face1 = [Face1;fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,4)];
                                                    Face2 = [Face2;fpDif(Difnum).CombinNuminDif(ArryIndex).Detail(CombinNuminDif2,3)];
                                                    AngleFace1_p = AngleFace2p;
                                                    AngleFace2_p = AngleFace1p;
                                                    AngleFace1_q = acos(dot(VectorFace4,Vectorn)/(norm(VectorFace4)*norm(Vectorn)));
                                                    AngleFace2_q = acos(dot(VectorFace3,Vectorn)/(norm(VectorFace3)*norm(Vectorn)));
                                                end

                                                %存棱的系数（形成刃的劈的角度）
                                                Angle_pDifq2 = acos(dot(Vectorm,Vectorn)/(norm(Vectorm)*norm(Vectorn)));%计算p-刃面与q-刃面形成的二面角
                                                Angle_edge2 = acos(dot(VectorFace3,VectorFace4)/(norm(VectorFace3)*norm(VectorFace4)));
                                                if Angle_pDifq2>=Angle_edge2
                                                    EdgeFactor = [EdgeFactor;Angle_edge2];
                                                else
                                                    if (AngleFace1_p+AngleFace2_q+Angle_pDifq2)<pi
                                                        EdgeFactor = [EdgeFactor;2*pi-Angle_edge2];
                                                    else
                                                        EdgeFactor = [EdgeFactor;Angle_edge2];
                                                    end
                                                end
                                                %存p-刃平面与入射面的二面角以及q-刃平面与入射面的二面角，这行注释是对的，下面的角错了
                                                Phi = [Phi;AngleFace1_q];%p-刃平面与入射面（面1，角度小的）的二面角
                                                PhiNext = [PhiNext;AngleFace1_p];%q-刃平面与入射面的二面角
                                                %应该要q-刃平面与入射面的二面角
                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Face1 = Face1;
                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Face2 = Face2;
                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).EdgeFactor = EdgeFactor;
                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Phi = Phi;
                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).PhiNext = PhiNext;

                                                if (peneNum~=0)
                                                    sym_pe=0;
                                                    for i = 1:peneNum%储存pe信息
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(i,1)=1;%该绕射径的第一条段径
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(i,2)=1;%有透射
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(i,3:5)=TemPeneDif_prl(i).PenePoint;%穿透坐标
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(i,6)=TemPeneDif_prl(i).IndexFace;%面的编号
                                                        sym_pe=sym_pe+1;
                                                        if sym_pe==peneNum
                                                            DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(i,7)=0;
                                                        else
                                                            DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(i,7)=1;
                                                        end
                                                    end
                                                elseif peneNum==0
                                                    DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(1,1) = 1;
                                                    DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(1,2) = 0;
                                                    peneNum = 1;%方便下一段存储   这里才变成1了
                                                end
                                                %D1-Dn即中间绕射径段
                                                if (t32_~=0)
                                                    for k = 1:(Difnum-1)%对每一个中间段进行索引
                                                        if t32(k)==0%若次段没有穿透，则设置pe(K+1,0)
                                                            DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end+1,1) = k+1;
                                                            DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,2) = 0;
                                                        else%否则，进行pe的具体赋值
                                                            sym_pe = 0;
                                                            for i = 1:t32(k)
                                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end+1,1) = k+1;
                                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,2) = 1;
                                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,3:5) = TemPeneDif(k).rr(i).PenePoint;
                                                                DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,6) = TemPeneDif(k).rr(i).IndexFace;%面的标号指的是FOringal里面的行数，这指定了一个唯一的面，并且每个面有一个唯一的标号
                                                                sym_pe = sym_pe+1;
                                                                if sym_pe==t32(k)
                                                                    DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,7) = 0;
                                                                else
                                                                    DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,7) = 1;
                                                                end
                                                            end
                                                        end
                                                    end
                                                elseif t32_==0%如果整条路径都没有穿透，则以此赋值Pe
                                                    for i = 1:(Difnum-1)
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end+1,1) = peneNum+i;
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,2) = 0;
                                                    end
                                                end

                                                %rnq段
                                                if (t31~=0)%保证发生了穿透并且穿透次数少于规定次数
                                                    sym_pe = 0;
                                                    for i = 1:t31
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end+1,1) = Difnum+1;
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,2) = 1;
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,3:5) = TemPeneDif_rnq(i).PenePoint;
                                                        DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,6) = TemPeneDif_rnq(i).IndexFace;%面的标号指的是FOringal里面的行数，这指定了一个唯一的面，并且每个面有一个唯一的标号
                                                        sym_pe = sym_pe+1;
                                                        if sym_pe==t31
                                                            DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,7) = 0;
                                                        else
                                                            DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,7) = 1;
                                                        end
                                                    end
                                                elseif t31==0
                                                    DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end+1,1) = Difnum+1;
                                                    DifInfo(index_Rx).Dif(Difnum).Detail(difnum2).Pe(end,2) = 0;
                                                end
                                                %%%%%%%%%很重要的变量！
                                                difnum2 = difnum2+1;%就是最初两面组合可以发生绕射（当然，需要满足好多好多条件），则总的二阶绕射径+1，即difnum2是该收发端场景下的二阶总绕射数
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    %存储RT计算结果
    GeoInfo(index_Rx).Startpoint = Tx;
    GeoInfo(index_Rx).Finishpoint = Rx;
    GeoInfo(index_Rx).LosInfo = LosInfo(index_Rx);
    GeoInfo(index_Rx).RefInfo = RefInfo(index_Rx).Ref;
    GeoInfo(index_Rx).DifInfo = DifInfo(index_Rx).Dif;
    GeoInfo(index_Rx).Ray_sum=RaySum;
end
%保存所需数据！！！！！！！！！
save([Outputpath '\GeoResult.mat'],'BuildingInfo','SetInfo','GeoInfo') ;
disp('寻径完成')
toc
end


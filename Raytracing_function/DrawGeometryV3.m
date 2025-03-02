function  DrawGeometryV3(Outputpath,OutputpathSca,simulat_params)

%V3 版本包含RIS多径、散射多径的画图;并自动选择
if nargin==0 %如果没有输入，即进行初始化
    clear;clc;
    Outputpath='E:\matlab_code\Raytracing_2024_V5_ris\Output\NorthtaipingzhuangCommunity\Rx_5\Los1Ref2Dif1Pe1';

end
%-----文件导入------
load([Outputpath '\GeoResult.mat'],'BuildingInfo','GeoInfo') ;
if simulat_params.isExistRIS==1
    load([Outputpath '\GeoResult_RIS.mat'],'BuildingInfo','GeoInfo_RIS','risInfo');
end
if simulat_params.diffscatting==1
    load([OutputpathSca '\GeoScaResult.mat'],'BuildingInfo','ScaInfo') ;

end

TxCAl=BuildingInfo.TXInfo;
posInRx=BuildingInfo.RXInfo;
RxNum=size(posInRx,1);

% 设置灰色
grayColor = [0.7, 0.7, 0.7];

for index_Rx = 1:RxNum%每个接收点分别运行
    h = []; % 初始化句柄数组
    legend_labels = {}; % 初始化图例标签
    Rx = posInRx(index_Rx,:);%接收端坐标
    Tx=TxCAl(index_Rx,:);
    figure(index_Rx);
    %画收发点
    h(end+1)=plot3(Tx(1,1),Tx(1,2),Tx(1,3),'k+','linewidth',15);legend_labels{end+1} = 'TX'; % 添加对应的图例标签
    hold on;
    h(end+1)=plot3(Rx(1,1),Rx(1,2),Rx(1,3),'b+','linewidth',15);legend_labels{end+1} = 'RX'; % 添加对应的图例标签
    hold on;
    FaceNum=size(BuildingInfo.Face,2);
    for i = 1:FaceNum
        %画面
        face = BuildingInfo.Face(i).Coordinate;
        patch('Vertices', face, 'Faces', 1:size(face, 1), ...
            'FaceColor', grayColor, 'EdgeColor', 'k', ...
            'FaceAlpha', 0.8, 'LineWidth', 0.5);
    end

    %根据geo画射线
    %LOS画图
    if ~isempty(GeoInfo(index_Rx).LosInfo.Pe)
       h(end+1)=plot3([Tx(1,1),Rx(1,1)],[Tx(1,2),Rx(1,2)],[Tx(1,3),Rx(1,3)],'--r','linewidth',1.3);%RefNum=0,Los
       legend_labels{end+1} = 'LOS'; % 添加对应的图例标签
       %画穿透点
       Pe=GeoInfo(index_Rx).LosInfo.Pe;
       for pii=1:size(Pe,1)
           if Pe(pii,2)==1
               pepoint=Pe(pii,3:5);
               plot3( pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
           end
       end
    end
    RefNum=size(GeoInfo(index_Rx).RefInfo,2);
    iref=0;
    for numref=1:RefNum
        for iray=1:size(GeoInfo(index_Rx).RefInfo(1,numref).Detail,2)
            iref=iref+1;
            %对每一条多径进行循环
            Refpoint=GeoInfo(index_Rx).RefInfo(1,numref).Detail(1,iray).Refpoint;
            %画反射点
            for i=1:size(Refpoint,1)
                plot3(Refpoint(i,1), Refpoint(i,2), Refpoint(i,3),'*r');%画所有的反射点
                hold on;
            end
            %FristRefLine 画的是Tx到Q1的连线，蓝线
            if iref==1
                h(end+1)=plot3([Tx(1,1),Refpoint(1,1)],[Tx(1,2),Refpoint(1,2)],[Tx(1,3),Refpoint(1,3)],'.-b');%FristRefLine
                hold on;legend_labels{end+1} = 'Reflection'; % 添加对应的图例标签
            else
                plot3([Tx(1,1),Refpoint(1,1)],[Tx(1,2),Refpoint(1,2)],[Tx(1,3),Refpoint(1,3)],'.-b');%FristRefLine
                hold on;
            end
            %BetweenRefLine 画的是中间反射点间的连线
            for i= 1:(numref-1)
                plot3([Refpoint(i,1),Refpoint(i+1,1)],[Refpoint(i,2),Refpoint(i+1,2)],[Refpoint(i,3),Refpoint(i+1,3)],'.-b');
                hold on;
            end
            %LastRefLine  画的是Rx到Qn的连线
            plot3([Rx(1,1),Refpoint(numref,1)],[Rx(1,2),Refpoint(numref,2)],[Rx(1,3),Refpoint(numref,3)],'.-b');
            hold on;
            %画穿透点
            Pe=GeoInfo(index_Rx).RefInfo(1,numref).Detail(1,iray).Pe;
            for pii=1:size(Pe,1)
                if Pe(pii,2)==1
                    pepoint=Pe(pii,3:5);
                    plot3( pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
                end
            end
        end
    end
    Difnum=size(GeoInfo(index_Rx).DifInfo,2);
    idif=0;
    for numdif=1:Difnum
        for iray=1:size(GeoInfo(index_Rx).DifInfo(1,numdif).Detail,2)
            idif=idif+1;
            %对每一条多径进行循环
            Difpoint=GeoInfo(index_Rx).DifInfo(1,numdif).Detail(1,iray).Difpoint;
            %画绕射点
            for i=1:size(Difpoint,1)
                plot3(Difpoint(i,1), Difpoint(i,2), Difpoint(i,3),'*r');%画所有的绕射点
                hold on;
            end
            %FristRefLine 画的是Tx到Q1的连线，红线
            if idif==1
                h(end+1)=plot3([Tx(1,1),Difpoint(1,1)],[Tx(1,2),Difpoint(1,2)],[Tx(1,3),Difpoint(1,3)],'.-m');%FristRefLine
                hold on;legend_labels{end+1} = 'Diffraction'; % 添加对应的图例标签
            else
                plot3([Tx(1,1),Difpoint(1,1)],[Tx(1,2),Difpoint(1,2)],[Tx(1,3),Difpoint(1,3)],'.-m');%FristRefLine
                hold on;
            end  
            %BetweenRefLine 画的是中间反射点间的连线
            for i= 1:(numdif-1)
                plot3([Difpoint(i,1),Difpoint(i+1,1)],[Difpoint(i,2),Difpoint(i+1,2)],[Difpoint(i,3),Difpoint(i+1,3)],'.-m');
                hold on;
            end
            %LastRefLine  画的是Rx到Qn的连线
            plot3([Rx(1,1),Difpoint(numdif,1)],[Rx(1,2),Difpoint(numdif,2)],[Rx(1,3),Difpoint(numdif,3)],'.-m');
            hold on;
            %画穿透点
            Pe=GeoInfo(index_Rx).DifInfo(1,numdif).Detail(1,iray).Pe;
            for pii=1:size(Pe,1)
                if Pe(pii,2)==1
                    pepoint=Pe(pii,3:5);
                    plot3(pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
                end
            end
        end
    end
    if simulat_params.isExistRIS==1
        % 进行RIS画图;只放有一个RIS板
        FaceNum_ris=size(risInfo.Face,1);
        for iris = 1:FaceNum_ris
            %画面
            face = risInfo.Face(iris).Coordinate;
            patch('Vertices', face, 'Faces', 1:size(face, 1), ...
                'FaceColor', 'r', 'EdgeColor', 'k', ...
                'FaceAlpha', 0.8, 'LineWidth', 0.5);
            if iris==FaceNum_ris
                h(end+1)=fill3( face(:,1)' , face(:,2)' , face(:,3)' , 'r');
                legend_labels{end+1} = 'RIS'; % 添加对应的图例标签
            end            
            %画RIS路径
            Tx=Tx;Rx=risInfo.Face(iris).CenterPoint;
            %LOS画图
            if ~isempty(GeoInfo_RIS(index_Rx).Tx_RIS(iris).LosInfo.Pe)
                plot3([Tx(1,1),Rx(1,1)],[Tx(1,2),Rx(1,2)],[Tx(1,3),Rx(1,3)],'--r','linewidth',1.3);%RefNum=0,Los
                %画穿透点
                Pe=GeoInfo_RIS(index_Rx).Tx_RIS(iris).LosInfo.Pe;
                for pii=1:size(Pe,1)
                    if Pe(pii,2)==1
                        pepoint=Pe(pii,3:5);
                        plot3( pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
                    end
                end
            end
            RefNum=size(GeoInfo_RIS(index_Rx).Tx_RIS(iris).RefInfo,2);
            for numref=1:RefNum
                for iray=1:size(GeoInfo_RIS(index_Rx).Tx_RIS(iris).RefInfo(1,numref).Detail,2)
                    %对每一条多径进行循环
                    Refpoint=GeoInfo_RIS(index_Rx).Tx_RIS(iris).RefInfo(1,numref).Detail(1,iray).Refpoint;
                    %画反射点
                    for i=1:size(Refpoint,1)
                        plot3(Refpoint(i,1), Refpoint(i,2), Refpoint(i,3),'*r');%画所有的反射点
                        hold on;
                    end
                    %FristRefLine 画的是Tx到Q1的连线，蓝线
                    plot3([Tx(1,1),Refpoint(1,1)],[Tx(1,2),Refpoint(1,2)],[Tx(1,3),Refpoint(1,3)],'.-b');%FristRefLine
                    hold on;
                    %BetweenRefLine 画的是中间反射点间的连线
                    for i= 1:(numref-1)
                        plot3([Refpoint(i,1),Refpoint(i+1,1)],[Refpoint(i,2),Refpoint(i+1,2)],[Refpoint(i,3),Refpoint(i+1,3)],'.-b');
                        hold on;
                    end
                    %LastRefLine  画的是Rx到Qn的连线
                    plot3([Rx(1,1),Refpoint(numref,1)],[Rx(1,2),Refpoint(numref,2)],[Rx(1,3),Refpoint(numref,3)],'.-b');
                    hold on;
                    %画穿透点
                    Pe=GeoInfo_RIS(index_Rx).Tx_RIS(iris).RefInfo(1,numref).Detail(1,iray).Pe;
                    for pii=1:size(Pe,1)
                        if Pe(pii,2)==1
                            pepoint=Pe(pii,3:5);
                            plot3( pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
                        end
                    end
                end
            end
            Difnum=size(GeoInfo_RIS(index_Rx).Tx_RIS(iris).DifInfo,2);
            for numdif=1:Difnum
                for iray=1:size(GeoInfo_RIS(index_Rx).Tx_RIS(iris).DifInfo(1,numdif).Detail,2)
                    %对每一条多径进行循环
                    Difpoint=GeoInfo_RIS(index_Rx).Tx_RIS(iris).DifInfo(1,numdif).Detail(1,iray).Difpoint;
                    %画绕射点
                    for i=1:size(Difpoint,1)
                        plot3(Difpoint(i,1), Difpoint(i,2), Difpoint(i,3),'*r');%画所有的绕射点
                        hold on;
                    end
                    %FristRefLine 画的是Tx到Q1的连线，红线
                    plot3([Tx(1,1),Difpoint(1,1)],[Tx(1,2),Difpoint(1,2)],[Tx(1,3),Difpoint(1,3)],'.-m');%FristRefLine
                    hold on;
                    %BetweenRefLine 画的是中间反射点间的连线
                    for i= 1:(numdif-1)
                        plot3([Difpoint(i,1),Difpoint(i+1,1)],[Difpoint(i,2),Difpoint(i+1,2)],[Difpoint(i,3),Difpoint(i+1,3)],'.-m');
                        hold on;
                    end
                    %LastRefLine  画的是Rx到Qn的连线
                    plot3([Rx(1,1),Difpoint(numdif,1)],[Rx(1,2),Difpoint(numdif,2)],[Rx(1,3),Difpoint(numdif,3)],'.-m');
                    hold on;
                    %画穿透点
                    Pe=GeoInfo_RIS(index_Rx).Tx_RIS(iris).DifInfo(1,numdif).Detail(1,iray).Pe;
                    for pii=1:size(Pe,1)
                        if Pe(pii,2)==1
                            pepoint=Pe(pii,3:5);
                            plot3(pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
                        end
                    end
                end
            end
            %画RIS-Rx的图
            %LOS画图
            Tx=risInfo.Face(iris).CenterPoint;Rx=posInRx(index_Rx,:);%接收端坐标
            if ~isempty(GeoInfo_RIS(index_Rx).RIS_Rx(iris).LosInfo.Pe)
                h(3)=plot3([Tx(1,1),Rx(1,1)],[Tx(1,2),Rx(1,2)],[Tx(1,3),Rx(1,3)],'--r','linewidth',1.3);%RefNum=0,Los
                %画穿透点
                Pe=GeoInfo_RIS(index_Rx).RIS_Rx(iris).LosInfo.Pe;
                for pii=1:size(Pe,1)
                    if Pe(pii,2)==1
                        pepoint=Pe(pii,3:5);
                        plot3( pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
                    end
                end
            end
            RefNum=size(GeoInfo_RIS(index_Rx).RIS_Rx(iris).RefInfo,2);
            for numref=1:RefNum
                for iray=1:size(GeoInfo_RIS(index_Rx).RIS_Rx(iris).RefInfo(1,numref).Detail,2)
                    %对每一条多径进行循环
                    Refpoint=GeoInfo_RIS(index_Rx).RIS_Rx(iris).RefInfo(1,numref).Detail(1,iray).Refpoint;
                    %画反射点
                    for i=1:size(Refpoint,1)
                        plot3(Refpoint(i,1), Refpoint(i,2), Refpoint(i,3),'*r');%画所有的反射点
                        hold on;
                    end
                    %FristRefLine 画的是Tx到Q1的连线，蓝线
                    plot3([Tx(1,1),Refpoint(1,1)],[Tx(1,2),Refpoint(1,2)],[Tx(1,3),Refpoint(1,3)],'.-b');%FristRefLine
                    hold on;
                    %BetweenRefLine 画的是中间反射点间的连线
                    for i= 1:(numref-1)
                        plot3([Refpoint(i,1),Refpoint(i+1,1)],[Refpoint(i,2),Refpoint(i+1,2)],[Refpoint(i,3),Refpoint(i+1,3)],'.-b');
                        hold on;
                    end
                    %LastRefLine  画的是Rx到Qn的连线
                    plot3([Rx(1,1),Refpoint(numref,1)],[Rx(1,2),Refpoint(numref,2)],[Rx(1,3),Refpoint(numref,3)],'.-b');
                    hold on;
                    %画穿透点
                    Pe=GeoInfo_RIS(index_Rx).RIS_Rx(iris).RefInfo(1,numref).Detail(1,iray).Pe;
                    for pii=1:size(Pe,1)
                        if Pe(pii,2)==1
                            pepoint=Pe(pii,3:5);
                            plot3( pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
                        end
                    end
                end
            end
            Difnum=size(GeoInfo_RIS(index_Rx).RIS_Rx(iris).DifInfo,2);
            for numdif=1:Difnum
                for iray=1:size(GeoInfo_RIS(index_Rx).RIS_Rx(iris).DifInfo(1,numdif).Detail,2)
                    %对每一条多径进行循环
                    Difpoint=GeoInfo_RIS(index_Rx).RIS_Rx(iris).DifInfo(1,numdif).Detail(1,iray).Difpoint;
                    %画绕射点
                    for i=1:size(Difpoint,1)
                        plot3(Difpoint(i,1), Difpoint(i,2), Difpoint(i,3),'*r');%画所有的绕射点
                        hold on;
                    end
                    %FristRefLine 画的是Tx到Q1的连线，红线
                    plot3([Tx(1,1),Difpoint(1,1)],[Tx(1,2),Difpoint(1,2)],[Tx(1,3),Difpoint(1,3)],'.-m');%FristRefLine
                    hold on;
                    %BetweenRefLine 画的是中间反射点间的连线
                    for i= 1:(numdif-1)
                        plot3([Difpoint(i,1),Difpoint(i+1,1)],[Difpoint(i,2),Difpoint(i+1,2)],[Difpoint(i,3),Difpoint(i+1,3)],'.-m');
                        hold on;
                    end
                    %LastRefLine  画的是Rx到Qn的连线
                    plot3([Rx(1,1),Difpoint(numdif,1)],[Rx(1,2),Difpoint(numdif,2)],[Rx(1,3),Difpoint(numdif,3)],'.-m');
                    hold on;
                    %画穿透点
                    Pe=GeoInfo_RIS(index_Rx).RIS_Rx(iris).DifInfo(1,numdif).Detail(1,iray).Pe;
                    for pii=1:size(Pe,1)
                        if Pe(pii,2)==1
                            pepoint=Pe(pii,3:5);
                            plot3(pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
                        end
                    end
                end
            end
        end
    end

    %画散射路径
    if simulat_params.diffscatting==1
        %画散射面为黄色的面
        for i_1=1:size(ScaInfo(index_Rx).ScatteringFace,1)
            faceindex=ScaInfo(index_Rx).ScatteringFace(i_1);%获取了散射墙壁编号
            FacePoint=BuildingInfo.Face(faceindex).Coordinate;
            fill3( FacePoint(:,1)' , FacePoint(:,2)' , FacePoint(:,3)' , 'y');
        end
        %画散射路径
        SCaNum=size(ScaInfo(index_Rx).Detail,2);
        for isca_path=1:SCaNum
            ScaPoint=ScaInfo(index_Rx).Detail(1,isca_path).ScaPoint(1:3);
            plot3(ScaPoint(1,1), ScaPoint(1,2), ScaPoint(1,3),'*r');%画所有的散射点
            hold on;
            if isca_path==1
                h(end+1)=plot3([Tx(1,1),ScaPoint(1,1)],[Tx(1,2),ScaPoint(1,2)],[Tx(1,3),ScaPoint(1,3)],'.-g');%FristRefLine
                hold on;legend_labels{end+1} = 'Scatting'; % 添加对应的图例标签
            end
            %FristRefLine 画的是Tx到Q1的连线，蓝线
            plot3([Tx(1,1),ScaPoint(1,1)],[Tx(1,2),ScaPoint(1,2)],[Tx(1,3),ScaPoint(1,3)],'.-g');%FristRefLine
            hold on;
            %LastRefLine  画的是Rx到Qn的连线
            plot3([Rx(1,1),ScaPoint(1,1)],[Rx(1,2),ScaPoint(1,2)],[Rx(1,3),ScaPoint(1,3)],'.-g');
            hold on;
            %画穿透点
            Pe=ScaInfo(index_Rx).Detail(1,isca_path).Pe;
            for pii=1:size(Pe,1)
                if Pe(pii,2)==1
                    pepoint=Pe(pii,3:5);
                    plot3( pepoint(1,1), pepoint(1,2), pepoint(1,3),'+r');%画所有的穿透点
                end
            end
        end
        
    end
    
    
    % 设置视角和光照效果
    axis equal;
    view(3);

    % 添加主光源
    mainLight = light('Position', [1 3 2], 'Style', 'infinite');

    % 添加辅助光源
    auxLight1 = light('Position', [-3 -1 3], 'Style', 'infinite');
    auxLight2 = light('Position', [3 -1 3], 'Style', 'infinite');

    % 设置光照类型
    lighting phong;
    grid on;%添加网线格
    lll=legend(h,legend_labels);%TX\RX
    set(lll,'Fontsize',12,'FontWeight','bold','FontName','Times New Roman','location','northwest');
    xlabel('Length [m]');
    ylabel('Width [m]');
    zlabel('Height [m]');
    set(get(gca,'XLabel'),'FontSize',12,'FontWeight','bold','FontName','Times New Roman');%图上文字为8 point或小5号
    set(get(gca,'YLabel'),'FontSize',12,'FontWeight','bold','FontName','Times New Roman','rotation',-35);
    set(get(gca,'ZLabel'),'FontSize',12,'FontWeight','bold','FontName','Times New Roman');
    set (gca,'position',[0.1,0.12,0.8,0.8] );
    set(gca,'FontSize',12); % 设置文字大小，同时影响坐标轴标注、图例、标题等。


end

end


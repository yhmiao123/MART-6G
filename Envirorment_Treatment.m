% ----------------- 环境处理主函数版本信息 --------------------%
%对给定的仿真环境进行处理，并设置收发端坐标
%V2:该版本可见面avisinfo是一个；即所有Tx必须保持一致；
%该版本加入了RIS设置
clc;clear;
addpath('EnvironmentTreatment_function');addpath('Raytracing_function');

% ----------------- 读取仿真参数 --------------------%
params = read_params('parameters.m');
%NorthtaipingzhuangCommunity场景：%Rx_1:Tx在中间空地上+1个随机的Rx+RIS；Rx_3:Tx在中间空地上+600米范围内均匀Rx；Rx_4:Tx在中间空地上+600米Rx+RIS
%Rx_5：Tx在屋顶上+随机1个Rx
% ----------------- 设置仿真配置 --------------------%
if_change_TxRx=0;

Inputpath = [params.datadir '\Input\' params.scenario_name '\' params.scenario_route];
Outputpath=[params.datadir '\Output\' params.scenario_name '\' params.scenario_route];
if ~exist(Inputpath)
    mkdir(Inputpath);
end
if ~exist(Outputpath)
    mkdir(Outputpath);
end
%-----------------自定义设置收发端坐标----------------%
if if_change_TxRx
    originPoint=[0 0 0];%参考点坐标；
    %--------------这里需要自定义代码块写收发端！！！data = xlsread('image.xlsx', 'A2:C27');
    RxPoint = [20,20,1.5];
    %-----------把发端复制为与Rx数量同样的维度------------%
    TxPoint_ones=ones(size(RxPoint,1),3);TxPoint=[0 0 70].*TxPoint_ones;
    %----------存储收发端坐标：这段不需进行修改--------%
    TxCAl=TxPoint-originPoint;RxCal=RxPoint-originPoint;save([Inputpath '\TxRxData.mat'],'TxCAl','RxCal');
else
    load([Inputpath '\TxRxData.mat'],'TxCAl','RxCal');
end
%-----------------进行环境处理-----------------------%
if params.isExistRIS
    FaceNum=EnvirTreatFormXml_ris(Inputpath,params);%计算并储存BuildingInfo和全局面的面面组合索引；
    [fp_avis,fD_avis]= AccessibleAnalysis_ris(Inputpath,TxCAl(1,:),params);
else
    FaceNum=EnvirTreatFormXml(Inputpath,params);%计算并储存BuildingInfo和全局面的面面组合索引；
    [fp_avis,fD_avis]= AccessibleAnalysis(Inputpath,TxCAl(1,:),params);
end
%-----------------根据发端位置进行可见面的分析处理:场景的Tx保持不变-------------
avisinfo.fp_avis=fp_avis;avisinfo.fD_avis=fD_avis;
save([Inputpath '\VisableInfo.mat'],'avisinfo');


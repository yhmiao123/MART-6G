clc;clear;
%自定义收发端坐标：储存在对应仿真编号下（Rx_id）
%假设仿真N个点位，即需要设置N个收发端对；
% 最终得到TxCAl储存Tx的坐标，TxCAl的维度为N*3，每一行是某对的Tx的三维坐标
%最终得到RxCal储存Rx的坐标，RxCal的维度为N*3，每一行是某对的Rx的三维坐标

%---------------自定义进行收发坐标配置------------------
TxPoint=[1.8 0.75 1.5;
         1.8 0.75 1.5];
Rxstart=[7.5 0.45 1;
         6.5 0.45 1];
originPoint=[0 0 0];%参考点坐标；
RxPoint=Rxstart;
TxCAl=TxPoint-originPoint;
RxCal=RxPoint-originPoint;
%---------------配置储存的场景及仿真的编号Rx_id------------------
%路径信息
datadir = 'E:\matlab_code\Raytracing_2024_V3_ris\Input';%待检测文件夹名称
outadir='E:\matlab_code\Raytracing_2024_V3\Output';%输出文件夹
Scene = 'environment_test_0611';
RxId='Rx_1';%Rx（路线）编号
Inputpath = [datadir '\' Scene '\' RxId];
Output=[outadir '\' Scene '\' RxId];
Inputpath = [datadir '\' Scene '\' RxId];
Output=[outadir '\' Scene '\' RxId];
if ~exist(Inputpath)
    mkdir(Inputpath);
end
if ~exist(Output)
    mkdir(Output);
end
%---------------储存到对应INPUT子文件下------------------
save([Inputpath '\TxRxData.mat'],'TxCAl','RxCal');

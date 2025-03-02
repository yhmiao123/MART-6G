%%%% Ray-tracing parameters set %%%%
% 此文件是RT仿真的所有配置文件
% 环境TxRx位置最后需要保持是一一对照的；Rx有几个，Tx也要有几个；
%散射：用户指定哪些面发生散射（xml指定）以及散射面的散射模型和模型参数（也在xml是最好的，未实现）；
%0512：天线需要给（最大）增益是多少db；
%0522:修正正向寻径；添加数据库寻径
%daetest的Rx2是未平移+无地面  Rx3是场景平移后+地面的结果 Rx4是双面测试场景;Rx5是平移+无地面的场景；Rx6是二次反射双面测试场景
%510HighFre场景：Rx1的xml加了散射标签  Rx2是三个收端  Rx3是一个收端
%510_simply Rx_1  daetest Rx_2  510HighFre Rx_3

%-----------1.Ray-tracing scenario 场景设置----------
%1.0 场景路径和收发端路径
params.datadir = 'E:\matlab_code_2025\Raytracing_2024_V6_Thz_UI_simply';%平台的路径
params.scenario_name = 'indoorRIS';%仿真场景510HighFre shptest daetest 510_simply 910indoor environment_test_0611 NorthtaipingzhuangCommunity  shinei0814 test_diff  beiyou0212
params.scenario_route='Tx_1';%该场景下运行的收发端路径

%1.1 收发端是否移动
params.transceiver_move=[0,0];%0代表静止仿真，无多普勒；1代表移动
params.transceiver_velocity_Tx=[0,0,0]; %速度单位:m/s
params.transceiver_velocity_Rx=[0,10,0]; %速度单位:m/s

%--------------2.Ray-tracing RT仿真设置----------------
%2.0 RT寻径机制和寻径算法
params.RT_LOS = 1;%直射=1/0，是/否需要直射
params.RT_RefNum = 2;%反射次数=Any，可调
params.RT_DifNum = 1;%绕射次数=1/0
params.RT_PeneNum = 1;%穿透次数限制，可调

params.RT_pathfinding=1;%简化版本只支持cpu单核反向计算The simplified version only supports cpu single-core reverse calculation.

%2.1 散射寻径设置
params.diffscatting=0;%是否启动散射
Density=0.5;AngleLimit=15;%网格大小、角度限制、散射模型；
params.diffscatting_information=struct('Density',Density,'AngleLimit',AngleLimit);

%2.2 RIS码本设置
params.isExistRIS=0;%是否启动RIS
RIS(1).x_axis = [0,0,1];
RIS(1).y_axis = [sqrt(2)/2,-sqrt(2)/2,0];
RIS(1).z_axis = cross(RIS(1).x_axis,RIS(1).y_axis)/norm(cross(RIS(1).x_axis,RIS(1).y_axis));
RIS(1).dx = 0.0425;%阵元大小
RIS(1).dy = 0.0425;%阵元大小
RIS(1).R = ones(10,10);%码本
RIS(1).T = zeros(10,10);%码本
params.RIS_Info = RIS;

%2.3 正向寻径细化正二十面体的次数
params.nRefine=20;

%--------------3.天线设置--------------
%3.0 仿真频率
Ant_F=14800;%天线频率(MHz)

Ant_polar=2;%天线极化方式；
%3.1天线设置—Tx设置
Ant_Tx_PT=1;%天线辐射功率，单位W
Ant_Tx_gain=0;%天线（最大）增益；单位db
Ant_Tx_type=1;%1=默认全向天线 2=电偶极子天线 3=用户输入的天线
Ant_Tx_partenpath=[];%天线方向图路径
if Ant_Tx_type==3
    Ant_Tx_partenpath=[params.datadir '\AntennaExample\AntennaEg1.mat'];
end
Ant_Tx_MIMO=0;%是否开启MIMO天线
Ant_Tx_array=[8,8,2];%如果是MIMO天线，需要[x,y,z]方向上的天线数量
Ant_Tx_Spacing=0.5;%如果是MIMO天线，需要天线之间的距离，以波长为单位
params.Ant_Tx_information=struct('Ant_Tx_MIMO',Ant_Tx_MIMO,'Ant_Tx_F',Ant_F,'Ant_PT',Ant_Tx_PT,'Ant_Tx_gain',Ant_Tx_gain,'Ant_Tx_polar',Ant_polar,'Ant_Tx_type',Ant_Tx_type,'Ant_Tx_partenpath',Ant_Tx_partenpath,'Ant_Tx_array',Ant_Tx_array,'Ant_Tx_Spacing',Ant_Tx_Spacing);

%3.2天线设置—Rx设置
Ant_Rx_type=1;%1=默认全向天线 2=电偶极子天线 3=用户输入的天线
Ant_Rx_gain=0;%天线（最大）增益；单位db
Ant_Rx_partenpath=[];%天线方向图路径
if Ant_Rx_type==3
    Ant_Rx_partenpath=[params.datadir '\AntennaExample\AntennaEg1.mat'];
end
Ant_Rx_MIMO=0;%是否开启MIMO天线
Ant_Rx_array=[2,2,1];%如果是MIMO天线，需要[x,y,z]方向上的天线数量
Ant_Rx_Spacing=0.5;%如果是MIMO天线，需要天线之间的距离，以波长为单位
params.Ant_Rx_information=struct('Ant_Rx_MIMO',Ant_Rx_MIMO,'Ant_Rx_F',Ant_F,'Ant_Rx_gain',Ant_Rx_gain,'Ant_Rx_polar',Ant_polar,'Ant_Rx_type',Ant_Rx_type,'Ant_Rx_partenpath',Ant_Rx_partenpath,'Ant_Rx_array',Ant_Rx_array,'Ant_Rx_Spacing',Ant_Rx_Spacing);

%-------------4.系统参数设置---------------
params.system_path_num=20;%选取多少条多径进行参数计算
params.system_fc=Ant_F/1000;%频率单位GHz
params.system_BW=1;%带宽单位GHz
params.system_OFDM=1;%是否开启OFDM
params.effective_filter_activate = 1;%是否使用成型滤波器（有限带宽窗函数）：矩形，升余弦
params.effective_filter_type = 2;%1代表矩形窗；2代表升余弦窗；

%4.1OFDM参数设置，当params.system_OFDM=1设置
OFDM_subcar_space=120*1e-6;%子载波间隔
OFDM_subcar_RBnum=12;%一个资源块RB的子载波数
OFDM_subcar_allnum=floor(params.system_BW/OFDM_subcar_space);%总共带宽下的总子载波数;
OFDM_subcar_sampling_strat=1;%OFDM子载波仿真起始序号
OFDM_subcar_sampling_limit=833;%OFDM子载波仿真结束序号
OFDM_subcar_sampling_factor=12;%%OFDM子载波仿真间隔
OFDM_info=struct('OFDM_subcar_space',OFDM_subcar_space,'OFDM_subcar_RBnum',OFDM_subcar_RBnum,'OFDM_subcar_allnum',OFDM_subcar_allnum,'OFDM_subcar_sampling_strat',OFDM_subcar_sampling_strat,'OFDM_subcar_sampling_limit',OFDM_subcar_sampling_limit,'OFDM_subcar_sampling_factor',OFDM_subcar_sampling_factor);
if params.system_OFDM==0
    params.OFDM_information=[];
else
    params.OFDM_information=OFDM_info;
end

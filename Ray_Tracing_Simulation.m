% ----------------- RT仿真主函数 --------------------%
%{
RT的仿真结果包括：
BuildingInfo：场景的环境信息
GeoInfo：几何寻径结果（直射、反射、透射、绕射）
tElecResults：电磁计算结果（直射、反射、透射、绕射）
ScaInfo：散射的寻径结果
tElecResultsSca：散射的电磁计算结果
GeoInfo_RIS：RIS的寻径结果
tElecResults_RIS：RIS的电磁计算结果
%}
clc;clear;
addpath('Raytracing_function')
% ----------------- 读取仿真参数 --------------------%
simulat_params = read_params('parameters.m');
Inputpath = [simulat_params.datadir '\Input\' simulat_params.scenario_name '\' simulat_params.scenario_route];
Output=[simulat_params.datadir '\Output\' simulat_params.scenario_name '\' simulat_params.scenario_route];
% ----------------- 几何寻径（直射、反射、透射、绕射） --------------------
tic;
SearchPathSet=[simulat_params.RT_LOS;simulat_params.RT_RefNum;simulat_params.RT_DifNum;simulat_params.RT_PeneNum;simulat_params.system_fc*1000];%设置寻径的一些参数
%根据配置选用不同寻径函数
switch simulat_params.RT_pathfinding
    case 1
        [BuildingInfo,SetInfo,GeoInfo,Outputpath]=Search_path_Image1(Inputpath,Output,SearchPathSet);
        %对传播多径画图
        DrawGeometryV3(Outputpath,[],simulat_params);
    case 2
        [BuildingInfo,SetInfo,GeoInfo,Outputpath]=Search_path_Image2(Inputpath,Output,SearchPathSet);
    case 3
        [BuildingInfo,SetInfo,GeoInfo,Outputpath]=Search_path_Image3(Inputpath,Output,SearchPathSet,simulat_params.nRefine);
    case 4
        RSID_Info= RSID_V3 (Inputpath,Output,SearchPathSet);
        [BuildingInfo,SetInfo,GeoInfo,Outputpath]=Search_path_Image4(Inputpath,Output,SearchPathSet,RSID_Info);
    case 5
        [BuildingInfo,SetInfo,GeoInfo,Outputpath]=Search_path_Image5_1(Inputpath,Output,SearchPathSet);
    case 6
        [BuildingInfo,SetInfo,GeoInfo,Outputpath]=Search_path_Image6_1(Inputpath,Output,SearchPathSet);
end
%---------简化版本以下均不可用 None of the following simplified versions are available—------------




% ----------------- 电磁计算（直射、反射、透射、绕射） --------------------%
ElecCalSet=struct('Outputpath',Outputpath,'F',simulat_params.system_fc*1000);
[tElecResults,BuildingInfo,savepath]=ElecCal_V7_Thz(BuildingInfo,GeoInfo,ElecCalSet,simulat_params.Ant_Tx_information,simulat_params.Ant_Rx_information);
% ----------------- 散射径：几何寻径+电磁计算 --------------------%
if simulat_params.diffscatting
    [BuildingInfo,ScaInfo,OutputpathSca] = Search_path_Scattering2(Inputpath,Output,simulat_params.diffscatting_information,simulat_params.system_fc);
    ElecCalSetSca=struct('Outputpath',OutputpathSca,'F',simulat_params.system_fc*1000);
    [tElecResultsSca,BuildingInfo]=ElecCal_Sca_V3_Thz(BuildingInfo,ScaInfo,ElecCalSetSca,simulat_params.Ant_Tx_information,simulat_params.diffscatting_information);
    %目前由于散射过于依赖于参数，因此只把把散射径用于大尺度参数建模中；large-scale
else
    tElecResultsSca=[];ScaInfo=[];OutputpathSca=[];
end
% ----------------- RIS：几何寻径+电磁计算 --------------------%
%如果有RIS，单独寻径RT，然后需要将结果+电磁计算和一般路径合并起来；再进行channel生成；
%目前，RIS的电磁计算只输出大尺度功率；多径信息储存空间太大不给出；
if simulat_params.isExistRIS
    %需要寻RIS径
    [BuildingInfo,SetInfo,GeoInfo_RIS,Outputpath]=Search_path_RIS1(Inputpath,Output,SearchPathSet);
    [tElecResults_RIS,BuildingInfo]=ElecCal_RIS(simulat_params.RIS_Info,BuildingInfo,GeoInfo_RIS,ElecCalSet,simulat_params.Ant_Tx_information,simulat_params.Ant_Rx_information);
else
    tElecResults_RIS=[];GeoInfo_RIS=[];
end
%对传播多径画图
DrawGeometryV3(Outputpath,OutputpathSca,simulat_params);
%DrawGeometryV4(Outputpath,OutputpathSca,simulat_params);
%参数合成--存在问题：V1合成RIS的多径信息；V2只合成RIS的总功率；
tElecResults_addRIS=ElecResultCompoundV2(tElecResults,tElecResults_RIS);
% ----------------- 信道参数生成-------------------%
channel_small_scale=Construct_channel_small_scale_V5(tElecResults_addRIS,simulat_params,savepath);
channel_large_scale=Construct_channel_large_scale(tElecResults_addRIS,tElecResultsSca,simulat_params,channel_small_scale);
% ----------------- 整理仿真结果-------------------%
RT_result.simulat_params=simulat_params;RT_result.geo_result=struct('GeoInfo',GeoInfo,'ScaInfo',ScaInfo);RT_result.elc_result=struct('tElecResults',tElecResults,'tElecResultsSca',tElecResultsSca);RT_result.channel_result=struct('channel_small_scale',channel_small_scale,'channel_large_scale',channel_large_scale);
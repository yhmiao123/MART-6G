%STAR-RIS element Ge
function [Etheta, Ephi]  = sRISElementGe(thetaIn, phiIn, thetaOut, phiOut, dx, dy, lambda, polar,T,R,TR)
%输入 入射垂直角，入射水平角，出射垂直角，出射水平角，阵元长度，阵元宽度，波长，入射极化方式0-垂直 1-水平，透射系数， 反射系数，
%TR反射或透射，TR=0反射，TR=1透射
%输出 假设入射电场强度为1，输出两种极化的反射信号强度。
%斜入射
yita = 120*pi;
if((R+T) ~= 1)
    Ze = yita/2*(1+(R+T))/(1-(R+T));
else
    Ze = 1e10;
end
if((R-T) ~= 1)
    Zm = 2*yita*(1+(R-T))/(1-(R-T));
else
    Zm = 1e10;
end
RTE = -yita/cos(thetaIn)/(2*Ze+yita/cos(thetaIn))+Zm/(Zm+2*yita/cos(thetaIn));
TTE = 2*Ze/(2*Ze+yita/cos(thetaIn))-Zm/(Zm+2*yita/cos(thetaIn));
RTM = -(-yita*cos(thetaIn)/(2*Ze+yita*cos(thetaIn))+Zm/(Zm+2*yita*cos(thetaIn)));
TTM = 2*Ze/(2*Ze+yita*cos(thetaIn))-Zm/(Zm+2*yita*cos(thetaIn));
% RTE = -1;
% TTE = 0;
% RTM = 1;
% TTM = 0;
RTE = R;
TTE = T;
RTM = R;
TTM = T;
%ge = dx*dy/(1j*lambda)*(1 + cos(thetaOut))/2
beta = 2*pi/lambda;
X = beta*dx/2*(sin(thetaOut)*cos(phiOut) + sin(thetaIn)*cos(phiIn))+1e-5;
Y = beta*dy/2*(sin(thetaOut)*sin(phiOut) + sin(thetaIn)*sin(phiIn))+1e-5;
if (TR == 0)%反射
    if(polar == 0)%垂直极化
        Etheta1 = -1j*dx*dy*beta/(4*pi)*(-sin(phiIn+pi/2)*sin(phiOut)-cos(phiIn+pi/2)*cos(phiOut)-cos(thetaIn)*sin(phiIn)*cos(thetaOut)*cos(phiOut)+cos(thetaIn)*cos(phiIn)*cos(thetaOut)*sin(phiOut))*sin(X)/X*sin(Y)/Y;
        Ephi1 = 1j*dx*dy*beta/(4*pi)*(sin(phiIn+pi/2)*cos(thetaOut)*cos(phiOut)-cos(phiIn+pi/2)*cos(thetaOut)*sin(phiOut)-cos(thetaIn)*sin(phiIn)*sin(phiOut)-cos(thetaIn)*cos(phiIn)*cos(phiOut))*sin(X)/X*sin(Y)/Y;
        Etheta2 = -1j*dx*dy*beta/(4*pi)*(-sin(phiIn+pi/2)*sin(phiOut)-cos(phiIn+pi/2)*cos(phiOut)+cos(thetaIn)*sin(phiIn)*cos(thetaOut)*cos(phiOut)-cos(thetaIn)*cos(phiIn)*cos(thetaOut)*sin(phiOut))*sin(X)/X*sin(Y)/Y;
        Ephi2 = 1j*dx*dy*beta/(4*pi)*(sin(phiIn+pi/2)*cos(thetaOut)*cos(phiOut)-cos(phiIn+pi/2)*cos(thetaOut)*sin(phiOut)+cos(thetaIn)*sin(phiIn)*sin(phiOut)+cos(thetaIn)*cos(phiIn)*cos(phiOut))*sin(X)/X*sin(Y)/Y;
        Ephi = RTE*Ephi2;
        Etheta = RTE*Etheta2;
%         Ephi = Ephi1;
%         Etheta = Etheta1;
    else%平行极化波反射电场正方向如何选取？
        Etheta1 = -1j*dx*dy*beta/(4*pi)*(-cos(thetaIn)*sin(phiIn+pi)*sin(phiOut)-cos(thetaIn)*cos(phiIn+pi)*cos(phiOut)-sin(phiIn+pi/2)*cos(thetaOut)*cos(phiOut)+cos(phiIn+pi/2)*cos(thetaOut)*sin(phiOut))*sin(X)/X*sin(Y)/Y;
        Ephi1 = 1j*dx*dy*beta/(4*pi)*(cos(thetaIn)*sin(phiIn+pi)*cos(thetaOut)*cos(phiOut)-cos(thetaIn)*cos(phiIn+pi)*cos(thetaOut)*sin(phiOut)-sin(phiIn+pi/2)*sin(phiOut)-cos(phiIn+pi/2)*cos(phiOut))*sin(X)/X*sin(Y)/Y;
        Etheta2 = -1j*dx*dy*beta/(4*pi)*(cos(thetaIn)*sin(phiIn+pi)*sin(phiOut)+cos(thetaIn)*cos(phiIn+pi)*cos(phiOut)-sin(phiIn+pi/2)*cos(thetaOut)*cos(phiOut)+cos(phiIn+pi/2)*cos(thetaOut)*sin(phiOut))*sin(X)/X*sin(Y)/Y;
        Ephi2 = 1j*dx*dy*beta/(4*pi)*(-cos(thetaIn)*sin(phiIn+pi)*cos(thetaOut)*cos(phiOut)+cos(thetaIn)*cos(phiIn+pi)*cos(thetaOut)*sin(phiOut)-sin(phiIn+pi/2)*sin(phiOut)-cos(phiIn+pi/2)*cos(phiOut))*sin(X)/X*sin(Y)/Y;
%         Etheta = Etheta1;
%         Ephi = Ephi1;
        Etheta = RTM*Etheta2;
        Ephi = RTM*Ephi2;
    end
else%透射
    %thetaIn = pi - thetaOut;
    if(polar == 0)
        Etheta = -1j*dx*dy*beta/(4*pi)*(sin(phiIn+pi/2)*sin(phiOut)+cos(phiIn+pi/2)*cos(phiOut)+cos(thetaIn)*sin(phiIn)*cos(thetaOut)*cos(phiOut)-cos(thetaIn)*cos(phiIn)*cos(thetaOut)*sin(phiOut))*sin(X)/X*sin(Y)/Y;
        Ephi = 1j*dx*dy*beta/(4*pi)*(-sin(phiIn+pi/2)*cos(thetaOut)*cos(phiOut)+cos(phiIn+pi/2)*cos(thetaOut)*sin(phiOut)+cos(thetaIn)*sin(phiIn)*sin(phiOut)+cos(thetaIn)*cos(phiIn)*cos(phiOut))*sin(X)/X*sin(Y)/Y;
        Etheta = TTE*Etheta;
        Ephi = TTE*Ephi;
    else
        Etheta = -1j*dx*dy*beta/(4*pi)*(cos(thetaIn)*sin(phiIn+pi)*sin(phiOut)+cos(thetaIn)*cos(phiIn+pi)*cos(phiOut)+sin(phiIn+pi/2)*cos(thetaOut)*cos(phiOut)-cos(phiIn+pi/2)*cos(thetaOut)*sin(phiOut))*sin(X)/X*sin(Y)/Y;
        Ephi = 1j*dx*dy*beta/(4*pi)*(-cos(thetaIn)*sin(phiIn+pi)*cos(thetaOut)*cos(phiOut)+cos(thetaIn)*cos(phiIn+pi)*cos(thetaOut)*sin(phiOut)+sin(phiIn+pi/2)*sin(phiOut)+cos(phiIn+pi/2)*cos(phiOut))*sin(X)/X*sin(Y)/Y;
        Etheta = TTM*Etheta;
        Ephi = TTM*Ephi;
    end
end
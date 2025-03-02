%直角坐标转化成球坐标 theta是俯仰角；phi是方位角
function [phi,theta,R]=sph2rec(Vector_in)
    x=Vector_in(1);
    y=Vector_in(2);
    z=Vector_in(3);
    R = sqrt(x.^2 + y.^2 + z.^2);
    if R ~=0
        theta = acos( z/R );
        phi=atan(y/x);

        if x>=0
            phi=phi;
        else
            phi=phi+pi;
        end
        if phi>pi
            phi=phi-2*pi;
        end

    
        phi=phi/pi*180;
        theta=theta/pi*180;
        theta=90-theta;
    else
        theta=0;
        phi=0;

    end
    
    
end

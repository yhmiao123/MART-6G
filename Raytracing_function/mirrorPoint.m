function mirrorPoint=mirrorPoint(m_perpendicular,point,y,d)
if abs( m_perpendicular)==inf%m==0


    mirrorPoint=[point(1),2*y(2)-point(2)];
elseif  m_perpendicular==0%m==inf
    mirrorPoint=[2*y(1)-point(1),point(2)];
else
    mirrorPoint=[point(1)- 2 * d / sqrt(1 + m_perpendicular^2),point(2)- 2 * d * m_perpendicular / sqrt(1 + m_perpendicular^2)];
end
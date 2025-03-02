function E_rough=t_Location_Scale_dis(mu_E,sigma_E,nu_E )
%T_LOCATION_SCALE_DIS 此处显示有关此函数的摘要
% 定义角度分辨率为1度
theta = 0:1:180;  % 仰角范围 [0, 180] 度
phi = 0:1:360;    % 方位角范围 [0, 360] 度

% 初始化散射强度矩阵
E_rough = zeros(length(theta), length(phi));

% 使用t Location-Scale分布生成散射强度数据
pdf = @(x, mu, sigma, nu) (gamma((nu+1)/2) ./ (sigma * sqrt(nu * pi) * gamma(nu/2))) .* ...
                         (1 + ((x - mu).^2) ./ (nu * sigma^2)).^(-(nu+1)/2);

% 使用接受-拒绝采样法生成符合分布的随机数据
pdf_max = max(pdf(linspace(-10, 10, 1000), mu_E, sigma_E, nu_E));  % 获取PDF的最大值

% 为每个方向生成随机的散射强度值
for i = 1:length(theta)
    for j = 1:length(phi)
        accepted = false;
        while ~accepted
            % 在 [-10, 10] 范围内生成候选样本
            x_candidate = (rand * 20) - 10;
            y_candidate = rand * pdf_max;
            % 如果候选样本满足分布，则接受该样本
            if y_candidate < pdf(x_candidate, mu_E, sigma_E, nu_E)
                E_rough(i, j) = x_candidate;
                accepted = true;
            end
        end
    end
end

end


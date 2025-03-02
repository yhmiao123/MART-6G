function pRefine = RefineTriangle(pTri, nRefine)%细分三角形的新的顶点可以用边向量为基底，然后线性组合表示
nPoint = 0.5 * (nRefine+1) * (nRefine + 2);
pRefine = zeros(round(nPoint), 3);

v1 = pTri(2, :) - pTri(1, :);
v2 = pTri(3, :) - pTri(2, :);
countPoint = 0;
for ii = 0 : nRefine
    for jj = 0 : ii
        countPoint = countPoint + 1;
        pRefine(countPoint, :) = ...
            pTri(1, :) + (ii / nRefine) * v1 + (jj / nRefine) * v2;



    end     % /* for jj */
end     % /* for ii */
end     % /* RefineTriangle */
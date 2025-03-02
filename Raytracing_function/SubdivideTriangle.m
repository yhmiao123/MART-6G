function pointEachPlane = SubdivideTriangle(triVertex, nSubdiv)
v1 = triVertex(2, :) - triVertex(1, :);
v2 = triVertex(3, :) - triVertex(2, :);

countPoint = 0;
for i = 0:nSubdiv
    for j = 0:i
        countPoint = countPoint + 1;
        pointEachPlane(countPoint, :) = triVertex(1, :) + (i / nSubdiv) * v1 + (j / nSubdiv) * v2;
    end
end
end
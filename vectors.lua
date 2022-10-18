function VectorsModule()
    Vectors = {}

    function Vectors.DirRandom()
        return VecNormalize { math.random() - 0.5, math.random() - 0.5, math.random() - 0.5 }
    end
end

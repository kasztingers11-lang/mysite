return {
    LuaVersion = 'Lua51';
    NameGenerator = 'MangledShuffled';
    PrettyPrint = false;
    Seed = 121312;
    Steps = {
        {Name = 'EncryptStrings'; Settings = {}};
        {Name = 'ConstantArray'; Settings = {
            Threshold = 1; StringsOnly = true; Shuffle = true; Rotate = true;
            LocalWrapperThreshold = 0; Encoding = 'base64';
        }};
        {Name = 'WrapInFunction'; Settings = {Iterations = 1}};
    };
}

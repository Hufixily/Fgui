local Helper = fclass();

local exportedClassInfo--到处类对象集合
local exportedTypeInfo-- 到处类型集合
local pkgInfo--包信息
local classPath--类的路径

local pkgName = nil;

function Helper:ctor(pkg)
    pkgName = pkg.name;

    exportedClassInfo = {};
    exportedTypeInfo = {};
    pkgInfo = {};
    classPath = {};
end

function Helper:Analyze(classes)
    for i = 0, classes.Count - 1 do
        local item = classes[i];
        exportedClassInfo[item.className] = item;
    end

    for _, classInfo in pairs(exportedClassInfo) do
        for j = 0, classInfo.members.Count - 1 do
            local info = classInfo.members[j];
            local name = info.name;
            local type = info.type;
            if info.res and info.res.exported then
                --同pkg
                if info.res.owner.name == pkgName then
                    if exportedClassInfo[type] then
                        exportedTypeInfo[name] = type;
                    else
                        exportedTypeInfo[name] = info.res.type;
                    end
                else
                    -- 跨包
                    if not pkgInfo[name] then
                        pkgInfo[name] = info.res.owner.name;
                    end
                    exportedTypeInfo[name] = type;
                end
            else
                exportedTypeInfo[name] = type;
            end
        end
    end
    fprint("F1");
end

local function GetGType(type)
    if type == "GImage" then
        return ".asImage";
    elseif type == "GComponent" then
        return ".asCom";
    elseif type == "GButton" then
        return ".asButton";
    elseif type == "GLabel" then
        return ".asLabel";
    elseif type == "GProgressBar" then
        return ".asProgress";
    elseif type == "GSlider" then
        return ".asSlider";
    elseif type == "GComboBox" then
        return ".asComboBox";
    elseif type == "GTextField" then
        return ".asTextField";
    elseif type == "GRichTextField" then
        return ".asRichTextField";
    elseif type == "GTextInput" then
        return ".asTextInput";
    elseif type == "GLoader" then
        return ".asLoader";
    elseif type == "GLoader3D" then
        return ".asLoader3D";
    elseif type == "GList" then
        return ".asList";
    elseif type == "GGraph" then
        return ".asGraph";
    elseif type == "GGroup" then
        return ".asGroup";
    elseif type == "GMovieClip" or type == "Transition" then
        return ".asMovieClip";
    elseif type == "GTree" then
        return ".asTree";
    else
        return nil;
    end
end

------------------------------------write-----------------------------------
local function GetRequirePath(memberInfo)
    if classPath[memberInfo.name] then
        return classPath[memberInfo.name];
    end

    local name = pkgInfo[memberInfo.name] or pkgName;
    local classType = memberInfo.type;
    local path = string.format("game.gen.%s", name);
    classPath[classType] = path;
    return path;
end

local function WriteRequire(classInfo, templateStr)
    local str = "";
    local created = {};
    for i = 0, classInfo.members.Count - 1 do
        local info = classInfo.members[i];
        local type = info.type;
        if exportedClassInfo[type] and not created[type] then
            local path = GetRequirePath(info);
            str = str .. string.format('require "%s.%s";\n', path, type);
            created[type] = 1;
        end
    end
    templateStr = string.gsub(templateStr, "$classRequire", str);
    return templateStr;
end

local function WriteFieldInfo(classInfo, templateStr)
    local str = "";
    --class
    for i = 0, classInfo.members.Count - 1 do
        local info = classInfo.members[i];
        local type = info.type;
        if exportedClassInfo[type] then
            str = str .. string.format('\tself.%s = %s.new();\n', info.varName, info.type);
            str = str .. string.format('\tself.%s:OnCreate(gComponent:GetChild("%s"))\n', info.varName, info.name, info.name);
        end
    end

    str = str.."\n";
    --field
    for i = 0, classInfo.members.Count - 1 do
        local info = classInfo.members[i];
        local type = exportedTypeInfo[info.name];
        if not exportedClassInfo[type] then
            local typeStr = GetGType(type);
            if type ~= "Controller" then
                str = str .. string.format('\tself.%s = gComponent:GetChild("%s")%s;\n', info.varName, info.name, typeStr);
            else
                str = str .. string.format('\tself.%s = gComponent:GetController("%s");\n', info.varName, info.name);
            end
        end
    end
    templateStr = string.gsub(templateStr, "$classField", str);
    return templateStr;
end

function Helper:Write(classInfo, templateStr)
    local tempStr = templateStr;
    tempStr = string.gsub(tempStr, "$className", classInfo.className);
    tempStr = WriteRequire(classInfo, tempStr);
    tempStr = WriteFieldInfo(classInfo, tempStr);
    return tempStr;
end

function Helper:All()
    return exportedClassInfo;
end

return Helper;
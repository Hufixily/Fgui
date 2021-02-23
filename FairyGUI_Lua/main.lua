local App = CS.FairyEditor.App
local LuaWriter = require(PluginPath .. "/writer");
local util = require(PluginPath .. "/util");
local print_table = util.print_table;
local consoleView = App.consoleView;
local Directory = CS.System.IO.Directory;
local File = CS.System.IO.File;

local _templatePath = PluginPath .. "/template.txt";
local _nameSpace = "CS.FairyGUI";
local _customSetting;
local SettingKey = {
    gen_lua = { name = "gen_lua", default_value = "false" },
    gen_extension_name = { name = "gen_extension_name", default_value = "lua.text" },
}
local function GetSettingValue(key_name)
    if (_customSetting and _customSetting:ContainsKey(key_name)) then
        return _customSetting:get_Item(key_name);
    else
        return SettingKey[key_name].default_value;
    end
end

local exportedClassInfos;
local gTypeInfos;
local function CollectAll(classes)
    exportedClassInfos = {};
    gTypeInfos = {};
    --all class
    for i = 0, classes.Count - 1 do
        local item = classes[i];
        if item.res and item.res.exported and not exportedClassInfos[item.resName] then
            exportedClassInfos[item.className] = item;
        end
        gTypeInfos[item.className] = item.superClassName;
    end
    --all base type
    for resName, classInfo in pairs(exportedClassInfos) do
        for j = 0, classInfo.members.Count - 1 do
            local item = classInfo.members[j];
            if item.res and item.res.exported then
                gTypeInfos[item.type] = item.res.type;
            elseif gTypeInfos[item.type] then
                gTypeInfos[item.type] = gTypeInfos[item.type];
            else
                gTypeInfos[item.type] = item.type;
            end
        end
    end
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
        return "." .. type;
    end
end

--analyze mask
local function WriteRequire(classInfo, templateStr, path)
    local str = "";
    local created = {};
    for i = 0, classInfo.members.Count - 1 do
        local info = classInfo.members[i];
        if info.res and info.res.exported and not created[info.type] then
            fprint(info.type);
            str = str .. string.format('require "%s.%s";\n', path, info.type);
            created[info.type] = 1;
        end
    end
    templateStr = string.gsub(templateStr, "$classRequire", str);
    return templateStr;
end

--analyze classnfo
local function WriteClassFieldInfo(classInfo, templateStr)
    local str = "\n";
    --
    for i = 0, classInfo.members.Count - 1 do
        local info = classInfo.members[i];
        local typeStr = GetGType(gTypeInfos[info.type]);
        if info.res and info.res.exported then
            str = str .. string.format('\tself.%s = %s.new();\n', info.varName, info.type);
            str = str .. string.format('\tself.%s:OnCreate(gComponent:GetChild("%s"))\n', info.varName, info.name, info.name);
        end
    end
    --
    str = str .. "\n";
    for i = 0, classInfo.members.Count - 1 do
        local info = classInfo.members[i];
        local typeStr = GetGType(gTypeInfos[info.type]);
        if not info.res or info.res.exported == false then
            str = str .. string.format('\tself.%s = gComponent:GetChild("%s")%s;\n', info.varName, info.name, typeStr);
        end
    end
    templateStr = string.gsub(templateStr, "$classField", str);
    return templateStr;
end

local function genCode(handler)
    if File.Exists(_templatePath) == false then
        fprint("TemplatePath No Find in :" .. _templatePath);
        return ;
    end

    local settings = handler.project:GetSettings("Publish").codeGeneration;
    local codePkgName = handler:ToFilename(handler.pkg.name);
    local exportCodePath = handler.exportCodePath .. "/" .. codePkgName;
    local genExtension = GetSettingValue(SettingKey.gen_extension_name.name);
    handler:SetupCodeFolder(exportCodePath, genExtension);
    --
    CollectAll(handler:CollectClasses(settings.ignoreNoname, settings.ignoreNoname, nil));
    --
    local templateStr = File.ReadAllText(PluginPath .. "/template.txt");
    local writer = LuaWriter.new({ blockFromNewLine = false, usingTabs = true });
    fprint("gen begin");
    local path = string.gsub(exportCodePath, '\\', '.')
    path = path.gsub(exportCodePath, '/', '.');
    local index = string.find(path, 'game');
    local requirePath = string.sub(path, index);
    for className, info in pairs(exportedClassInfos) do
        local tempStr = templateStr;
        tempStr = string.gsub(tempStr, "$className", className);
        tempStr = WriteRequire(info, tempStr, requirePath);
        tempStr = WriteClassFieldInfo(info, tempStr);
        writer:writeln('%s', tempStr);
        writer:save(exportCodePath .. '/' .. className .. '.' .. genExtension);
        writer:reset();
        -- fprint("res gen finish:" .. resName);
    end
    fprint("gen all");
end

function onPublish(handler)
    if not handler.genCode or handler.publishDescOnly then
        return
    end
    handler.genCode = false;
    _customSetting = App.project:GetSettings("CustomProperties").elements;
    local gen_lua = GetSettingValue(SettingKey.gen_lua.name);
    if gen_lua == "true" then
        consoleView:Clear();
        genCode(handler);
    end
end
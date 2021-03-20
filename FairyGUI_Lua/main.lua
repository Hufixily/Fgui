--package.cpath = package.cpath .. ';C:/Users/admin/AppData/Roaming/JetBrains/IdeaIC2020.3/plugins/intellij-emmylua/classes/debugger/emmy/windows/x64/?.dll'
--local dbg = require('emmy_core')
--dbg.tcpConnect('localhost', 9966)

local App = CS.FairyEditor.App
local _pluginPath = PluginPath;
local LuaWriter = require(_pluginPath .. "/writer");
local util = require(_pluginPath .. "/util");
local Helper = require(_pluginPath .. "/helper");

local print_table = util.print_table;
local consoleView = App.consoleView;
local File = CS.System.IO.File;

local _templatePath = _pluginPath .. "/template.txt";
local _extension = "lua.text";

local function genCode(handler)
    if File.Exists(_templatePath) == false then
        fprint("TemplatePath No Find in :" .. _templatePath);
        return
    end
    --set up folder
    local settings = handler.project:GetSettings("Publish").codeGeneration;
    local codePkgName = handler:ToFilename(handler.pkg.name);
    local exportCodePath = handler.exportCodePath .. "/" .. codePkgName;
    handler:SetupCodeFolder(exportCodePath, _extension);
    --template
    local templateStr = File.ReadAllText(_pluginPath .. "/template.txt");
    local writer = LuaWriter.new({ blockFromNewLine = false, usingTabs = true });

    --analyze
    local helper = Helper.new(handler.pkg);
    helper:Analyze(handler:CollectClasses(settings.ignoreNoname, settings.ignoreNoname, nil));

    --write
    local exportedClassInfo = helper.All();
    for className, classInfo in pairs(exportedClassInfo) do
        local tempStr = helper:Write(classInfo, templateStr)
        writer:writeln('%s', tempStr);
        writer:save(exportCodePath .. '/' .. className .. '.' .. _extension);
        fprint(exportCodePath .. '/' .. className .. '.' .. _extension);
        writer:reset();
    end
    fprint("Gen Code Finish");
end

function onPublish(handler)
    if not handler.genCode then
        return
    end
    consoleView:Clear();
    handler.genCode = false;
    genCode(handler);
end
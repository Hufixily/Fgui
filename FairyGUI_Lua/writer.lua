local LuaCodeWriter = fclass()

function LuaCodeWriter:ctor(config)
    config = config or {}
    self.blockStart = config.blockStart or '{'
    self.blockEnd = config.blockEnd or '}'
    self.blockFromNewLine = config.blockFromNewLine
    if self.blockFromNewLine == nil then
        self.blockFromNewLine = true
    end
    if config.usingTabs then
        self.indentStr = '\t'
    else
        self.indentStr = '    '
    end
    self.usingTabs = config.usingTabs
    self.endOfLine = config.endOfLine or '\n'
    self.lines = {}
    self.indent = 0

    self:writeMark()
end

function LuaCodeWriter:writeMark()
    table.insert(self.lines, '--- This is an automatically generated class by FairyGUI Editor ---')
    table.insert(self.lines, '---  Please do not modify it. ---')
    table.insert(self.lines, '')
end

function LuaCodeWriter:writeln(format, ...)
    if not format then
        table.insert(self.lines, '')
        return
    end

    local str = ''
    for i = 0, self.indent - 1 do
        str = str .. self.indentStr
    end
    str = str .. string.format(format, ...)
    table.insert(self.lines, str)

    return self
end

function LuaCodeWriter:startBlock()
    if self.blockFromNewLine or #self.lines == 0 then
        self:writeln(self.blockStart)
    else
        local str = self.lines[#self.lines]
        self.lines[#self.lines] = str .. ' ' .. self.blockStart
    end
    self.indent = self.indent + 1
    return self
end

function LuaCodeWriter:endBlock()
    self.indent = self.indent - 1
    self:writeln(self.blockEnd)
    return self
end

function LuaCodeWriter:incIndent()
    self.indent = self.indent + 1
    return self
end

function LuaCodeWriter:decIndent()
    self.indent = self.indent - 1
    return self
end

function LuaCodeWriter:reset()
    if #self.lines > 0 then
        self.lines = {}
    end
    self.indent = 0
    self:writeMark()
end

function LuaCodeWriter:tostring()
    return table.concat(self.lines, self.endOfLine)
end

function LuaCodeWriter:save(filePath)
    local str = table.concat(self.lines, self.endOfLine)
    CS.System.IO.File.WriteAllText(filePath, str)
end

return LuaCodeWriter;
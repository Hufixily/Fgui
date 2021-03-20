local util = {};

local function print_table (t)
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        local str = "";
        if (print_r_cache[tostring(t)]) then
            str = str + indent .. "*" .. tostring(t) .. "\n";
        else
            print_r_cache[tostring(t)] = true
            if (type(t) == "table") then
                for pos, val in pairs(t) do
                    if (type(val) == "table") then
                        str = str + indent .. "[" .. pos .. "] => " .. tostring(t) .. " {\n"
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                        str = str + indent .. string.rep(" ", string.len(pos) + 6) .. "} \n";
                    elseif (type(val) == "string") then
                        str = str + indent .. "[" .. pos .. '] => "' .. val .. '"\n';
                    else
                        str = str + indent .. "[" .. pos .. "] => " .. tostring(val) .."\n";
                    end
                end
            else
                str = str + indent .. tostring(t) .."\n";
            end
        end
        fprint(str);
    end
    if (type(t) == "table") then
        fprint(tostring(t) .. " {")
        sub_print_r(t, "  ")
        fprint("}")
    else
        sub_print_r(t, "  ")
    end
    fprint()
end

util.print_table = print_table;
return util;
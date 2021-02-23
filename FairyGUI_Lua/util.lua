local util = {};

local function print_table ( t )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            fprint(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        fprint(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        fprint(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        fprint(indent.."["..pos..'] => "'..val..'"')
                    else
                        fprint(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                fprint(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        fprint(tostring(t).." {")
        sub_print_r(t,"  ")
        fprint("}")
    else
        sub_print_r(t,"  ")
    end
    fprint()
end

util.print_table = print_table;
return util;
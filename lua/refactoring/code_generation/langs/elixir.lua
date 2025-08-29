local code_utils = require("refactoring.code_generation.utils")

local function elixir_function(opts)
    local args = next(opts.args) and table.concat(opts.args, ", ") or ""
    local visibility = opts.scope_type == "defp" and "defp" or "def"
    
    if opts.func_header == nil then
        opts.func_header = ""
    end
    
    -- Handle single-line vs multi-line functions
    local body_str = code_utils.stringify_code(opts.body)
    local lines = vim.split(body_str, "\n")
    local non_empty_lines = vim.tbl_filter(function(line)
        return vim.trim(line) ~= ""
    end, lines)
    
    -- Use single-line syntax for simple cases
    if #non_empty_lines == 1 and string.len(non_empty_lines[1]) < 60 then
        return ([[
%s%s %s(%s), do: %s

]]):format(opts.func_header, visibility, opts.name, args, vim.trim(non_empty_lines[1]))
    else
        return ([[
%s%s %s(%s) do
%s
end

]]):format(opts.func_header, visibility, opts.name, args, body_str)
    end
end

local function elixir_constant(opts)
    local constant_string_pattern
    
    if opts.multiple then
        constant_string_pattern = ("%s = %s\n"):format(
            table.concat(opts.identifiers, ", "),
            table.concat(opts.values, ", ")
        )
    else
        local name
        if opts.name[1] ~= nil then
            name = opts.name[1]
        else
            name = opts.name
        end
        
        if not opts.statement then
            opts.statement = "%s = %s"
        end
        
        constant_string_pattern = (opts.statement .. "\n"):format(
            name,
            opts.value
        )
    end
    
    return constant_string_pattern
end

---@type refactor.CodeGeneration
local elixir = {
    comment = function(statement)
        return ("# %s"):format(statement)
    end,
    constant = function(opts)
        return elixir_constant(opts)
    end,
    ["function"] = elixir_function,
    function_return = elixir_function,
    ["return"] = function(code)
        return code_utils.stringify_code(code)
    end,
    call_function = function(opts)
        return ("%s(%s)"):format(opts.name, table.concat(opts.args, ", "))
    end,
    terminate = function(code)
        return code
    end,
    pack = function(names)
        return code_utils.returnify(names, "{%s}")
    end,
    unpack = function(names)
        return code_utils.returnify(names, "{%s}")
    end,
    print = function(opts)
        return opts.statement:format(opts.content)
    end,
    default_printf_statement = function()
        return { 'IO.puts("%s")' }
    end,
    default_print_var_statement = function()
        return { 'IO.puts("%s #{inspect(%s)}")' }
    end,
    print_var = function(opts)
        return opts.statement:format(opts.prefix, opts.var)
    end,
}

return elixir
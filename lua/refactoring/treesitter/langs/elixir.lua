local TreeSitter = require("refactoring.treesitter.treesitter")
local Nodes = require("refactoring.treesitter.nodes")
local FieldNode = Nodes.FieldNode
local InlineNode = Nodes.InlineNode

---@class refactor.TreeSitterInstance
local Elixir = {}

function Elixir.new(bufnr, ft)
    ---@type refactor.TreeSitterLanguageConfig
    local config = {
        filetype = ft,
        bufnr = bufnr,
        scope_names = {
            ["function"] = "function",
            private_function = "function",
        },
        block_scope = {
            ["function"] = true,
            private_function = true,
            do_block = true,
        },
        indent_scopes = {
            module = true,
            ["function"] = true,
            private_function = true,
            ["if"] = true,
            case = true,
            cond = true,
            ["for"] = true,
            with = true,
            try = true,
        },
        variable_scope = {
            binary_operator = true,
        },
        local_var_names = {
            InlineNode("(binary_operator left: (identifier) @tmp_capture)"),
            InlineNode("(binary_operator left: (tuple (identifier) @tmp_capture))"),
        },
        local_var_values = {
            InlineNode("(binary_operator right: (_) @tmp_capture)"),
        },
        local_declarations = {
            InlineNode("(binary_operator) @tmp_capture"),
        },
        statements = {
            InlineNode("(call) @tmp_capture"),
            InlineNode("(binary_operator) @tmp_capture"),
            InlineNode("(pipe) @tmp_capture"),
            InlineNode("(if) @tmp_capture"),
            InlineNode("(case) @tmp_capture"),
            InlineNode("(cond) @tmp_capture"),
            InlineNode("(for) @tmp_capture"),
            InlineNode("(with) @tmp_capture"),
            InlineNode("(try) @tmp_capture"),
        },
        function_args = {
            InlineNode("(call target: (identifier) @_def (#match? @_def \"^def[p]?$\") (arguments (_) @tmp_capture))"),
        },
        function_body = {
            InlineNode("(call target: (identifier) @_def (#match? @_def \"^def[p]?$\") (do_block (_) @tmp_capture))"),
        },
        return_statement = {
            InlineNode("(call target: (identifier) @_target (#eq? @_target \"return\")) @tmp_capture"),
        },
        return_values = {
            InlineNode("(call target: (identifier) @_target (#eq? @_target \"return\") (arguments (_) @tmp_capture))"),
        },
        function_references = {
            InlineNode("(call target: (identifier) @tmp_capture)"),
        },
        caller_args = {
            InlineNode("(call (arguments (_) @tmp_capture))"),
        },
        debug_paths = {
            module = FieldNode("name"),
            ["function"] = FieldNode("name"),
            private_function = FieldNode("name"),
        },
        require_class_name = false,
        require_class_type = false,
        require_param_types = false,
        is_return_statement = function(statement)
            return vim.startswith(vim.trim(statement), "return ")
        end,
        should_check_parent_node_print_var = function(node)
            local parent = node:parent()
            if not parent then
                return false
            end
            
            -- Check for pipe operator context
            if parent:type() == "pipe" then
                return true
            end
            
            -- Check for dot notation (module.function calls)
            if parent:type() == "dot" then
                local field_node = parent:field("right")[1]
                if field_node and field_node:equal(node) then
                    return true
                end
            end
            
            return false
        end,
    }
    return TreeSitter:new(config, bufnr)
end

return Elixir
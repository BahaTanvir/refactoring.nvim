local helpers = require("refactoring.tests.utils")

describe("elixir", function()
    local function test_code_generation(test_name, opts, expected)
        it(test_name, function()
            local elixir = require("refactoring.code_generation.langs.elixir")
            local result = elixir[opts.operation](opts)
            assert.are.same(expected, result)
        end)
    end

    describe("code generation", function()
        describe("function generation", function()
            test_code_generation(
                "should generate simple function",
                {
                    operation = "function",
                    name = "add",
                    args = { "a", "b" },
                    body = { "a + b" },
                },
                [[
def add(a, b), do: a + b

]]
            )

            test_code_generation(
                "should generate multi-line function",
                {
                    operation = "function",
                    name = "complex_function",
                    args = { "x", "y" },
                    body = { "result = x * y", "IO.puts(result)", "result" },
                },
                [[
def complex_function(x, y) do
result = x * y
IO.puts(result)
result
end

]]
            )

            test_code_generation(
                "should generate private function",
                {
                    operation = "function",
                    name = "helper",
                    args = { "value" },
                    body = { "value * 2" },
                    scope_type = "defp",
                },
                [[
defp helper(value), do: value * 2

]]
            )
        end)

        describe("constant generation", function()
            test_code_generation("should generate simple constant", {
                operation = "constant",
                name = "result",
                value = "42",
            }, "result = 42\n")

            test_code_generation("should generate multiple constants", {
                operation = "constant",
                multiple = true,
                identifiers = { "x", "y" },
                values = { "1", "2" },
            }, "x, y = 1, 2\n")
        end)

        describe("debug statements", function()
            test_code_generation("should generate print statement", {
                operation = "print",
                statement = 'IO.puts("%s")',
                content = "Hello World",
            }, 'IO.puts("Hello World")')

            test_code_generation("should generate print var statement", {
                operation = "print_var",
                statement = 'IO.puts("%s #{inspect(%s)}")',
                prefix = "Debug:",
                var = "my_var",
            }, 'IO.puts("Debug: #{inspect(my_var)}")')

            it("should provide default printf statement", function()
                local elixir =
                    require("refactoring.code_generation.langs.elixir")
                local result = elixir.default_printf_statement()
                assert.are.same({ 'IO.puts("%s")' }, result)
            end)

            it("should provide default print var statement", function()
                local elixir =
                    require("refactoring.code_generation.langs.elixir")
                local result = elixir.default_print_var_statement()
                assert.are.same({ 'IO.puts("%s #{inspect(%s)}")' }, result)
            end)
        end)

        describe("utility functions", function()
            test_code_generation("should generate function call", {
                operation = "call_function",
                name = "my_function",
                args = { "arg1", "arg2" },
            }, "my_function(arg1, arg2)")

            it("should generate return statement", function()
                local elixir =
                    require("refactoring.code_generation.langs.elixir")
                local result = elixir["return"]("some_value")
                assert.are.same("some_value", result)
            end)

            it("should generate comment", function()
                local elixir =
                    require("refactoring.code_generation.langs.elixir")
                local result = elixir.comment("This is a comment")
                assert.are.same("# This is a comment", result)
            end)

            it("should pack values into tuple", function()
                local elixir =
                    require("refactoring.code_generation.langs.elixir")
                local result = elixir.pack({ "value1", "value2" })
                assert.are.same("{value1, value2}", result)
            end)

            it("should terminate code (no-op for Elixir)", function()
                local elixir =
                    require("refactoring.code_generation.langs.elixir")
                local result = elixir.terminate("some_code")
                assert.are.same("some_code", result)
            end)
        end)
    end)

    describe("treesitter integration", function()
        it("should create elixir treesitter instance", function()
            local elixir_ts = require("refactoring.treesitter.langs.elixir")
            local instance = elixir_ts.new(0, "elixir")
            assert.is_not_nil(instance)
            assert.are.equal("elixir", instance.filetype)
        end)

        it("should have proper scope configuration", function()
            local elixir_ts = require("refactoring.treesitter.langs.elixir")
            local instance = elixir_ts.new(0, "elixir")

            -- Check that function scopes are configured
            assert.is_true(instance.block_scope["function"])
            assert.is_true(instance.block_scope.private_function)
            assert.is_true(instance.block_scope.do_block)

            -- Check scope names
            assert.are.equal("function", instance.scope_names["function"])
            assert.are.equal("function", instance.scope_names.private_function)
        end)
    end)
end)

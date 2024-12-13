local fixtures = require 'spec.fixtures'
local helpers = require 'spec.helpers'

describe('indent', function()
  it(
    'indents after where',
    helpers.clean_buffer([[structure foo where]], function()
      helpers.feed 'Gofoo := 12'
      assert.current_line.is '  foo := 12'
    end)
  )

  it(
    'maintains indentation level for fields',
    helpers.clean_buffer(
      [[
      structure foo where
        foo := 12
    ]],
      function()
        helpers.feed 'Gobar := 37'
        assert.current_line.is '  bar := 37'
      end
    )
  )

  it(
    'aligns with focus dots',
    helpers.clean_buffer(
      [[
      example {n : Nat} : n = n := by
        cases n
        · have : 0 = 0 := rfl
    ]],
      function()
        helpers.feed 'Gorfl'
        assert.current_line.is '    rfl'
      end
    )
  )

  it(
    'indents after by',
    helpers.clean_buffer([[example : 2 = 2 := by]], function()
      helpers.feed 'Gorfl'
      assert.current_line.is '  rfl'
    end)
  )

  it(
    'respects shiftwidth',
    helpers.clean_buffer([[structure foo where]], function()
      vim.bo.shiftwidth = 7
      helpers.feed 'Gofoo := 12'
      assert.current_line.is '       foo := 12'
    end)
  )

  it(
    'does not misindent the structure line itself',
    helpers.clean_buffer([[structure foo where]], function()
      vim.cmd.normal '=='
      assert.current_line.is 'structure foo where'
    end)
  )

  it(
    'dedents after double indented type',
    helpers.clean_buffer([[example :]], function()
      helpers.feed 'o2 = 2 :=<CR>rfl'
      assert.contents.are [[
        example :
            2 = 2 :=
          rfl
      ]]
    end)
  )

  it(
    'indents inside braces',
    helpers.clean_buffer(
      [[
        example : 2 = 2 ∧ 3 = 3 := by
          exact ⟨rfl,
      ]],
      function()
        helpers.feed 'Gorfl⟩'
        assert.current_line.is '    rfl⟩'
      end
    )
  )

  for each in fixtures.indent() do
    it(each.description, function()
      vim.cmd.edit { each.unindented, bang = true }
      vim.cmd.normal 'gg=G'
      assert.are.same(each.expected, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    end)
  end
end)
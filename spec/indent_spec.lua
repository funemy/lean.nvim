local fixtures = require 'spec.fixtures'
local helpers = require 'spec.helpers'

vim.o.debug = 'throw'
vim.o.report = 9999

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
    'dedents after sorry',
    helpers.clean_buffer(
      [[
        example : 37 = 37 ∧ 73 = 73 := by
          sorry
      ]],
      function()
        helpers.feed 'Go#check 37'
        assert.contents.are [[
        example : 37 = 37 ∧ 73 = 73 := by
          sorry
        #check 37
      ]]
      end
    )
  )

  it(
    'dedents after focused sorry',
    helpers.clean_buffer(
      [[
        example : 37 = 37 ∧ 73 = 73 := by
          constructor
          · sorry
      ]],
      function()
        helpers.feed 'Go· sorry'
        assert.contents.are [[
          example : 37 = 37 ∧ 73 = 73 := by
            constructor
            · sorry
            · sorry
      ]]
      end
    )
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
        assert.contents.are [[
          example : 2 = 2 ∧ 3 = 3 := by
            exact ⟨rfl,
              rfl⟩
        ]]
      end
    )
  )

  it(
    'aligns with brackets',
    helpers.clean_buffer(
      [[
        example : 37 = 37 ∧ 73 = 73 := by
          simp [Nat.lt_or_gt,
     ]],
      function()
        helpers.feed 'GoNat.lt_or_gt]'
        assert.contents.are [[
          example : 37 = 37 ∧ 73 = 73 := by
            simp [Nat.lt_or_gt,
                  Nat.lt_or_gt]
        ]]
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

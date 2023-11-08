local Job = require'plenary.job'

local M = {}

local function parse_git_blame(blame_output)
  local authors = {}
  for _, line in ipairs(blame_output) do
    if line:find("^author ") then
      table.insert(authors, line:sub(8))
    end
  end
  return authors
end

function M.show_line_authors()
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  
  Job:new({
    command = 'git',
    args = {'-C', vim.fn.fnamemodify(filename, ':h'), 'blame', '--line-porcelain', filename},
    on_exit = function(j, return_val)
      if return_val == 0 then
        local authors = parse_git_blame(j:result())
        vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
        for linenr, author in ipairs(authors) do
          vim.api.nvim_buf_set_extmark(bufnr, vim.g.my_namespace, linenr - 1, 0, {
            virt_text = {{author, "Comment"}},
            virt_text_pos = 'eol',
          })
        end
      else
        vim.api.nvim_err_writeln('Error running git blame: ' .. table.concat(j:result(), '\n'))
      end
    end,
  }):start()
end

return M


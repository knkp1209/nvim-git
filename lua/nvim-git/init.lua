local Job = require("plenary.job")

local M = {}

-- 解析git blame输出并提取作者和日期信息
local function parse_git_blame(blame_output)
	local info = {}
	local current_item = { author = "", date = "" } -- 初始化当前项
	for _, line in ipairs(blame_output) do
		if line:find("^author ") then
			if current_item.author ~= "" then -- 如果当前项已有作者，先保存
				table.insert(info, current_item)
				current_item = { author = "", date = "" } -- 重新初始化当前项
			end
			current_item.author = line:sub(8)
		elseif line:find("^author%-time%s+") then
			local timestamp = tonumber(line:sub(13))
			if timestamp then -- 确保时间戳不是nil
				current_item.date = os.date("%Y-%m-%d", timestamp)
			end
		end
	end
	if current_item.author ~= "" then
		table.insert(info, current_item) -- 插入最后一个项
	end
	return info
end

-- 显示当前缓冲区的行作者和日期虚拟文本
function M.show_blame()
	-- 确保my_namespace已设置
	if vim.g.my_namespace == nil then
		vim.g.my_namespace = vim.api.nvim_create_namespace("")
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local filename = vim.api.nvim_buf_get_name(bufnr)

	Job:new({
		command = "git",
		args = { "blame", "--line-porcelain", filename },
		cwd = vim.fn.fnamemodify(filename, ":h"),
		on_exit = function(j, return_val)
			local blame_info = parse_git_blame(j:result())
			if return_val == 0 then
				vim.schedule(function()
					vim.api.nvim_buf_clear_namespace(bufnr, vim.g.my_namespace, 0, -1)
					for linenr, info in ipairs(blame_info) do
						if type(linenr) == "number" then
							local text = info.date .. info.author
							vim.api.nvim_buf_set_extmark(bufnr, vim.g.my_namespace, linenr - 1, 0, {
								virt_text = { { text, "Comment" } },
								virt_text_pos = "eol", -- 显示在行尾但不遮挡内容
							})
						end
					end
				end)
			else
				vim.schedule(function()
					vim.api.nvim_err_writeln("Error running git blame: " .. table.concat(j:result(), "\n"))
				end)
			end
		end,
	}):start()
end

-- 取消显示当前缓冲区的行作者虚拟文本
function M.hide_blame()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, vim.g.my_namespace, 0, -1)
end

return M

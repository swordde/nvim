local M = {}

local endpoint = "http://127.0.0.1:8081/v1/chat/completions"

local history = {}

local chat_buf = nil
local chat_win = nil


----------------------------------------------------
-- Open chat window
----------------------------------------------------

local function open_chat()

    if chat_win and vim.api.nvim_win_is_valid(chat_win) then
        vim.api.nvim_set_current_win(chat_win)
        vim.cmd("startinsert")
        return
    end


    chat_buf = vim.api.nvim_create_buf(false, true)


    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)

    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)


    chat_win = vim.api.nvim_open_win(chat_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded",
        title = " Qwen Chat ",
        title_pos = "center",
    })


    vim.bo[chat_buf].bufhidden = "wipe"
    vim.bo[chat_buf].filetype = "markdown"


    vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
        "# Qwen Chat",
        "",
        "Type below and press <Enter>",
        "",
        "You: ",
    })


    vim.api.nvim_win_set_cursor(chat_win, {5, 5})


    ------------------------------------------------
    -- ENTER send message (INSERT MODE)
    ------------------------------------------------

    vim.keymap.set("i", "<CR>", function()

        M.send()

    end, {
        buffer = chat_buf,
        silent = true,
    })


    ------------------------------------------------
    -- Clear chat
    ------------------------------------------------

    vim.keymap.set("n", "<C-l>", function()

        history = {}

        vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
            "# Qwen Chat",
            "",
            "Chat cleared",
            "",
            "You: ",
        })


        vim.api.nvim_win_set_cursor(chat_win, {5, 5})
        vim.cmd("startinsert")

    end, {
        buffer = chat_buf,
    })


    ------------------------------------------------
    -- Quit
    ------------------------------------------------

    vim.keymap.set("n", "q", function()

        vim.api.nvim_win_close(chat_win, true)

    end, {
        buffer = chat_buf,
    })


    vim.cmd("startinsert")

end



----------------------------------------------------
-- Get current prompt
----------------------------------------------------

local function current_prompt()

    local lines = vim.api.nvim_buf_get_lines(
        chat_buf,
        0,
        -1,
        false
    )


    for i = #lines, 1, -1 do

        local line = lines[i]

        if vim.startswith(line, "You: ") then
            return line:gsub("^You:%s*", "")
        end

    end


    return ""

end



----------------------------------------------------
-- Send message
----------------------------------------------------

function M.send()


    local prompt = current_prompt()


    if prompt == "" then
        return
    end


    table.insert(history, {
        role = "user",
        content = prompt,
    })


    local payload = vim.fn.json_encode({

        model = "Qwen2.5-Coder-0.5B-Instruct-Q4_K_M.gguf",

        messages = history,

        temperature = 0.2,

    })


    local result = vim.fn.system({

        "curl",
        "-s",

        endpoint,

        "-H",
        "Content-Type: application/json",

        "-d",
        payload,

    })


    local ok, decoded = pcall(
        vim.fn.json_decode,
        result
    )


    if not ok then

        vim.notify(
            "Model response error:\n" .. result,
            vim.log.levels.ERROR
        )

        return

    end



    local answer = decoded.choices[1].message.content



    table.insert(history, {

        role = "assistant",

        content = answer,

    })



    local lines = vim.api.nvim_buf_get_lines(
        chat_buf,
        0,
        -1,
        false
    )



    table.insert(lines, "")

    table.insert(lines, "Qwen:")

    for _, line in ipairs(vim.split(answer, "\n")) do
        table.insert(lines, line)
    end

    table.insert(lines, "")

    table.insert(lines, "You: ")



    vim.api.nvim_buf_set_lines(
        chat_buf,
        0,
        -1,
        false,
        lines
    )


    vim.api.nvim_win_set_cursor(
        chat_win,
        {
            #lines,
            5
        }
    )


    vim.cmd("startinsert")

end



----------------------------------------------------
-- Open command
----------------------------------------------------

function M.chat()

    open_chat()

end


return M

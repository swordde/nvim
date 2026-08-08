-- Thin HTTP layer built on `curl` + vim.system (Neovim >= 0.10).
-- No external plugin dependencies.
local M = {}

--- Stream an OpenAI-compatible /v1/chat/completions request.
--- opts = {
---   url = string,
---   body = table,           -- request body; "stream = true" is added automatically
---   on_delta = fn(text),    -- called for each incremental chunk (already vim.schedule'd)
---   on_done = fn(full_text),
---   on_error = fn(message),
--- }
--- Returns the vim.system job (has :kill(signal)).
function M.stream_chat(opts)
  local body = vim.deepcopy(opts.body)
  body.stream = true

  local sse_buffer = ""
  local pieces = {}

  local function handle_chunk(data)
    sse_buffer = sse_buffer .. data
    while true do
      local nl = sse_buffer:find("\n")
      if not nl then
        break
      end
      local line = sse_buffer:sub(1, nl - 1):gsub("\r$", "")
      sse_buffer = sse_buffer:sub(nl + 1)

      if line:match("^data:") then
        local payload = line:sub(6):gsub("^%s+", "")
        if payload ~= "" and payload ~= "[DONE]" then
          local ok, decoded = pcall(vim.json.decode, payload)
          if ok and decoded.choices and decoded.choices[1] then
            local delta = decoded.choices[1].delta
           local text = delta and delta.content
if type(text) == "string" and text ~= "" then
	table.insert(pieces, text)
              if opts.on_delta then
                opts.on_delta(text)
              end
            end
          end
        end
      end
    end
  end

  local ok_encode, encoded = pcall(vim.json.encode, body)
  if not ok_encode then
    if opts.on_error then
      opts.on_error("failed to encode request body")
    end
    return nil
  end

  local job = vim.system({
    "curl",
    "-s",
    "-N",
    opts.url,
    "-H",
    "Content-Type: application/json",
    "-d",
    encoded,
  }, {
    stdout = function(_, data)
      if data then
        vim.schedule(function()
          handle_chunk(data)
        end)
      end
    end,
  }, function(res)
    vim.schedule(function()
      if res.code ~= 0 and #pieces == 0 then
        local msg = ("curl exited with code %d - is the server reachable at %s?"):format(res.code, opts.url)
        if res.stderr and res.stderr ~= "" then
          msg = msg .. " (" .. vim.trim(res.stderr) .. ")"
        end
        if opts.on_error then
          opts.on_error(msg)
        end
        return
      end
      if opts.on_done then
        opts.on_done(table.concat(pieces))
      end
    end)
  end)

  return job
end

--- Simple non-streaming JSON POST. callback(decoded_body_or_nil, error_or_nil)
--- Returns the vim.system job (has :kill(signal)).
function M.post_json(url, body, callback)
  local ok_encode, encoded = pcall(vim.json.encode, body)
  if not ok_encode then
    callback(nil, "failed to encode request body")
    return nil
  end

  return vim.system({
    "curl",
    "-s",
    url,
    "-H",
    "Content-Type: application/json",
    "-d",
    encoded,
  }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        callback(nil, ("curl exited with code %d"):format(res.code))
        return
      end
      local ok, decoded = pcall(vim.json.decode, res.stdout or "")
      if not ok then
        callback(nil, "failed to decode JSON response")
        return
      end
      callback(decoded, nil)
    end)
  end)
end

return M

-- ColonyManager-Pro-ME Remote Screen
-- Shows the main computer's request list on a pocket computer, or on a second
-- computer (with or without a monitor). Needs a wireless or ender modem, and so
-- does the main computer running MEWarehouse.lua.
--
-- Install on a pocket computer so it starts on boot:
--   wget https://raw.githubusercontent.com/justinmpowers/ColonyManager-Pro-ME/main/remote.lua startup.lua
--
-- Controls: tap the buttons, scroll with the mouse wheel or arrow keys,
--           R = refresh, C = clear warning, Q = quit

local PROTOCOL = "colonymanager"
local STALE_AFTER = 90  -- seconds without an update before showing "No signal"

local modem = peripheral.find("modem", function(_, m) return m.isWireless() end)
if not modem then
    printError("No wireless or ender modem found.")
    print("Pocket computer: craft it together with a wireless or ender modem.")
    print("Computer: attach a wireless or ender modem.")
    return
end
rednet.open(peripheral.getName(modem))

-- Draw on an attached monitor if there is one, otherwise on this computer's screen
local monitor = peripheral.find("monitor")
local out = monitor or term.current()
if monitor then monitor.setTextScale(0.5) end

local status = nil      -- last status message from the main computer
local server = nil      -- computer ID of the main computer
local receivedAt = 0    -- os.clock() when the last status arrived
local scroll = 0
local buttons = {}
local notice, noticeUntil = nil, 0

local STATUS_STYLE = {
    done = { "[OK]", colors.green },
    partial = { "[>>]", colors.yellow },
    crafting = { "[..]", colors.yellow },
    in_transit = { "[->]", colors.lightBlue },
    waiting_cpu = { "[CP]", colors.magenta },
    failed = { "[XX]", colors.red },
    partial_fail = { "[!>]", colors.orange },
    manual = { "[??]", colors.blue },
}

local function setColors(fg, bg)
    if out.isColor() then
        out.setTextColor(fg or colors.white)
        out.setBackgroundColor(bg or colors.black)
    else
        out.setTextColor(colors.white)
        out.setBackgroundColor(colors.black)
    end
end

local function writeAt(x, y, text, fg, bg)
    out.setCursorPos(x, y)
    setColors(fg, bg)
    out.write(text)
end

local function fit(text, width)
    text = tostring(text or "")
    if width <= 0 then return "" end
    if #text > width then
        return text:sub(1, math.max(1, width - 1)) .. "~"
    end
    return text
end

local function send(command)
    local message = { command = command }
    if server then
        rednet.send(server, message, PROTOCOL)
    else
        rednet.broadcast(message, PROTOCOL)
    end
end

local function showNotice(text)
    notice = text
    noticeUntil = os.clock() + 3
end

-- Turn the status message into a list of display lines
local function buildLines(w)
    local lines = {}
    local function add(text, fg, icon, iconColor, right)
        table.insert(lines, { text = text, fg = fg, icon = icon, iconColor = iconColor, right = right })
    end

    if status.warning and #status.warning > 0 then
        add("! Crafts stuck (" .. #status.warning .. ") - tap Clear", colors.red)
        for _, item in ipairs(status.warning) do
            local name = tostring(item.name or "?"):gsub("^minecraft:", "")
            add("  " .. (item.count or 0) .. "x " .. name, colors.orange)
        end
        add("", colors.white)
    end

    local any = false
    for _, section in ipairs(status.sections or {}) do
        if (section.total or 0) > 0 then
            any = true
            add(section.title .. " (" .. section.total .. ")", colors.white)
            for _, item in ipairs(section.items or {}) do
                local style = STATUS_STYLE[item.status] or { "[  ]", colors.lightGray }
                local who = nil
                if w >= 40 and item.who and item.who ~= "" then who = item.who end
                add((item.provided or 0) .. "/" .. (item.needed or 0) .. " " .. (item.name or "?"),
                    style[2], style[1], style[2], who)
            end
            if section.total > #(section.items or {}) then
                add("  ... and " .. (section.total - #section.items) .. " more", colors.gray)
            end
        end
    end
    if not any then
        add("No open requests", colors.lightGray)
    end
    return lines
end

local function addButton(x, y, label, fg, bg, action)
    if not out.isColor() then label = "[" .. label .. "]" end
    writeAt(x, y, label, fg, bg)
    table.insert(buttons, { x1 = x, x2 = x + #label - 1, y = y, action = action })
    return x + #label + 1
end

local function draw()
    local w, h = out.getSize()
    setColors(colors.white, colors.black)
    out.clear()
    buttons = {}

    -- Header: colony name and game time
    local title = status and status.colony or "ColonyManager"
    local clock = status and textutils.formatTime(status.time, false) or ""
    writeAt(1, 1, fit(title, w - #clock - 1), colors.cyan)
    writeAt(w - #clock + 1, 1, clock, colors.lightGray)

    local bodyTop, bodyBottom = 4, h - 1
    if not status then
        writeAt(1, 3, fit("Waiting for main computer...", w), colors.lightGray)
        writeAt(1, 5, fit("It needs a wireless or", w), colors.gray)
        writeAt(1, 6, fit("ender modem as well.", w), colors.gray)
    else
        -- Line 2: next scan / connection state
        local age = os.clock() - receivedAt
        if age > STALE_AFTER then
            writeAt(1, 2, fit("No signal for " .. math.floor(age) .. "s", w), colors.red)
        elseif status.paused then
            writeAt(1, 2, fit("Paused for the night", w), colors.orange)
        else
            local nextScan = math.max(0, math.ceil((status.nextScan or 0) - age))
            writeAt(1, 2, fit("Next scan: " .. nextScan .. "s", w), colors.yellow)
        end

        -- Line 3: tracking totals, or a short notice after pressing a button
        if notice and os.clock() < noticeUntil then
            writeAt(1, 3, fit(notice, w), colors.lime)
        else
            writeAt(1, 3, fit("Crafting " .. (status.pending or 0) .. "  In transit " .. (status.transit or 0), w), colors.lightGray)
        end

        -- Body
        local lines = buildLines(w)
        local bodyHeight = bodyBottom - bodyTop + 1
        scroll = math.max(0, math.min(scroll, #lines - bodyHeight))
        for i = 1, bodyHeight do
            local line = lines[i + scroll]
            if line then
                local y = bodyTop + i - 1
                local x = 1
                if line.icon then
                    writeAt(1, y, line.icon, line.iconColor)
                    x = #line.icon + 2
                end
                local rightWidth = line.right and (#line.right + 1) or 0
                writeAt(x, y, fit(line.text, w - x + 1 - rightWidth), line.fg)
                if line.right then
                    writeAt(w - #line.right + 1, y, line.right, colors.gray)
                end
            end
        end
    end

    -- Bottom row: buttons
    local x = addButton(1, h, " Refresh ", colors.black, colors.lime, function()
        send("refresh")
        showNotice("Refresh sent")
    end)
    if status and status.warning and #status.warning > 0 then
        addButton(x, h, " Clear ", colors.white, colors.red, function()
            send("clear_warning")
            showNotice("Clear sent")
        end)
    end
    if out.isColor() then
        addButton(w - 6, h, " ^ ", colors.white, colors.gray, function() scroll = scroll - 3 end)
        addButton(w - 2, h, " v ", colors.white, colors.gray, function() scroll = scroll + 3 end)
    end
    setColors(colors.white, colors.black)
end

local function click(x, y)
    for _, button in ipairs(buttons) do
        if y == button.y and x >= button.x1 and x <= button.x2 then
            button.action()
            draw()
            return
        end
    end
end

-- Ask the main computer for its latest results right away
send("status")
local lastRequest = os.clock()
local timer = os.startTimer(1)
draw()

while true do
    local event, a, b, c = os.pullEvent()
    if event == "rednet_message" then
        local sender, message, protocol = a, b, c
        if protocol == PROTOCOL and type(message) == "table" and message.type == "status" then
            status = message
            server = sender
            receivedAt = os.clock()
            draw()
        end
    elseif event == "timer" and a == timer then
        -- Not hearing anything: ask again every 10 seconds
        if (not status or os.clock() - receivedAt > STALE_AFTER) and os.clock() - lastRequest > 10 then
            server = nil
            send("status")
            lastRequest = os.clock()
        end
        draw()
        timer = os.startTimer(1)
    elseif event == "mouse_click" and not monitor then
        click(b, c)
    elseif event == "monitor_touch" and monitor then
        click(b, c)
    elseif event == "mouse_scroll" then
        scroll = scroll + a
        draw()
    elseif event == "key" then
        if a == keys.r then
            send("refresh")
            showNotice("Refresh sent")
            draw()
        elseif a == keys.c then
            send("clear_warning")
            showNotice("Clear sent")
            draw()
        elseif a == keys.up then
            scroll = scroll - 1
            draw()
        elseif a == keys.down then
            scroll = scroll + 1
            draw()
        elseif a == keys.q then
            break
        end
    elseif event == "term_resize" or event == "monitor_resize" then
        draw()
    end
end

setColors(colors.white, colors.black)
out.clear()
out.setCursorPos(1, 1)

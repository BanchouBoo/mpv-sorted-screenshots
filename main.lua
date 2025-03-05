local utils = require 'mp.utils'
local options = require 'mp.options'

local opts = {
    ['nested-directory-mirrors'] = 1
}

local function split_string(input, separator)
    if not separator then return { input } end
    local output = {}
    for match in string.gmatch(input, '([^'.. separator ..']+)') do
        table.insert(output, match)
    end
    return output
end

local function is_local_file(path)
    return path ~= nil and string.find(path, '://') == nil and path ~= '-'
end

local function get_formatted_time(seconds)
    local builder = {}

    local hours = math.floor(seconds / 3600)
    if hours > 0 then
        builder[#builder + 1] = string.format('%02d', hours)
        seconds = seconds - (hours * 3600)
    end

    local minutes = math.floor(seconds / 60)
    if minutes > 0 then
        builder[#builder + 1] = string.format('%02d', minutes)
        seconds = seconds - (minutes * 60)
    end

    local miliseconds = math.floor((1000 * (seconds - math.floor(seconds))) + 0.5)
    seconds = math.floor(seconds)
    builder[#builder + 1] = string.format('%02d.%03d', seconds, miliseconds)

    return table.concat(builder, ':')
end

local function screenshot(...)
    local base_directory = mp.command_native({
        'expand-path',
        mp.get_property_native('screenshot-dir') or ''
    })
    if base_directory == '' then
        mp.osd_message('You must set `screenshot-dir` in your mpv configuration!')
        return
    end

    local path = mp.get_property_native('path')
    if is_local_file(path) then
        local full_path = mp.command_native({'normalize-path', path})

        local split_path = split_string(full_path, '/')
        local parent_count = math.min(#split_path - 1, opts['nested-directory-mirrors'])

        local final_directory_builder = { base_directory }
        for i = #split_path - parent_count, #split_path do
            final_directory_builder[#final_directory_builder + 1] = split_path[i]
        end
        local final_directory = table.concat(final_directory_builder, '/')

        mp.command_native({
            name = 'subprocess',
            args = { 'mkdir', '-p', final_directory }
        })

        local final_file = table.concat({
            get_formatted_time(mp.get_property_native('time-pos')),
            mp.get_property_native('screenshot-format')
        }, '.')
        local final_path = utils.join_path(final_directory, final_file)

        mp.command_native({'screenshot-to-file', final_path, ...})
        mp.osd_message("Screenshot: " .. final_path .. "'")
    else
        local folder
        local is_stdin = path == '-'
        -- NOTE: as I find more exceptions, I may have to refactor this into something
        --       more maintainable
        if path:find('^http://') or path:find('^https://') or is_stdin then
            -- if stdin, attempt to get url from title instead (e.g. streamlink)
            if is_stdin then
                path = mp.get_property_native('media-title')
            end

            -- strip http(s):// and www. and other extraneous elements
            folder = path:gsub('^.*://', ''):gsub('^www%.', '')

            -- normalize youtube links
            folder = folder:gsub('^youtu%.be', 'youtube.com')
            -- special case to get subfolder for video ID
            if folder:find('^youtube.com') then
                folder = folder:gsub('watch%?v=', '')
            end

            -- normalize twitter links
            folder = folder:gsub('^x.com', 'twitter.com')
            -- and for the various embed redirects
            folder = folder:gsub('^girlcockx.com', 'twitter.com')
            folder = folder:gsub('^.*twitter.com', 'twitter.com')

            -- strip other extraneous elements
            folder = folder:gsub('%?.*', ''):gsub('#.*', '')
        end

        -- TODO: finish implementing screenshot behavior, need to consider different naming
        --       behavior for livestreams (esp twitch)
        mp.osd_message(folder)
        folder = nil

        -- failed to come up with a reliable folder name
        if not folder then
            mp.osd_message("No implementation for '" .. path .. "', defaulting to built in screenshot behavior")
            mp.command_native({'screenshot', ...})
        end
    end
end

-- TODO: don't use forced keybindings
mp.add_key_binding(nil, 'sorted-screenshot', screenshot)

local minNameLength = 3
local maxNameLength = 20
local nameFormat = Config.nameFormat
local bannedWords = {"badword1", "badword2"}

local discordWebhookUrl = Config.discordWebhookUrl

RegisterServerEvent('playerConnecting')

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
    local playerName = name
    local isValidName, errorMsg = IsNameValid(playerName)

    if isValidName then
        deferrals.done()
    else
        deferrals.done(errorMsg)
    end
end)

function IsNameValid(name)
    if not string.match(name, nameFormat) then
        return false, 'Your name does not match the required format. Example: [2320] Dave B.'
    end

    local nameLength = string.len(name)
    if nameLength < minNameLength or nameLength > maxNameLength then
        return false, 'Your name must be between ' .. minNameLength .. ' and ' .. maxNameLength .. ' characters long.'
    end
	
    for _, word in ipairs(bannedWords) do
        if string.find(name:lower(), word) then
            return false, 'Your name contains inappropriate language.'
        end
    end
	
    LogValidationAttempt(name, true)

    return true
end

function LogValidationAttempt(name, isValid)
    local currentTime = os.date("%Y-%m-%d %H:%M:%S")
    local result = isValid and "valid" or "invalid"
    local logMessage = currentTime .. " - Name: " .. name .. ", Result: " .. result

    SendToDiscord(name, logMessage, isValid)
end

function SendToDiscord(name, message, isValid)
    local color = isValid and 65280 or 16711680
    local footer = isValid and "Validation Successful" or "Validation Failed"

    local embed = {
        {
            ["color"] = color,
            ["title"] = "**" .. name .. "**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = footer,
            },
        }
    }

    PerformHttpRequest(discordWebhookUrl, function(err, text, headers) end, 'POST', json.encode({username = "Server", embeds = embed}), { ['Content-Type'] = 'application/json' })
end

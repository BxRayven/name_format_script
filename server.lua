local ScriptList = {}
local Changelogs = 0

CreateThread(function()
    CheckForUpdates()
end)

local function formatChangelog(text)
    local formattedChangelog = {}
    for line in string.gmatch(text, "<[^>]+>%s*-%s*([^\n]+)") do
        table.insert(formattedChangelog, "- " .. line)
    end
    return table.concat(formattedChangelog, "\n")
end

local function parseVersion(versionStr)
    local major, minor, patch = versionStr:match("(%d+)%.(%d+)%.(%d+)")
    if not major then
        major, minor = versionStr:match("(%d+)%.(%d+)")
        patch = 0
    end
    return {major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch)}
end

local function compareVersions(v1, v2)
    if v1.major < v2.major then return -1 end
    if v1.major > v2.major then return 1 end
    if v1.minor < v2.minor then return -1 end
    if v1.minor > v2.minor then return 1 end
    if v1.patch < v2.patch then return -1 end
    if v1.patch > v2.patch then return 1 end
    return 0
end

local function getUpdateType(currentVersion, newVersion)
    local versionComparison = compareVersions(currentVersion, newVersion)
    if versionComparison == -1 then
        if currentVersion.major < newVersion.major then
            return "Major"
        elseif currentVersion.minor < newVersion.minor then
            return "Minor"
        else
            return "Patch"
        end
    end
    return nil
end

local function Changelog()
    print('')
    for i, v in pairs(ScriptList) do
        if v.Version ~= v.NewestVersion then
            if v.CL then
                print('^3'..v.Resource:upper()..' - Changelog:')
                print('^4'..v.Changelog)
                print('')
            end
        end
    end
    print('^0--------------------------------------------------------------------')
end

local function UpdateChecker(resource)
    if resource and GetResourceState(resource) == 'started' then
        if GetResourceMetadata(resource, 'fivem_checker', 0) == 'yes' then
            local Name = GetResourceMetadata(resource, 'name', 0)
            local Github = GetResourceMetadata(resource, 'github', 0)
            local Version = GetResourceMetadata(resource, 'version', 0)
            local Changelog, GithubL, NewestVersion

            Script = {}

            Script['Resource'] = resource
            if Version == nil then
                Version = GetResourceMetadata(resource, 'version', 0)
            end
            if Name ~= nil then
                Script['Name'] = Name
            else
                resource = resource:upper()
                Script['Name'] = '^6'..resource
            end
            if string.find(Github, "github") then
                if string.find(Github, "github.com") then
                    Script['Github'] = Github
                    Github = string.gsub(Github, "github", "raw.githubusercontent")..'/master/version'
                else
                    GithubL = string.gsub(Github, "raw.githubusercontent", "github"):gsub("/master", "")
                    Github = Github..'/version'
                    Script['Github'] = GithubL
                end
            else
                Script['Github'] = Github..'/version'
            end
            PerformHttpRequest(Github, function(Error, V, Header)
                NewestVersion = V
            end)
            repeat
                Wait(10)
            until NewestVersion ~= nil
            local _, strings = string.gsub(NewestVersion, "\n", "\n")
            Version1 = NewestVersion:match("[^\n]*"):gsub("[<>]", "")
            if not string.find(Version1, Version) then
                if strings > 0 then
                    Changelog = NewestVersion:gsub(Version1, ""):match("<.*" .. Version .. ">"):gsub(Version, "")
                    Changelog = formatChangelog(Changelog)
                    NewestVersion = Version1
                end
            end

            if Changelog ~= nil then
                Script['CL'] = true
            end

            local currentVersion = parseVersion(Version)
            local newVersion = parseVersion(Version1)
            Script['UpdateType'] = getUpdateType(currentVersion, newVersion)
            Script['NewestVersion'] = Version1
            Script['Version'] = Version
            Script['Changelog'] = Changelog
            table.insert(ScriptList, Script)
        end
    end
end

local function Checker()
    print('^0--------------------------------------------------------------------')
    print("^3FiveM Checker - Automatically check update of compatible resources")
    print('')
    for i, v in pairs(ScriptList) do
        if string.find(v.NewestVersion, v.Version) then
            print('^4'..v.Name..' ('..v.Resource..') ^2✓ ' .. 'Up to date - Version ' .. v.Version..'^0')
        else
            print('^4'..v.Name..' ('..v.Resource..') ^1✗ ' .. 'Outdated (v'..v.Version..') ^5- Update found: Version ' .. v.NewestVersion .. ' ^3(' .. v.UpdateType .. ') ^0('..v.Github..')')
        end

        if v.CL then
            Changelogs = Changelogs + 1
        end
    end

    if Changelogs > 0 then
        print('^0----------------------------------')
        Changelog()
    else
        print('^0--------------------------------------------------------------------')
    end
end

function CheckForUpdates()
    local Resources = GetNumResources()

    ScriptList = {}
    Changelogs = 0

    for i=0, Resources, 1 do
        local resource = GetResourceByFindIndex(i)
        UpdateChecker(resource)
    end

    if next(ScriptList) ~= nil then
        Checker()
    end
end

RegisterCommand('checkupdate', function(source) if source == 0 then CheckForUpdates() end end, false)

local minNameLength = 3
local maxNameLength = 20
local nameFormat = "%[%d+%]%s[A-Za-z]+%s[A-Za-z]+"
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

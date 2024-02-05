RegisterServerEvent('playerConnecting')

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
    local playerName = name
    local isValidName = IsNameValid(playerName)

    if isValidName then
        deferrals.done()
    else
        deferrals.done('Your name does not match the required format. here is an example [2320] Dave B.')
    end
end)

function IsNameValid(name)
    return string.match(name, "%[%d+%]%s[A-Za-z]+%s[A-Za-z]") ~= nil
end
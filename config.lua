Config = {}

-- Discord Webhook URL
Config.discordWebhookUrl = "YOUR_DISCORD_WEBHOOK_URL"

-- Minimum and maximum name length
Config.minNameLength = 3
Config.maxNameLength = 20

-- Name format
-- Example formats: "%[%d+%]%s[A-Za-z]+%s[A-Za-z]+", "%d+[A-Za-z]-%d+|%s[A-Za-z]+%s[A-Za-z]+"
Config.nameFormat = "%[%d+%]%s[A-Za-z]+%s[A-Za-z]+"

Config.bannedWords = {"badword1", "badword2"}


-- Name Format Example 

-- %d+: Represents one or more digits.
-- [A-Za-z]-: Represents a single letter (either uppercase or lowercase) followed by a hyphen.
-- %s: Represents one whitespace character.
-- [A-Za-z]+: Represents one or more letters (either uppercase or lowercase).
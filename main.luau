-- Rive layout entry point; game logic is shared with the regression tests.
local Game = require('game')

return function(context: Context): Layout<Game.Main>
    return Game.create(context)
end

-- Entry point for Love2D 11.5.
-- This file intentionally keeps only bootstrap code.

local App = {}

App.state = {
    initialized = false,
}

function App:load()
    self.state.initialized = true
end

function App:update(_dt)
    -- Systems update pipeline will be wired here.
end

function App:draw()
    love.graphics.clear(0.08, 0.08, 0.1, 1.0)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("ChainReaction - Love2D 11.5 project scaffold", 16, 16)
    love.graphics.print("No gameplay implemented yet.", 16, 40)
end

function App:keypressed(_key)
    -- Input routing will be handled through systems.
end

function love.load()
    App:load()
end

function love.update(dt)
    App:update(dt)
end

function love.draw()
    App:draw()
end

function love.keypressed(key)
    App:keypressed(key)
end

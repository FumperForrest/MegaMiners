-- Required Libraries
require("sprites")
require("map")
require("particles")
require("items")

-- Global Variables
local camera = require 'libraries/camera'
local cam
local camSpeed = 350
local miningSrc, breakSrc, musicSrc
local spriteToBlock = 50/32
local chestOpen = nil
local fullscreenX, fullscreenY
local particleTriggered = false
local particleX, particleY = 0, 0
local pickaxes = {}
local pick
local cx, cy, cw, ch
local exitButtonSize = 16
local chestMenuScale = 3 
local chestMenuX, chestMenuY
local canMine = true
local currentPickSprite
local pickAnimTimer = 0
local pickSwinging = false
local loadedChunks = {}
local renderDistance = 1000
local inventory = {}

-- Load Function
function love.load()
  cam = camera()
  love.graphics.setDefaultFilter('nearest','nearest')

  miningSrc = love.audio.newSource('Assets/mining.wav', 'stream')
  breakSrc = love.audio.newSource('Assets/break.wav', 'stream')
  musicSrc = love.audio.newSource('Assets/music.mp3','stream')
  musicSrc:setLooping(true)
  musicSrc:setVolume(0.1)
  musicSrc:play()

  local oreShaderCode = [[
    extern number time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        float glow = sin(time * 3.0) * 0.5 + 0.5; // Adjust frequency to 2.0 for slower animation
        if (pixel.r > 0.5 && pixel.b > 0.5 && pixel.g < 0.5) {
            pixel.rgb += glow * vec3(0.5, 0.0, 0.5); // Amethyst glow
        } else if (pixel.g > 0.5 && pixel.b < 0.5 && pixel.r < 0.5) {
            pixel.rgb += glow * vec3(0.0, 1.0, 0.0); // Forrestite glow
        }
        return pixel * color;
    }
  ]]
  
  local vignetteShaderCode = [[
    extern number time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);

        vec2 center = vec2(0.5, 0.5);
        float dist = distance(texture_coords, center);

        float vignette = smoothstep(0.3, 0.8, dist);

        float mist = sin(time * 1.5 + texture_coords.x * 10.0) * 0.1;
        mist += cos(time * 1.2 + texture_coords.y * 12.0) * 0.1;

        vignette = clamp(vignette + mist, 0.0, 1.0);

        pixel.rgb *= mix(vec3(1.0), vec3(0.5), vignette);

        return pixel;
    }
]]

  vignetteShader = love.graphics.newShader(vignetteShaderCode)
  oreShader = love.graphics.newShader(oreShaderCode)
  screenshot = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())

  fullscreenX = love.graphics.getWidth() - 16
  fullscreenY = 0

  initializePickaxes()
  initializeChestMenu()
  initializeInventory(6)
  generateMap(50, 50)
end

function love.resize(w, h)
  screenshot = love.graphics.newCanvas(w, h)
end

-- Initialize Pickaxes
function initializePickaxes()
  flintPick = { idle = flintPickIdle, swing = flintPickSwing, final = flintPickFinal, damage = 1 }
  ironPick = { idle = ironPickIdle, swing = ironPickSwing, final = ironPickFinal, damage = 2.5 }
  goldPick = { idle = goldPickIdle, swing = goldPickSwing, final = goldPickFinal, damage = 5 }
  diamondPick = { idle = diamondPickIdle, swing = diamondPickSwing, final = diamondPickFinal, damage = 7.5 }
  amethystPick = { idle = amethystPickIdle, swing = amethystPickSwing, final = amethystPickFinal, damage = 10 }
  forrestitePick = { idle = forrestitePickIdle, swing = forrestitePickSwing, final = forrestitePickFinal, damage = 15 }
  
  pick = { type = flintPick, x = 100, y = 100 }
  currentPickSprite = pick.type.idle
end

-- Initialize Chest Menu
function initializeChestMenu()
  cx, cy, cw, ch = chestMenu:getViewport()
  chestMenuX = (love.graphics.getWidth() / 2) - ((cw * chestMenuScale) / 2)
  chestMenuY = (love.graphics.getHeight() / 2) - ((ch * chestMenuScale) / 2)
end

-- Initialize Inventory
function initializeInventory(number)
  for i = 1, number do
    local slot = { item = nil, amount = 0 }
    table.insert(inventory, slot)
  end
end

-- Draw Functions
function love.preDraw()
  screenshot = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setCanvas(screenshot)
  love.graphics.clear()
end

function love.draw()
  -- Draw the entire scene to the canvas
  love.graphics.setCanvas(screenshot)
  love.graphics.clear()

  cam:attach()
  drawMap()
  drawParticles()
  cam:detach()

  love.graphics.setCanvas() -- Back to main screen

  -- Apply shader effect
  love.graphics.setShader(vignetteShader)
  love.graphics.draw(screenshot)
  love.graphics.setShader() -- Turn off the shader

  -- HUD/Overlay elements drawn after shader
  drawBorderedText(love.timer.getFPS(), 0, 0)
  drawPick(pick.x, pick.y)
  drawInventory()

  if chestOpen ~= nil then
      drawChest(chestOpen)
  end
end

function love.postDraw()
  love.graphics.setCanvas()
end

function drawMap()
  for chunkIndex, chunk in ipairs(chunks) do
      local camX, camY = cam:position()
      if math.abs(chunk.x - camX) < renderDistance and math.abs(chunk.y - camY) < renderDistance then
          table.insert(loadedChunks, chunk)
      else
          table.remove(loadedChunks, chunkIndex)
      end
  end

  for chunkIndex, chunk in ipairs(loadedChunks) do
      for blockIndex, block in ipairs(chunk.blocks) do
          if block.blockType then
              if block.blockType == amethyst or block.blockType == forrestite then
                  love.graphics.setShader(oreShader)
              end
              love.graphics.draw(spriteSheet, block.blockType.sprite, block.x, block.y, 0, spriteToBlock, spriteToBlock)
              if block.blockType == amethyst or block.blockType == forrestite then
                  love.graphics.setShader()
              end
              drawBlockDamage(block)
          end
      end
  end
end

function drawPick(x, y)
  if pick.type == amethystPick or pick.type == forrestitePick then
      love.graphics.setShader(oreShader)
  end
  love.graphics.draw(spriteSheet, currentPickSprite, x - 15, y - 15)
  if pick.type == amethystPick or pick.type == forrestitePick then
      love.graphics.setShader()
  end
end

function drawBlockDamage(block)
  if block.blockType.type == 'mineable' then
    if block.health < (9.9/10) * block.blockType.durability and block.health >= (6.5/10) * block.blockType.durability then
      love.graphics.draw(spriteSheet, break1, block.x, block.y, 0, spriteToBlock, spriteToBlock)
    elseif block.health < (6.5/10) * block.blockType.durability and block.health >= (3/10) * block.blockType.durability then
      love.graphics.draw(spriteSheet, break2, block.x, block.y, 0, spriteToBlock, spriteToBlock)
    elseif block.health < (3/10) * block.blockType.durability and block.health >= 0 then
      love.graphics.draw(spriteSheet, break3, block.x, block.y, 0, spriteToBlock, spriteToBlock)
    end
  end
end

function drawParticles()
  love.graphics.draw(rockParticleSystem)
  love.graphics.draw(ironParticleSystem)
  love.graphics.draw(goldParticleSystem)
  love.graphics.draw(diamondParticleSystem)
  love.graphics.draw(amethystParticleSystem)
  love.graphics.draw(forrestiteParticleSystem)
end

function drawInventory()
  local slotMargin = 5
  local slotSize = 40
  local inventoryScale = 2 -- Adjust this scale as needed

  for slotIndex, slot in ipairs(inventory) do
    local slotX = slotIndex * slotSize - slotSize + slotMargin * slotIndex
    local slotY = love.graphics.getHeight() - slotSize - slotMargin

    love.graphics.setColor(0.7, 0.5, 0.3)
    love.graphics.rectangle('fill', slotX, slotY, slotSize, slotSize)

    if slot.item then
      love.graphics.setColor(1, 1, 1)
      local quad = slot.item.sprite
      local _, _, quadWidth, quadHeight = quad:getViewport()
      local itemWidth = quadWidth * inventoryScale
      local itemHeight = quadHeight * inventoryScale
      local itemX = slotX + (slotSize - itemWidth) / 2
      local itemY = slotY + (slotSize - itemHeight) / 2
      love.graphics.draw(spriteSheet, quad, itemX, itemY, 0, inventoryScale, inventoryScale)
    end

    love.graphics.setColor(0.5, 0.3, 0.1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line', slotX, slotY, slotSize, slotSize)
    drawBorderedText(slot.amount, slotX, slotY)
  end
end

function drawChest(chest)
  local itemMargin = 11 * chestMenuScale
  local itemSpacing = 31 * chestMenuScale
  local chestColumns = 7
  local chestRows = 4

  love.graphics.draw(spriteSheet, chestMenu, chestMenuX, chestMenuY, 0, chestMenuScale, chestMenuScale)
  love.graphics.draw(spriteSheet, exitIcon, chestMenuX - exitButtonSize, chestMenuY - exitButtonSize, 0, chestMenuScale, chestMenuScale)

  if not chest then
    print("Error: chest is nil")
    return
  end

  for itemIndex, item in ipairs(chest.items) do
    item.x = chestMenuX + itemIndex * itemMargin
    
    local row = 1

    if 0 < itemIndex and itemIndex <= 7 then
      item.x = chestMenuX + itemMargin + ((itemIndex - 1) * itemSpacing)
      row = 0
    elseif 7 < itemIndex and itemIndex <= 14 then
      item.x = chestMenuX + ((itemIndex - 1) - 7) * itemSpacing + itemMargin
      row = 1
    elseif 14 < itemIndex and itemIndex <= 21 then
      item.x = chestMenuX + ((itemIndex - 1) - 14) * itemSpacing + itemMargin
      row = 2
    elseif 21 < itemIndex and itemIndex <= 28 then
      item.x = chestMenuX + ((itemIndex - 1) - 21) * itemSpacing + itemMargin
      row = 2
    end

    rowY = row * itemSpacing + itemMargin
    item.y = row * itemSpacing + itemMargin + chestMenuY
    
    love.graphics.draw(spriteSheet, item.itemType.sprite, item.x, item.y, 0, chestMenuScale, chestMenuScale)
    drawBorderedText(item.amount, item.x, chestMenuY + rowY)
  end
end

function drawBorderedText(text, x, y)
  love.graphics.setColor(0, 0, 0)
  love.graphics.print(text, x, y + 1)
  love.graphics.print(text, x + 1, y)
  love.graphics.print(text, x + 2, y + 1)
  love.graphics.print(text, x + 1, y + 2)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(text, x + 1, y + 1)
end

-- Update Function
function love.update(dt)
  oreShader:send("time", love.timer.getTime())
  vignetteShader:send("time", love.timer.getTime()) -- Add this
  updateParticles(dt)
  updatePick(dt)
  updateCamera(dt)
end

function updateParticles(dt)
  rockParticleSystem:update(dt)
  ironParticleSystem:update(dt)
  goldParticleSystem:update(dt)
  diamondParticleSystem:update(dt)
  amethystParticleSystem:update(dt)
  forrestiteParticleSystem:update(dt)
end

function updatePick(dt)
  pick.x, pick.y = love.mouse.getX(), love.mouse.getY()
  local worldPickX, worldPickY = cam:worldCoords(pick.x, pick.y)

  if love.mouse.isDown(1) then
    if not pickSwinging and canMine then
      pickSwinging = true
      particleTriggered = false

      for chunkIndex, chunk in ipairs(loadedChunks) do
        for blockIndex, block in ipairs(chunk.blocks) do
          if block.blockType then
            if checkCollision(block.x, block.y, worldPickX, worldPickY, blockWidth, blockHeight) and block.blockType.type == 'mineable' then
              if not particleTriggered then
                particleX, particleY = block.x + blockWidth / 2, block.y + blockHeight / 2
                rockParticleSystem:setPosition(particleX, particleY)
                rockParticleSystem:emit(1)
                particleTriggered = true
              end

              if not block.health then
                block.health = block.blockType.durability
              end

              if block.health <= 0 then
                breakBlock(block, blockIndex, chunk)
              else
                block.health = block.health - pick.type.damage
                miningSrc:play()
              end
            end
          end
        end
      end
    end
  end

  if pickSwinging then
    pickAnimTimer = pickAnimTimer + dt * 200
    if pickAnimTimer <= 20 then
      currentPickSprite = pick.type.idle
    elseif pickAnimTimer <= 40 then
      currentPickSprite = pick.type.swing
    elseif pickAnimTimer <= 60 then
      currentPickSprite = pick.type.final
    else
      pickSwinging = false
      pickAnimTimer = 0
      currentPickSprite = pick.type.idle
    end
  end
end

function updateMenu(dt)
  --the items need to move with the mouse while it is down and only come off when over and empty or fitting item slot in the inventory. If it is unclicked, it should return to the chest.
end   
function updateCamera(dt)
  local moveX, moveY = 0, 0
  if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
    moveX = moveX + camSpeed * dt
  end
  if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
    moveX = moveX - camSpeed * dt
  end
  if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
    moveY = moveY + camSpeed * dt
  end
  if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
    moveY = moveY - camSpeed * dt
  end
  cam:move(moveX, moveY)
end

-- Input Functions
function love.mousepressed(mx, my, button)
  if button == 1 then
    if checkCollision(fullscreenX, fullscreenY, mx, my, 16, 16) then
      toggleFullscreen()
    elseif checkCollision(chestMenuX, chestMenuY, mx, my, 16 * chestMenuScale, 16 * chestMenuScale) then
      if chestOpen then
        chestOpen = nil
        canMine = true
      end
    end
  elseif button == 2 then
    for chunkIndex, chunk in ipairs(loadedChunks) do
      for blockIndex, block in ipairs(chunk.blocks) do
        if block.blockType == chest then
          local camBlockX, camBlockY = cam:cameraCoords(block.x, block.y)

          if checkCollision(camBlockX, camBlockY, mx, my, 32, 32) then
            chestOpen = block
            canMine = false
          end
        end
      end
    end
  end
end

function love.keypressed(key)
  if not pickSwinging then
    if key == '1' then
      pick.type = flintPick
    elseif key == '2' then
      pick.type = ironPick
    elseif key == '3' then
      pick.type = goldPick
    elseif key == '4' then
      pick.type = diamondPick
    elseif key == '5' then
      pick.type = amethystPick
    elseif key == '6' then
      pick.type = forrestitePick
    end
    currentPickSprite = pick.type.idle
  end
end

-- Utility Functions
function checkCollision(x, y, pickX, pickY, width, height)
  return pickX >= x and pickX <= x + width and pickY >= y and pickY <= y + height
end

function toggleFullscreen()
  if love.window.getFullscreen() then
    love.window.setFullscreen(false)
  else
    love.window.setFullscreen(true, 'exclusive')
  end
end

function breakBlock(block, blockIndex, chunk)
  table.remove(chunk.blocks, blockIndex)
  breakSrc:play()
  miningSrc:stop()
  rockParticleSystem:setPosition(particleX, particleY)
  rockParticleSystem:emit(5)

  if block.blockType == iron then
    ironParticleSystem:setPosition(particleX, particleY)
    ironParticleSystem:emit(3)
  elseif block.blockType == gold then
    goldParticleSystem:setPosition(particleX, particleY)
    goldParticleSystem:emit(3)
  elseif block.blockType == diamonds then
    diamondParticleSystem:setPosition(particleX, particleY)
    diamondParticleSystem:emit(3)
  elseif block.blockType == amethyst then
    amethystParticleSystem:setPosition(particleX, particleY)
    amethystParticleSystem:emit(3)
  elseif block.blockType == forrestite then
    forrestiteParticleSystem:setPosition(particleX, particleY)
    forrestiteParticleSystem:emit(3)
  end

  local slotFilled = false
  for slotIndex, slot in ipairs(inventory) do
    if not slotFilled then
      if slot.item == block.blockType.item then
        slotFilled = true
        slot.amount = slot.amount + 1
      elseif slot.item == nil then
        slotFilled = true
        slot.item = block.blockType.item
        slot.amount = slot.amount + 1
      end
    end
  end
end
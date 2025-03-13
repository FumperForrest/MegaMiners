require("sprites")
require("map")
require("particles")

function love.load()
  camera = require 'libraries/camera'
  cam = camera()
  
  camSpeed = 500
  
  love.graphics.setDefaultFilter('nearest','nearest')

  miningSrc = love.audio.newSource('Assets/mining.wav', 'stream')
  breakSrc = love.audio.newSource('Assets/break.wav', 'stream')

  musicSrc = love.audio.newSource('Assets/music.mp3','stream')
  musicSrc.setLooping(musicSrc, true)
  musicSrc.setVolume(musicSrc, .1)
  musicSrc:play()
  
  spriteToBlock = 50/32
  
  fullscreenX = love.graphics.getWidth()-16
  fullscreenY = 0
  
  particleTriggered = false
  
  particleX, particleY = 0,0
  
  pickaxes = {}
  
  flintPick = { idle = flintPickIdle, swing = flintPickSwing, final = flintPickFinal, damage = 1 }
  ironPick = { idle = ironPickIdle, swing = ironPickSwing, final = ironPickFinal, damage = 2.5 }
  goldPick = { idle = goldPickIdle, swing = goldPickSwing, final = goldPickFinal, damage = 5 }
  diamondPick = { idle = diamondPickIdle, swing = diamondPickSwing, final = diamondPickFinal, damage = 7.5 }
  
  pick = { type = flintPick, x = 100, y = 100 }

  currentPickSprite = pick.type.idle
  pickAnimTimer = 0
  
  pickSwinging = false

  loadedChunks = {}

  renderDistance = 1000
  
  --inventory
  inventory = {}
  
  makeSlots(5)
  
  generateMap(50,50)
end

function makeSlots(number)
  for i = 1, number do
    local slot = {
      item = nil,
      amount = 0,
    }
    
    table.insert(inventory, slot)
  end
end

function drawPick(x,y)
  love.graphics.draw(spriteSheet,currentPickSprite,x-15,y-15)
end

function drawInventory()
  local slotMargin = 5
  
  local slotSize = 40
  local itemSize = 30
  
  for slotIndex, slot in ipairs(inventory) do
    local slotX = slotIndex * slotSize - slotSize + slotMargin*slotIndex
    local slotY = love.graphics.getHeight() - slotSize - slotMargin
    
    --light brown
    love.graphics.setColor(.7,.5,.3)
    love.graphics.rectangle('fill', slotX, slotY, slotSize, slotSize)
    
    --draw item
    if slot.item then
      love.graphics.setColor(1, 1, 1)
    
      -- Calculate item position to center it
      local itemX = slotX + (slotSize - itemSize) / 2
      local itemY = slotY + (slotSize - itemSize) / 2
      
      love.graphics.draw(spriteSheet, slot.item.sprite, itemX, itemY, 0, itemSize / 32, itemSize / 32)
    end
    
    --slot border
    love.graphics.setColor(.5,.3,.1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line', slotIndex * slotSize - slotSize + slotMargin*slotIndex, love.graphics.getHeight() - slotSize - slotMargin, slotSize, slotSize)
    
    --draw count
    drawBorderedText(slot.amount, slotIndex * slotSize - slotSize + slotMargin*slotIndex, love.graphics.getHeight() - slotSize - slotMargin)
  end
end

function checkCollision(x, y, pickX, pickY, width, height)
  return pickX >= x
  and pickX <= x + width
  and pickY >= y
  and pickY <= y + height
end

function drawBorderedText(text, x, y)
  love.graphics.setColor(0,0,0)
  love.graphics.print(text, x,y+1)
  love.graphics.print(text, x+1,y)
  love.graphics.print(text, x+2,y+1)
  love.graphics.print(text, x+1,y+2)
  love.graphics.setColor(1,1,1)
  love.graphics.print(text, x+1,y+1)
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
  elseif  block.blockType == diamonds then
    diamondParticleSystem:setPosition(particleX, particleY)
    diamondParticleSystem:emit(3)
  end
        
  local slotFilled = false
  
  for slotIndex, slot in ipairs(inventory) do
    if slotFilled == false then
      if slot.item == block.blockType then
        slotFilled = true
        slot.amount = slot.amount + 1
        slot.item = block.blockType
      elseif slot.item == nil then
        slotFilled = true
        slot.item = block.blockType
        slot.amount = slot.amount + 1
      end
    end
  end
end

function love.mousepressed(mx,my,button)
  if button == 1 then
    if checkCollision(fullscreenX, fullscreenY, mx, my, 16, 16) then
      if love.window.getFullscreen() then
        love.window.setFullscreen(false)
      else
        love.window.setFullscreen(true, 'exclusive')
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
    end

    currentPickSprite = pick.type.idle
  end
end

function love.update(dt)
  rockParticleSystem:update(dt)
  ironParticleSystem:update(dt)
  goldParticleSystem:update(dt)
  diamondParticleSystem:update(dt)
  
  pick.x, pick.y = love.mouse.getX(), love.mouse.getY()
  
  local worldPickX, worldPickY = cam:worldCoords(pick.x, pick.y)
  
  if love.mouse.isDown(1) then
    if not pickSwinging then
      pickSwinging = true
      particleTriggered = false  -- Reset the flag when a new swing starts

      for chunkIndex, chunk in ipairs(loadedChunks) do
        for blockIndex, block in ipairs(chunk.blocks) do
          if block.blockType then
            if checkCollision(block.x, block.y, worldPickX, worldPickY, blockWidth, blockHeight) then
              if not particleTriggered then
                particleX, particleY = block.x + blockWidth / 2, block.y + blockHeight / 2
                rockParticleSystem:setPosition(particleX, particleY)
                rockParticleSystem:emit(1)

                particleTriggered = true  -- Ensures particles emit only once per swing
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

function love.draw()
  cam:attach()
    --Draw map
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
        if block.blockType then  -- Prevent errors if blockType is nil
          love.graphics.draw(spriteSheet, block.blockType.sprite, block.x, block.y, 0, spriteToBlock, spriteToBlock)

          if block.health < (9.9/10)*block.blockType.durability and block.health >= (6.5/10)*block.blockType.durability then
            love.graphics.draw(spriteSheet, break1, block.x, block.y, 0, spriteToBlock, spriteToBlock)
          elseif block.health < (6.5/10)*block.blockType.durability and block.health >= (3/10)*block.blockType.durability then
            love.graphics.draw(spriteSheet, break2, block.x, block.y, 0, spriteToBlock, spriteToBlock)
          elseif block.health < (3/10)*block.blockType.durability and block.health >= 0 then
            love.graphics.draw(spriteSheet, break3, block.x, block.y, 0, spriteToBlock, spriteToBlock)
          end
        end
      end
    end
    
    particleX = pick.x
    particleY = pick.y
    
    love.graphics.draw(rockParticleSystem)
    love.graphics.draw(ironParticleSystem)
    love.graphics.draw(goldParticleSystem)
    love.graphics.draw(diamondParticleSystem)
  cam:detach()

  love.graphics.draw(spriteSheet, fullscreenIcon, fullscreenX, fullscreenY)
  drawBorderedText(love.timer.getFPS(), 0,0)
  drawPick(pick.x, pick.y)
  drawInventory()
end
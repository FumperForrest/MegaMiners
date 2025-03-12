love.graphics.setDefaultFilter('nearest','nearest')

spriteSheet = love.graphics.newImage('Assets/spriteSheet.png')
  
flintPickIdle = love.graphics.newQuad(0,0,32,32,spriteSheet:getDimensions())
flintPickSwing = love.graphics.newQuad(32,0,32,32,spriteSheet:getDimensions())
flintPickFinal = love.graphics.newQuad(64,0,32,32,spriteSheet:getDimensions())

stonePickIdle = love.graphics.newQuad(96,0,32,32,spriteSheet:getDimensions())
stonePickSwing = love.graphics.newQuad(128,0,32,32,spriteSheet:getDimensions())
stonePickFinal = love.graphics.newQuad(160,0,32,32,spriteSheet:getDimensions())

goldPickIdle = love.graphics.newQuad(192,0,32,32,spriteSheet:getDimensions())
goldPickSwing = love.graphics.newQuad(224,0,32,32,spriteSheet:getDimensions())
goldPickFinal = love.graphics.newQuad(256,0,32,32,spriteSheet:getDimensions())

diamondPickIdle = love.graphics.newQuad(288,0,32,32,spriteSheet:getDimensions())
diamondPickSwing = love.graphics.newQuad(320,0,32,32,spriteSheet:getDimensions())
diamondPickFinal = love.graphics.newQuad(352,0,32,32,spriteSheet:getDimensions())

break1 = love.graphics.newQuad(0,32,32,32,spriteSheet:getDimensions())
break2 = love.graphics.newQuad(32,32,32,32,spriteSheet:getDimensions())
break3 = love.graphics.newQuad(64,32,32,32,spriteSheet:getDimensions())

stone = love.graphics.newQuad(0,64,32,32,spriteSheet:getDimensions())
iron = love.graphics.newQuad(32,64,32,32,spriteSheet:getDimensions())
gold = love.graphics.newQuad(64,64,32,32,spriteSheet:getDimensions())
diamonds = love.graphics.newQuad(96,64,32,32,spriteSheet:getDimensions())

rockParticle = love.graphics.newQuad(0,96,16,16,spriteSheet:getDimensions())

fullscreenIcon = love.graphics.newQuad(0,112,16,16,spriteSheet:getDimensions())
love.graphics.setDefaultFilter('nearest','nearest')

spriteSheet = love.graphics.newImage('Assets/spriteSheet.png')
  
flintPickIdle = love.graphics.newQuad(0,0,32,32,spriteSheet:getDimensions())
flintPickSwing = love.graphics.newQuad(32,0,32,32,spriteSheet:getDimensions())
flintPickFinal = love.graphics.newQuad(64,0,32,32,spriteSheet:getDimensions())

ironPickIdle = love.graphics.newQuad(96,0,32,32,spriteSheet:getDimensions())
ironPickSwing = love.graphics.newQuad(128,0,32,32,spriteSheet:getDimensions())
ironPickFinal = love.graphics.newQuad(160,0,32,32,spriteSheet:getDimensions())

goldPickIdle = love.graphics.newQuad(192,0,32,32,spriteSheet:getDimensions())
goldPickSwing = love.graphics.newQuad(224,0,32,32,spriteSheet:getDimensions())
goldPickFinal = love.graphics.newQuad(256,0,32,32,spriteSheet:getDimensions())

diamondPickIdle = love.graphics.newQuad(288,0,32,32,spriteSheet:getDimensions())
diamondPickSwing = love.graphics.newQuad(320,0,32,32,spriteSheet:getDimensions())
diamondPickFinal = love.graphics.newQuad(352,0,32,32,spriteSheet:getDimensions())

amethystPickIdle = love.graphics.newQuad(96,32,32,32,spriteSheet:getDimensions())
amethystPickSwing = love.graphics.newQuad(128,32,32,32,spriteSheet:getDimensions())
amethystPickFinal = love.graphics.newQuad(160,32,32,32,spriteSheet:getDimensions())

forrestitePickIdle = love.graphics.newQuad(192,32,32,32,spriteSheet:getDimensions())
forrestitePickSwing = love.graphics.newQuad(224,32,32,32,spriteSheet:getDimensions())
forrestitePickFinal = love.graphics.newQuad(256,32,32,32,spriteSheet:getDimensions())

dynamite1 = love.graphics.newQuad(288,32,32,32,spriteSheet:getDimensions())
dynamite2 = love.graphics.newQuad(320,32,32,32,spriteSheet:getDimensions())
dynamite3 = love.graphics.newQuad(352,32,32,32,spriteSheet:getDimensions())

explosionSprite = love.graphics.newQuad(224,192,64,64,spriteSheet:getDimensions())

break1 = love.graphics.newQuad(0,32,32,32,spriteSheet:getDimensions())
break2 = love.graphics.newQuad(32,32,32,32,spriteSheet:getDimensions())
break3 = love.graphics.newQuad(64,32,32,32,spriteSheet:getDimensions())

stoneSprite = love.graphics.newQuad(0,64,32,32,spriteSheet:getDimensions())
ironSprite = love.graphics.newQuad(32,64,32,32,spriteSheet:getDimensions())
goldSprite = love.graphics.newQuad(64,64,32,32,spriteSheet:getDimensions())
diamondsSprite = love.graphics.newQuad(96,64,32,32,spriteSheet:getDimensions())
amethystSprite = love.graphics.newQuad(128,64,32,32,spriteSheet:getDimensions())
forrestiteSprite = love.graphics.newQuad(160,64,32,32,spriteSheet:getDimensions())

stoneItemSprite = love.graphics.newQuad(32,112,16,16,spriteSheet:getDimensions())
ironItemSprite = love.graphics.newQuad(48,112,16,16,spriteSheet:getDimensions())
goldItemSprite = love.graphics.newQuad(64,112,16,16,spriteSheet:getDimensions())
diamondItemSprite = love.graphics.newQuad(80,112,16,16,spriteSheet:getDimensions())
amethystItemSprite = love.graphics.newQuad(96,112,16,16,spriteSheet:getDimensions())
forrestiteItemSprite = love.graphics.newQuad(112,112,16,16,spriteSheet:getDimensions())
carrotItemSprite = love.graphics.newQuad(128,112,16,16,spriteSheet:getDimensions())
breadItemSprite = love.graphics.newQuad(144,112,16,16,spriteSheet:getDimensions())
penisItemSprite = love.graphics.newQuad(160,112,16,16,spriteSheet:getDimensions())

chest = love.graphics.newQuad(192,64,32,32,spriteSheet:getDimensions())
chestMenu = love.graphics.newQuad(0,128,224,128,spriteSheet:getDimensions())

parallax1 = love.graphics.newImage('Assets/parallax1.png')
parallax2 = love.graphics.newImage('Assets/parallax2.png')
parallax3 = love.graphics.newImage('Assets/parallax3.png')
parallax4 = love.graphics.newImage('Assets/parallax4.png')
parallax5 = love.graphics.newImage('Assets/parallax5.png')

rockParticle = love.graphics.newQuad(0,96,16,16,spriteSheet:getDimensions())
ironParticle = love.graphics.newQuad(16,96,16,16,spriteSheet:getDimensions())
goldParticle = love.graphics.newQuad(32,96,16,16,spriteSheet:getDimensions())
diamondParticle = love.graphics.newQuad(48,96,16,16,spriteSheet:getDimensions())
amethestParticle = love.graphics.newQuad(64,96,16,16,spriteSheet:getDimensions())
forrestiteParticle = love.graphics.newQuad(80,96,16,16,spriteSheet:getDimensions())

minerSpriteSheet = love.graphics.newImage('Assets/minerSpriteSheet.png')

minerWalk1 = love.graphics.newQuad(0,0,32,32,minerSpriteSheet:getDimensions())
minerWalk2 = love.graphics.newQuad(32,0,32,32,minerSpriteSheet:getDimensions())
minerWalk3 = love.graphics.newQuad(64,0,32,32,minerSpriteSheet:getDimensions())
minerWalk4 = love.graphics.newQuad(96,0,32,32,minerSpriteSheet:getDimensions())
minerWalk5 = love.graphics.newQuad(128,0,32,32,minerSpriteSheet:getDimensions())
minerWalk6 = love.graphics.newQuad(160,0,32,32,minerSpriteSheet:getDimensions())
minerWalk7 = love.graphics.newQuad(192,0,32,32,minerSpriteSheet:getDimensions())
minerWalk8 = love.graphics.newQuad(224,0,32,32,minerSpriteSheet:getDimensions())

minerDoorSprite = love.graphics.newQuad(224,64,32,32,spriteSheet:getDimensions())

fullscreenIcon = love.graphics.newQuad(0,112,16,16,spriteSheet:getDimensions())
exitIcon = love.graphics.newQuad(16,112,16,16,spriteSheet:getDimensions())
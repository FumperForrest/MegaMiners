require("items")

-- Constants
BLOCK_WIDTH = 50
BLOCK_HEIGHT = 50
CHUNK_WIDTH = 15
CHUNK_HEIGHT = 15
local CHEST_SLOTS = 28

math.randomseed(os.time())

-- Block Types
blockTypes = {
    stone = { type = 'mineable', durability = 5, sprite = stoneSprite, item = stoneItem },
    iron = { type = 'mineable', durability = 10, sprite = ironSprite, item = ironItem },
    gold = { type = 'mineable', durability = 25, sprite = goldSprite, item = goldItem },
    diamonds = { type = 'mineable', durability = 35, sprite = diamondsSprite, item = diamondItem },
    amethyst = { type = 'mineable', durability = 50, sprite = amethystSprite, item = amethystItem },
    forrestite = { type = 'mineable', durability = 100, sprite = forrestiteSprite, item = forrestiteItem },
    chest = { type = 'interactable', sprite = chest },
    minerDoor = { type = 'special', sprite = minerDoorSprite }
}

-- Mineable Blocks
local mineables = { blockTypes.stone, blockTypes.iron, blockTypes.gold, blockTypes.diamonds, blockTypes.amethyst, blockTypes.forrestite }

-- Chunks and Blocks
chunks = {}
chunksX = 0
chunksY = 0

-- Generate a single block
local function generateBlock(chunkX, chunkY, widthIndex, heightIndex)
    local block = {}
    local blockType

    -- Randomly decide if this block is a chest
    if math.random(1, 100) == 1 then
        blockType = blockTypes.chest
        block = {
            blockType = blockType,
            x = chunkX * CHUNK_WIDTH * BLOCK_WIDTH + (widthIndex - 1) * BLOCK_WIDTH,
            y = chunkY * CHUNK_HEIGHT * BLOCK_HEIGHT + (heightIndex - 1) * BLOCK_HEIGHT,
            items = {},
            slotsUsed = 0
        }
        itemizeChest(block, stoneItem, 5)
        itemizeChest(block, ironItem, 3)
        itemizeChest(block, goldItem, 3)
        itemizeChest(block, diamondItem, 5)
        itemizeChest(block, amethystItem, 1)
        itemizeChest(block, forrestiteItem, 1)
        itemizeChest(block, carrotItem, 3)
        itemizeChest(block, breadItem, 5)
    -- Randomly decide if this block is a mineable resource
    elseif math.random(1, 200) == 1 then
        blockType = blockTypes.minerDoor
        block = {
            blockType = blockType,
            x = chunkX * CHUNK_WIDTH * BLOCK_WIDTH + (widthIndex - 1) * BLOCK_WIDTH,
            y = chunkY * CHUNK_HEIGHT * BLOCK_HEIGHT + (heightIndex - 1) * BLOCK_HEIGHT
        }
    elseif math.random(1, 10) == 1 then
        blockType = mineables[math.random(1, #mineables)]
        block = {
            blockType = blockType,
            x = chunkX * CHUNK_WIDTH * BLOCK_WIDTH + (widthIndex - 1) * BLOCK_WIDTH,
            y = chunkY * CHUNK_HEIGHT * BLOCK_HEIGHT + (heightIndex - 1) * BLOCK_HEIGHT,
            health = blockType.durability
        }
    -- Default to stone
    else
        blockType = blockTypes.stone
        block = {
            blockType = blockType,
            x = chunkX * CHUNK_WIDTH * BLOCK_WIDTH + (widthIndex - 1) * BLOCK_WIDTH,
            y = chunkY * CHUNK_HEIGHT * BLOCK_HEIGHT + (heightIndex - 1) * BLOCK_HEIGHT,
            health = blockType.durability
        }
    end

    return block
end

-- Generate a single chunk
local function generateChunk(chunkX, chunkY)
    local chunk = {
        blocks = {},
        x = (chunkX * CHUNK_WIDTH * BLOCK_WIDTH) + (CHUNK_WIDTH * BLOCK_WIDTH) / 2,
        y = (chunkY * CHUNK_HEIGHT * BLOCK_HEIGHT) + (CHUNK_HEIGHT * BLOCK_HEIGHT) / 2
    }

    for widthIndex = 1, CHUNK_WIDTH do
        for heightIndex = 1, CHUNK_HEIGHT do
            local block = generateBlock(chunkX, chunkY, widthIndex, heightIndex)
            table.insert(chunk.blocks, block)
        end
    end

    return chunk
end

-- Generate the entire map
function generateMap(chunksPerRow, chunksPerColumn)
    for chunkX = 0, chunksPerRow - 1 do
        for chunkY = 0, chunksPerColumn - 1 do
            local chunk = generateChunk(chunkX, chunkY)
            table.insert(chunks, chunk)

            chunksX = chunksPerColumn
            chunksY = chunksPerRow
        end
    end
end

-- Add items to a chest
function itemizeChest(chest, itemType, amount)
    local itemFound = false

    for itemIndex, item in ipairs(chest.items) do
        if item.itemType == itemType then
            item.amount = item.amount + amount
            itemFound = true
            break
        end
    end

    if not itemFound then
        table.insert(chest.items, { itemType = itemType, amount = amount })
    end
end
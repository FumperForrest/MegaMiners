require("items")

blockWidth = 50
blockHeight = 50

blocks = {}

blockTypes = {}  -- Ensure this is defined before adding types

chunks = {}

chunkWidth = 15
chunkHeight = 15

chestSlots = 28

stone = { type = 'mineable', durability = 5, sprite = stoneSprite }
iron = { type = 'mineable', durability = 10, sprite = ironSprite }
gold = { type = 'mineable', durability = 25, sprite = goldSprite }
diamonds = { type = 'mineable', durability = 35, sprite = diamondsSprite }
amethyst = { type = 'mineable', durability = 50, sprite = amethystSprite }
forrestite = { type = 'mineable', durability = 100, sprite = forrestiteSprite }

chest = { type = 'interactable', sprite = chest }

table.insert(blockTypes, stone)
table.insert(blockTypes, iron)
table.insert(blockTypes, gold)
table.insert(blockTypes, diamonds)
table.insert(blockTypes, amethyst)
table.insert(blockTypes, forrestite)
table.insert(blockTypes, chest)

local mineables = {stone, iron, gold, diamonds, amethyst, forrestite}

function generateMap(chunksPerRow, chunksPerColumn)
  for chunkX = 0, chunksPerRow - 1 do
      for chunkY = 0, chunksPerColumn - 1 do
          local chunk = {
              blocks = {},  -- Store blocks inside the chunk
              x = (chunkX * chunkWidth * blockWidth) + (chunkWidth * blockWidth) / 2,
              y = (chunkY * chunkHeight * blockHeight) + (chunkHeight * blockHeight) / 2
          }

          for widthIndex = 1, chunkWidth do
              for heightIndex = 1, chunkHeight do
                local block = {}

                if math.random(1, 100) == 1 then
                    blockType = chest
                    block = {
                        blockType = blockType,
                        x = chunkX * chunkWidth * blockWidth + (widthIndex - 1) * blockWidth,
                        y = chunkY * chunkHeight * blockHeight + (heightIndex - 1) * blockHeight,
                        items = {},
                        slotsUsed = 0,
                    }
                    itemizeChest(block, stoneItem, 5)
                    itemizeChest(block, ironItem, 3)
                    itemizeChest(block, goldItem, 3)
                    itemizeChest(block, diamondItem, 5)
                    itemizeChest(block, amethystItem, 1)
                    itemizeChest(block, forrestiteItem, 1)
                    itemizeChest(block, carrotItem, 3)
                    itemizeChest(block, breadItem, 5)
                elseif math.random(1, 10) == 1 then
                    blockType = blockTypes[math.random(1, #mineables)]
                    block = {
                        blockType = blockType,
                        x = chunkX * chunkWidth * blockWidth + (widthIndex - 1) * blockWidth,
                        y = chunkY * chunkHeight * blockHeight + (heightIndex - 1) * blockHeight,
                        health = blockType.durability
                    }
                else
                    blockType = stone
                    block = {
                        blockType = blockType,
                        x = chunkX * chunkWidth * blockWidth + (widthIndex - 1) * blockWidth,
                        y = chunkY * chunkHeight * blockHeight + (heightIndex - 1) * blockHeight,
                        health = blockType.durability
                    }
                end

                table.insert(chunk.blocks, block)  -- Insert block into the chunk
              end
          end

          table.insert(chunks, chunk)  -- Insert the chunk into the chunks table
      end
  end
end

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
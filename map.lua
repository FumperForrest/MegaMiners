blockWidth = 50
blockHeight = 50

blocks = {}

blockTypes = {}  -- Ensure this is defined before adding types

chunks = {}

chunkWidth = 15
chunkHeight = 15

stone = { durability = 5, sprite = stone }
iron = { durability = 10, sprite = iron }
gold = { durability = 25, sprite = gold }
diamonds = { durability = 35, sprite = diamonds }

table.insert(blockTypes, stone)
table.insert(blockTypes, iron)
table.insert(blockTypes, gold)
table.insert(blockTypes, diamonds)

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

                  if math.random(1, 10) == 1 then
                      local blockType = blockTypes[math.random(1, #blockTypes)]
                      block = {
                          blockType = blockType,
                          x = chunkX * chunkWidth * blockWidth + (widthIndex - 1) * blockWidth,
                          y = chunkY * chunkHeight * blockHeight + (heightIndex - 1) * blockHeight,
                          health = blockType.durability
                      }
                  else
                      local blockType = stone
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
rm BetterNSTTS/sounds.lua
touch BetterNSTTS/sounds.lua

echo 'BetterNSTTS = {}' >> BetterNSTTS/sounds.lua
echo '' >> BetterNSTTS/sounds.lua
echo 'BetterNSTTS.BNSTTS_SOUNDS =  {' >> BetterNSTTS/sounds.lua

find BetterNSTTS/media -type f -name "*.ogg" | while read -r file; do
  filename=$(basename "$file" .ogg)
  echo "[\"${filename}\"] = true," >> BetterNSTTS/sounds.lua
done

echo '}' >> BetterNSTTS/sounds.lua
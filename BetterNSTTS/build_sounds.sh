rm sounds.lua
touch sounds.lua

echo 'BetterNSTTS = {}' >> sounds.lua
echo '' >> sounds.lua
echo 'BetterNSTTS.BNSTTS_SOUNDS =  {' >> sounds.lua

find media -type f -name "*.ogg" | while read -r file; do
  filename=$(basename "$file" .ogg)
  echo "[\"${filename}\"] = true," >> sounds.lua
done

echo '}' >> sounds.lua
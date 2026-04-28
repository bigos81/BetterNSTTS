rm sounds.lua
touch sounds.lua
echo '-- contains all the supported sounds (and file names of the .ogg files in media folder)' >> sounds.lua
echo '-- as wow LUA prevents file existence checking, use build_sounds.sh script to auto generate data from folder' >> sounds.lua

echo 'BetterNSTTS = {}' >> sounds.lua
echo '' >> sounds.lua
echo 'BetterNSTTS.BNSTTS_SOUNDS =  {' >> sounds.lua

find media -type f -name "*.ogg" | while read -r file; do
  filename=$(basename "$file" .ogg)
  echo "[\"${filename}\"] = true," >> sounds.lua
done

echo '}' >> sounds.lua
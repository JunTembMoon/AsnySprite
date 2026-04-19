#!/bin/sh


out=$(pwd)
src=$(pwd)
APP="AsnySprite"
ARCH="$(uname -m)"

chmod +x libresprite

mkdir -p AsnySprite/usr/bin

mv ../../desktop/libresprite.desktop AsnySprite/
cp ../../desktop/icons/hicolor/256x256/apps/libresprite.png AsnySprite/libresprite.png

mv *.so* AsnySprite/usr/lib

# Create AppImage with lib4bin and Sharun
(
export ARCH="$(uname -m)" # Just to be double sure
cd AsnySprite
wget "https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -k -w \
  ../libresprite \
  /usr/lib/libpthread.so* \
  /usr/lib/librt.so* \
  /usr/lib/libstdc++.so* 
ln ./sharun ./AppRun 
./sharun -g
)

# Maybe the data folder is being read during initial run
# This lets the run complete with expected original locations and then
# copies it over afterwards using the below command
mv "$out"/data "$out"/AsnySprite/bin

wget "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage" -O appimagetool
chmod +x ./appimagetool
./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n "$out"/AsnySprite "$out"/"$APP"-anylinux-"$ARCH".AppImage
